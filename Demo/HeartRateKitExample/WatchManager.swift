//
//  WatchManager.swift
//  HeartRateKitExample
//
//  Created by Sergii Kostanian on 15.10.2019.
//  Copyright © 2019 MadAppGang. All rights reserved.
//

import Foundation
import WatchConnectivity

protocol WatchManagerDelegate: class {
    func watchManager(_ WatchManager: WatchManager, didReceive heartRate: Int)
}

final class WatchManager: NSObject {
    
    weak var delegate: WatchManagerDelegate?

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    override init() {
        super.init()
        startSession()
    }
    
    private func startSession() {
        guard session?.activationState == .notActivated else { return }
        session?.delegate = self
        session?.activate()
    }
}

extension WatchManager: WCSessionDelegate {
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let heartRate = message["HeartRate"] as? Int {
            delegate?.watchManager(self, didReceive: heartRate)
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
    }
}

