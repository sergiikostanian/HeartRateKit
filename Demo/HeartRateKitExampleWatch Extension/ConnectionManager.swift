//
//  ConnectionManager.swift
//  HeartRateKitExampleWatch Extension
//
//  Created by Sergii Kostanian on 15.10.2019.
//  Copyright © 2019 MadAppGang. All rights reserved.
//

import Foundation

import WatchConnectivity

final class ConnectionManager: NSObject {
    
    private let session = WCSession.default

    override init() {
        super.init()
        startSession()
    }

    private func startSession() {
        guard session.activationState == .notActivated else { return }
        session.delegate = self
        session.activate()
    }
    
    func sendHeartRate(_ heartRate: Int) {
        guard session.isReachable else { return }
        
        let message = ["HeartRate": heartRate]
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)        
    }
    
}

extension ConnectionManager: WCSessionDelegate {
        
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
}
