//
//  SensorCell.swift
//  HeartRateKitExample
//
//  Created by Sergii Kostanian on 7/19/18.
//  Copyright © 2018 MadAppGang. All rights reserved.
//

import UIKit
import HeartRateKit

class SensorCell: UITableViewCell {

    @IBOutlet private weak var container: UIView!
    @IBOutlet private weak var sensorName: UILabel!
    @IBOutlet private weak var sensorType: UILabel!
    
    func setup(with sensor: Sensor, selected: Bool) {
        sensorName.text = sensor.description
        sensorType.text = sensor.type.rawValue
        container.backgroundColor = selected ? #colorLiteral(red: 0.4472277761, green: 1, blue: 0.4058409035, alpha: 1) : #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        setConnected(sensor.state == .connected)
    }

    func setConnected(_ connected: Bool) {
        container.alpha = connected ? 1.0 : 0.3
    }

}
