//
//  AppleWatchSensorManager.swift
//  SmartRun
//
//  Created by Sergii Kostanian on 1/23/18.
//  Copyright © 2018 MadAppGang. All rights reserved.
//

import Foundation
import WatchConnectivity
import HealthKit

protocol AppleWatchSensorManagerDelegate: class {
    func appleWatchSensorManager(_ appleWatchSensorManager: AppleWatchSensorManager, didReceive heartRate: HeartRate, from sensor: Sensor)
    func appleWatchSensorManager(_ appleWatchSensorManager: AppleWatchSensorManager, didDiscover sensor: Sensor)
    func appleWatchSensorManager(_ appleWatchSensorManager: AppleWatchSensorManager, didConnect sensor: Sensor)
    func appleWatchSensorManager(_ appleWatchSensorManager: AppleWatchSensorManager, didDisconnect sensor: Sensor)
}

final class AppleWatchSensorManager {

    weak var delegate: AppleWatchSensorManagerDelegate?

    private let healthStoreManager: HealthStoreManager
    private var sensor: Sensor!

    private var sessionActivationStateObserver: NSKeyValueObservation?
    private var sessionIsWatchAppInstalledObserver: NSKeyValueObservation?

    private var session: WCSession?
    private var heartRateTimer: Timer?

    private let appleWatchUUIDString = "E5CEF8DA-79A2-489B-A2D6-92F7FA270596"

    // MARK: - Lifecycle

    init() {
        healthStoreManager = HealthStoreManager()
        sensor = makeAppleWatchSensor()

        guard WCSession.isSupported() else { return }
        session = WCSession.default

        if let session = session, session.activationState == .activated {
            sensor.state = .connected
        }

        sessionActivationStateObserver = session?.observe(\.activationState) { [weak self] (session, change) in
            guard let `self` = self else { return }
            if session.activationState == .activated {
                self.sensor.state = .connected
                self.delegate?.appleWatchSensorManager(self, didConnect: self.sensor)
            } else if session.activationState == .notActivated {
                self.sensor.state = .notConnected
                self.delegate?.appleWatchSensorManager(self, didDisconnect: self.sensor)
            }
        }
    }

    deinit {
        stopDiscovering()
        stopReceivingHeartRate()
        sessionActivationStateObserver?.invalidate()
    }

    // MARK: - Public

    func startDiscovering() {
        guard let session = session else { return }

        if session.isWatchAppInstalled {
            delegate?.appleWatchSensorManager(self, didDiscover: sensor)
            return
        }

        sessionIsWatchAppInstalledObserver = session.observe(\.isWatchAppInstalled) { [weak self] (session, change) in
            guard let `self` = self else { return }
            if session.isWatchAppInstalled {
                self.delegate?.appleWatchSensorManager(self, didDiscover: self.sensor)
                self.sessionIsWatchAppInstalledObserver?.invalidate()
            }
        }
    }

    func stopDiscovering() {
        sessionIsWatchAppInstalledObserver?.invalidate()
    }

    func startReceivingHeartRate() {
        healthStoreManager.requestHeartRateShareAndReadAuthorization { [weak self] (success) in
            guard success else { return }
            self?.healthStoreManager.startObservingHeartRate({ (heartRate) in
                guard let `self` = self else { return }
                self.delegate?.appleWatchSensorManager(self, didReceive: heartRate, from: self.sensor)
            })
        }
    }

    func stopReceivingHeartRate() {
        healthStoreManager.stopObservingHeartRate()
    }

    // MARK: - Private

    private func makeAppleWatchSensor() -> Sensor {
        let appleWatchUUID = UUID(uuidString: appleWatchUUIDString) ?? UUID()
        var sensor = Sensor(id: appleWatchUUID)
        sensor.type = .appleWatch
        sensor.source = .appleWatch
        sensor.state = .none
        sensor.description = "Apple Watch"
        sensor.nameOfDevice = sensor.description
        return sensor
    }
}
