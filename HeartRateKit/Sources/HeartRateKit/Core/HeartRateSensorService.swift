//
//  HeartRateSensorService.swift
//  SmartRun
//
//  Created by Sergii Kostanian on 1/16/18.
//  Copyright © 2018 MadAppGang. All rights reserved.
//

import Foundation

/// Measures in _beats per minute_.
public typealias HeartRate = Int

/**
 The HeartRateSensorService is a protocol that describes API for work with
 sources that can read heart rate.
 */
public protocol HeartRateSensorService {

    func addObserver(_ observer: HeartRateSensorObserver)
    func removeObserver(_ observer: HeartRateSensorObserver)

    /**
     All discovered sensors that can read heart rate.
     */
    var discoveredSensors: Set<Sensor> { get }

    /**
     Currently selected sensor. It's the sensor from which you will receive heart rate.
     */
    var selectedSensor: Sensor? { get }

    /**
     Last received heart rate.
     */
    var lastReceivedHeartRate: HeartRate? { get }

    /**
     Starts sensors discovering.
     */
    func startDiscovering()

    /**
     Stops sensors discovering.
     */
    func stopDiscovering()

    /**
     Use this method to select sensor from which you want receive heart rate.
     Receiving will start immediately after sensor selecting.
     */
    func select(_ sensor: Sensor?)
}
