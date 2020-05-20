//
//  AppDelegate.swift
//  HeartRateKitExample
//
//  Created by Sergii Kostanian on 3/2/18.
//  Copyright © 2018 MadAppGang. All rights reserved.
//

import UIKit
import HeartRateKit
import HealthKit
import WatchConnectivity


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if let sensorsVC = window?.rootViewController as? SensorsViewController {
            sensorsVC.heartRateSensorService = HeartRateSensorManager()
        }

        return true
    }
}
