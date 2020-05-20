//
//  BluetoothSensorManager.swift
//  SmartRun
//
//  Created by Sergii Kostanian on 1/23/18.
//  Copyright © 2018 MadAppGang. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothSensorManagerDelegate: class {
    func bluetoothSensorManager(_ bluetoothSensorManager: BluetoothSensorManager, didReceive heartRate: HeartRate, from sensor: Sensor)
    func bluetoothSensorManager(_ bluetoothSensorManager: BluetoothSensorManager, didDiscover sensor: Sensor)
    func bluetoothSensorManager(_ bluetoothSensorManager: BluetoothSensorManager, didConnect sensor: Sensor)
    func bluetoothSensorManager(_ bluetoothSensorManager: BluetoothSensorManager, didDisconnect sensor: Sensor)
}

final class BluetoothSensorManager: NSObject {

    private struct Device {
        let identifier: UUID
        let peripheral: CBPeripheral
        var sensor: Sensor
    }

    private enum ServiceUUID {
        static let heartRate = CBUUID(string: "180D")

        static func all() -> [CBUUID] {
            return [ServiceUUID.heartRate]
        }
    }

    private enum CharacteristicUUID {
        static let heartRateMeasurement = CBUUID(string: "2A37")
    }

    weak var delegate: BluetoothSensorManagerDelegate?

    /// - Note: all `centralManager` callbacks called in DispatchQueue with `utility` QoS
    private var centralManager: CBCentralManager!
    private var connectTimer: Timer!
    fileprivate var isDiscovering: Bool = false

    private var discoveredDevices: [Device] = []
    private var selectedDevice: Device?
    private var selectedPeripheralCharacteristic: CBCharacteristic?
    
    // MARK: - Lifecycle

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .global(qos: .utility))
    }

    deinit {
        stopReceivingHeartRate()
        stopDiscovering()
        discoveredDevices.forEach { centralManager.cancelPeripheralConnection($0.peripheral) }
    }

    // MARK: - Public

    func startDiscovering() {
        isDiscovering = true
        if !centralManager.isScanning {
            centralManager.scanForPeripherals(withServices: ServiceUUID.all(), options: nil)
        }
    }

    func stopDiscovering() {
        isDiscovering = false
        if centralManager.isScanning {
            centralManager.stopScan()
        }
    }

    func startReceivingHeartRate(fromSensorWithId identifier: UUID) {
        stopReceivingHeartRate()
        
        guard selectDevice(withId: identifier) else { return }
        guard let peripheral = selectedDevice?.peripheral else { return }
        centralManager.connect(peripheral, options: nil)
        connectTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] (timer) in
            self?.reconnectIfNeeded()
        })
    }

    func stopReceivingHeartRate() {
        guard let selectedDevice = selectedDevice else { return }
        
        if let characteristic = selectedPeripheralCharacteristic {
            selectedDevice.peripheral.setNotifyValue(false, for: characteristic)
        }
        centralManager.cancelPeripheralConnection(selectedDevice.peripheral)

        self.selectedDevice = nil
        if connectTimer != nil {
            connectTimer.invalidate()
            connectTimer = nil
        }
    }

    // MARK: - Private

    private func selectDevice(withId identifier: UUID) -> Bool {
        guard let device = discoveredDevices.filter({ $0.identifier == identifier }).first else { return false }
        selectedDevice = device
        return true
    }

    private func handleDiscoveredPeripheral(_ peripheral: CBPeripheral) {
        guard !discoveredDevices.contains(where: {$0.identifier == peripheral.identifier}) else { return }
        guard let sensor = makeSensor(from: peripheral) else { return }
        let device = Device(identifier: peripheral.identifier, peripheral: peripheral, sensor: sensor)

        discoveredDevices.append(device)
        DispatchQueue.main.async {
            self.delegate?.bluetoothSensorManager(self, didDiscover: sensor)
        }
    }

    @objc private func reconnectIfNeeded() {
        guard case .poweredOn = centralManager.state else { return }
        guard let selectedDevice = selectedDevice else { return }
        if selectedDevice.peripheral.state != .connected {
            centralManager.connect(selectedDevice.peripheral, options: nil)
        }
    }

    private func handle(heartRateMeasurementBytes bytes: [UInt8]) -> HeartRate {
        /**
         Property represents a set of bits, which values describe markup for bytes in heart rate data.

         Bits grouped like `| 000 | 0 | 0 | 00 | 0 |` where: 3 bits are reserved, 1 bit for RR-Interval, 1 bit for Energy Expended Status, 2 bits for Sensor Contact Status, 1 bit for Heart Rate Value Format
         */
        let flags = bytes[0]

        var range: Range<Int>

        var heartRate: HeartRate
        if flags & 0x1 == 0 {
            range = 1..<(1 + MemoryLayout<UInt8>.size)
            heartRate = HeartRate(bytes[1])
        } else {
            range = 1..<(1 + MemoryLayout<UInt16>.size)
            heartRate = HeartRate(UnsafePointer(Array(bytes[range])).withMemoryRebound(to: UInt16.self, capacity: 1, { $0.pointee }))
        }

        /// 0, 1 – if value not available, 2 - if sensor is not worn, 3 - if sensor worn
        let sensorContactStatusValue = (Int(flags) >> 1) & 0x3
        if sensorContactStatusValue == 2 {
            heartRate = 0
        }

        return heartRate
    }

    private func makeSensor(from device: CBPeripheral) -> Sensor? {
        guard var nameOfDevice = device.name?.uppercased() else { return nil }

        var sensor = Sensor(id: device.identifier)
        sensor.nameOfDevice = nameOfDevice
        sensor.source = .bluetooth

        if let range = nameOfDevice.range(of: "HRM603B") {
            nameOfDevice.replaceSubrange(range, with: "SmartRun chest")
            sensor.type = .smartRunChest
        }

        if let range = nameOfDevice.range(of: "HW702A") {
            nameOfDevice.replaceSubrange(range, with: "SmartRun arm")
            sensor.type = .smartRunArm
        }

        if nameOfDevice.contains("APPLE WATCH") {
            sensor.type = .appleWatch
        }

        if nameOfDevice.contains("POLAR H7") {
            sensor.type = .polarH7
        }

        sensor.description = nameOfDevice
        sensor.state = (device.state == .connected) ? .connected : .notConnected

        return sensor
    }
}

extension BluetoothSensorManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if case .poweredOn = central.state {
            guard isDiscovering else { return }

            for peripheral: AnyObject in central.retrieveConnectedPeripherals(withServices: ServiceUUID.all()) {
                guard let peripheral = peripheral as? CBPeripheral  else { return }
                handleDiscoveredPeripheral(peripheral)
            }
            central.scanForPeripherals(withServices: ServiceUUID.all(), options: nil)
        } else {
            var devicesMarkedAsDisconnected: [Device] = []
            for device in discoveredDevices {
                var disconnectedDevice = device
                disconnectedDevice.sensor.state = .notConnected
                devicesMarkedAsDisconnected.append(disconnectedDevice)
                self.delegate?.bluetoothSensorManager(self, didDisconnect: disconnectedDevice.sensor)
            }
            discoveredDevices = devicesMarkedAsDisconnected
            selectedDevice?.sensor.state = .notConnected
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        handleDiscoveredPeripheral(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(ServiceUUID.all())

        DispatchQueue.main.async {
            guard var device = self.discoveredDevices.filter({ $0.identifier == peripheral.identifier }).first else { return }
            device.sensor.state = .connected
            self.delegate?.bluetoothSensorManager(self, didConnect: device.sensor)
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            guard var device = self.discoveredDevices.filter({ $0.identifier == peripheral.identifier }).first else { return }
            device.sensor.state = .notConnected
            self.delegate?.bluetoothSensorManager(self, didDisconnect: device.sensor)
        }
    }
}

extension BluetoothSensorManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
            let characteristics: [CBUUID]

            switch service.uuid {
            case ServiceUUID.heartRate:
                characteristics = [CharacteristicUUID.heartRateMeasurement]
            default:
                continue
            }
            peripheral.discoverCharacteristics(characteristics, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            switch characteristic.uuid {
            case CharacteristicUUID.heartRateMeasurement:
                selectedPeripheralCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            default:
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        guard let binaryData = characteristic.value else { return }
        guard let selectedDevice = selectedDevice else { return }
        guard selectedDevice.identifier == peripheral.identifier else { return }

        var bytes = [UInt8](repeating: 0, count: binaryData.count)
        binaryData.copyBytes(to: &bytes, count: bytes.count)

        switch characteristic.uuid {
        case CharacteristicUUID.heartRateMeasurement:
            DispatchQueue.main.async {
                let heartRate = self.handle(heartRateMeasurementBytes: bytes)
                self.delegate?.bluetoothSensorManager(self, didReceive: heartRate, from: selectedDevice.sensor)
            }
        default:
            break
        }
    }
}
