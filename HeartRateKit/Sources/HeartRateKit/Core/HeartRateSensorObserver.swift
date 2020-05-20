//
//  HeartRateSensorObserver.swift
//  SmartRun
//
//  Created by Sergii Kostanian on 1/16/18.
//  Copyright © 2018 MadAppGang. All rights reserved.
//

import Foundation

public protocol HeartRateSensorObserver: class {

    /**
     Invoked when new heart rate value is received from selected sensor.
     */
    func heartRateSensorService(_ heartRateSensorService: HeartRateSensorService, didReceive heartRate: HeartRate, from sensor: Sensor)

    /**
     Invoked when new sensor is discovered.
     */
    func heartRateSensorService(_ heartRateSensorService: HeartRateSensorService, didDiscover sensor: Sensor)

    /**
     Invoked when discovered sensor is chenged it's state to connected.
     Manual sensor connecting is not available,
     it is managed by `HeartRateSensorService`.
     */
    func heartRateSensorService(_ heartRateSensorService: HeartRateSensorService, didConnect sensor: Sensor)

    /**
     Invoked when discovered sensor is chenged it's state to disconnected.
     Manual sensor disconnecting is not available,
     it is managed by `HeartRateSensorService`.
     */
    func heartRateSensorService(_ heartRateSensorService: HeartRateSensorService, didDisconnect sensor: Sensor)

    /**
     Invoked when new sensor is selected.
     */
    func heartRateSensorService(_ heartRateSensorService: HeartRateSensorService, didSelect sensor: Sensor)
}
