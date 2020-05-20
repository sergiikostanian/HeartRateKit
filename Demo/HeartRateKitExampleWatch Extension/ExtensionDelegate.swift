//
//  ExtensionDelegate.swift
//  HeartRateKitExampleWatch Extension
//
//  Created by Sergii Kostanian on 7/23/18.
//  Copyright © 2018 MadAppGang. All rights reserved.
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    let session = WCSession.default

    func applicationDidFinishLaunching() {
        session.delegate = self
        session.activate()
    }
}

extension ExtensionDelegate: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}

