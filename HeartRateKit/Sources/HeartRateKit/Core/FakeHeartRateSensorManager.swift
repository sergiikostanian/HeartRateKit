//
//  FakeHeartRateSensorManager.swift
//  HeartRateKit
//
//  Created by Sergii Kostanian on 2/13/18.
//  Copyright © 2018 MadAppGang. All rights reserved.
//

import Foundation

public final class FakeHeartRateSensorManager {

    public var discoveredSensors: Set<Sensor> = []
    public var selectedSensor: Sensor?
    public var lastReceivedHeartRate: HeartRate?

    public var randomHeartRateRange: Range<HeartRate> = 40..<200
    
    fileprivate var observers = ObserverContainer<HeartRateSensorObserver>()

    private var fakeSensor: Sensor!
    private let fakeSensorUUIDString = "9A44C575-81CA-4ED5-9FE5-291EC8E74FA9"

    private let hrGeneratingFrequency: TimeInterval = 5 // seconds
    private var heartRateTimer: Timer?

    public init() {
        fakeSensor = makeFakeSensor()
    }

    deinit {
        stopHeartRateTimer()
    }

    private func makeFakeSensor() -> Sensor {
        let fakeSensorUUID = UUID(uuidString: fakeSensorUUIDString) ?? UUID()
        var sensor = Sensor(id: fakeSensorUUID)
        sensor.type = .fake
        sensor.source = .bluetooth
        sensor.state = .connected
        sensor.description = "Fake Sensor"
        sensor.nameOfDevice = sensor.description
        return sensor
    }

    private func startHeartRateTimer() {
        guard heartRateTimer == nil else { return }
        heartRateTimer = Timer.scheduledTimer(withTimeInterval: hrGeneratingFrequency, repeats: true, block: { [weak self] (timer) in
            self?.generateHeartRate()
        })
        heartRateTimer?.tolerance = 1
    }

    private func stopHeartRateTimer() {
        if heartRateTimer != nil {
            heartRateTimer?.invalidate()
            heartRateTimer = nil
        }
    }

    @objc private func generateHeartRate() {
        let hr = HeartRate.random(in: randomHeartRateRange)
        lastReceivedHeartRate = hr
        observers.enumerateObservers { observer in
            observer.heartRateSensorService(self, didReceive: hr, from: fakeSensor)
        }
    }
}

extension FakeHeartRateSensorManager: HeartRateSensorService {

    public func addObserver(_ observer: HeartRateSensorObserver) {
        observers.add(observer)
    }

    public func removeObserver(_ observer: HeartRateSensorObserver) {
        observers.remove(observer)
    }

    public func startDiscovering() {
        discoveredSensors.insert(fakeSensor)
        observers.enumerateObservers { observer in
            observer.heartRateSensorService(self, didDiscover: fakeSensor)
        }
    }

    public func stopDiscovering() {
    }

    public func select(_ sensor: Sensor?) {
        guard let sensor = sensor else {
            stopHeartRateTimer()
            selectedSensor = nil
            return
        }

        guard sensor == fakeSensor else { return }
        startHeartRateTimer()
        selectedSensor = sensor
        observers.enumerateObservers { observer in
            observer.heartRateSensorService(self, didSelect: sensor)
        }
    }
}
