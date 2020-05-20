//
//  HeartRateSensorManager.swift
//  SmartRun
//
//  Created by Sergii Kostanian on 1/20/18.
//  Copyright © 2018 MadAppGang. All rights reserved.
//

import Foundation
import CoreBluetooth

final public class HeartRateSensorManager {

    public var discoveredSensors: Set<Sensor> = []
    public var selectedSensor: Sensor?
    public var lastReceivedHeartRate: HeartRate?

    private var observers = ObserverContainer<HeartRateSensorObserver>()

    private let appleWatchSensorManager = AppleWatchSensorManager()
    private let bluetoothSensorManager = BluetoothSensorManager()

    public init() {
        appleWatchSensorManager.delegate = self
        bluetoothSensorManager.delegate = self
    }
    
    deinit {
        print("deinit HeartRateSensorManager")
    }

    fileprivate func handleReceived(heartRate: HeartRate, from sensor: Sensor) {
        lastReceivedHeartRate = heartRate
        observers.enumerateObservers { observer in
            observer.heartRateSensorService(self, didReceive: heartRate, from: sensor)
        }
    }

    fileprivate func handleDiscovered(sensor: Sensor) {
        // Ignore sensors that is already discovered because we can't discover something twice.
        // We need this to not notify observers about same discovered sensor more then one time.  
        guard !discoveredSensors.contains(sensor) else { return }
        
        discoveredSensors.insert(sensor)
        observers.enumerateObservers { observer in
            observer.heartRateSensorService(self, didDiscover: sensor)
        }
    }

    fileprivate func handleConnected(sensor: Sensor) {
        guard discoveredSensors.contains(sensor) else { return }
        if var connectedSensor = discoveredSensors.remove(sensor) {
            connectedSensor.state = .connected
            discoveredSensors.insert(connectedSensor)
        }
        if selectedSensor == sensor {
            selectedSensor?.state = .connected
        }
        observers.enumerateObservers { observer in
            observer.heartRateSensorService(self, didConnect: sensor)
        }
    }

    fileprivate func handleDisconnected(sensor: Sensor) {
        guard discoveredSensors.contains(sensor) else { return }
        if var disconnectedSensor = discoveredSensors.remove(sensor) {
            disconnectedSensor.state = .notConnected
            discoveredSensors.insert(disconnectedSensor)
        }
        if selectedSensor == sensor {
            selectedSensor?.state = .notConnected
        }
        observers.enumerateObservers { observer in
            observer.heartRateSensorService(self, didDisconnect: sensor)
        }
    }

    fileprivate func stopReceivingHeartRateFromCurrentSensor() {
        if let currentSensor = selectedSensor {
            switch currentSensor.source {
            case .appleWatch:
//                appleWatchSensorManager.stopReceivingHeartRate()
                break
            case .bluetooth:
                bluetoothSensorManager.stopReceivingHeartRate()
            }
        }
    }

    fileprivate func startReceivingHeartRateFrom(_ sensor: Sensor) {
        switch sensor.source {
        case .appleWatch:
            
            // The most effective way to read hr data from apple watch for now 
            // it's reading it on the watch side and sending to the phone
            // via Watch Connectivity. Usage example can be found in 
            // `HeartRateKitExample` and `HeartRateKitExampleWatch`. 
            
//            appleWatchSensorManager.startReceivingHeartRate()
            break
        case .bluetooth:
            bluetoothSensorManager.startReceivingHeartRate(fromSensorWithId: sensor.id)
        }
    }
}

extension HeartRateSensorManager: HeartRateSensorService {

    public func addObserver(_ observer: HeartRateSensorObserver) {
        observers.add(observer)
    }

    public func removeObserver(_ observer: HeartRateSensorObserver) {
        observers.remove(observer)
    }

    public func startDiscovering() {
        appleWatchSensorManager.startDiscovering()
        bluetoothSensorManager.startDiscovering()
    }

    public func stopDiscovering() {
        appleWatchSensorManager.stopDiscovering()
        bluetoothSensorManager.stopDiscovering()
    }

    public func select(_ sensor: Sensor?) {
        guard let sensor = sensor else {
            stopReceivingHeartRateFromCurrentSensor()
            selectedSensor = nil
            return
        }
        
        guard discoveredSensors.contains(sensor) else { return }

        stopReceivingHeartRateFromCurrentSensor()
        startReceivingHeartRateFrom(sensor)

        selectedSensor = sensor

        observers.enumerateObservers { observer in
            observer.heartRateSensorService(self, didSelect: sensor)
        }
    }
}

extension HeartRateSensorManager: AppleWatchSensorManagerDelegate {

    func appleWatchSensorManager(_ appleWatchSensorManager: AppleWatchSensorManager, didReceive heartRate: HeartRate, from sensor: Sensor) {
        handleReceived(heartRate: heartRate, from: sensor)
    }

    func appleWatchSensorManager(_ appleWatchSensorManager: AppleWatchSensorManager, didDiscover sensor: Sensor) {
        handleDiscovered(sensor: sensor)
    }

    func appleWatchSensorManager(_ appleWatchSensorManager: AppleWatchSensorManager, didConnect sensor: Sensor) {
        handleConnected(sensor: sensor)
    }

    func appleWatchSensorManager(_ appleWatchSensorManager: AppleWatchSensorManager, didDisconnect sensor: Sensor) {
        handleDisconnected(sensor: sensor)
    }
}

extension HeartRateSensorManager: BluetoothSensorManagerDelegate {

    func bluetoothSensorManager(_ bluetoothSensorManager: BluetoothSensorManager, didReceive heartRate: HeartRate, from sensor: Sensor) {
        handleReceived(heartRate: heartRate, from: sensor)
    }

    func bluetoothSensorManager(_ bluetoothSensorManager: BluetoothSensorManager, didDiscover sensor: Sensor) {
        handleDiscovered(sensor: sensor)
    }

    func bluetoothSensorManager(_ bluetoothSensorManager: BluetoothSensorManager, didConnect sensor: Sensor) {
        handleConnected(sensor: sensor)
    }

    func bluetoothSensorManager(_ bluetoothSensorManager: BluetoothSensorManager, didDisconnect sensor: Sensor) {
        handleDisconnected(sensor: sensor)
    }
}

