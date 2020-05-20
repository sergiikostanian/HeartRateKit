//
//  InterfaceController.swift
//  HeartRateKitExampleWatch Extension
//
//  Created by Sergii Kostanian on 7/23/18.
//  Copyright © 2018 MadAppGang. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class InterfaceController: WKInterfaceController {
    
    private let workoutManager = WorkoutManager()
    private let connectionManager = ConnectionManager()
    
    @IBOutlet private var hrLabel: WKInterfaceLabel!
    @IBOutlet private var toggleButton: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        workoutManager.delegate = self
    }
    
    @IBAction private func toggleReadingHR() {
        if workoutManager.hasRunningSession {
            stopWorkout()
        } else {
            startWorkout()
        }
    }
    
    private func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        workoutManager.startSession(with: configuration) { [weak self] _ in
            self?.workoutManager.startCollectingHeartRate()
            self?.toggleButton.setTitle("Stop reading HR")
            self?.toggleButton.setBackgroundColor(#colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1))
        }
    }
    
    private func stopWorkout() {
        workoutManager.stopSession()
        toggleButton.setTitle("Start reading HR")
        toggleButton.setBackgroundColor(#colorLiteral(red: 0.5563425422, green: 0.9793455005, blue: 0, alpha: 1))
        hrLabel.setText("---")
    }
}

extension InterfaceController: WorkoutManagerDelegate {
    
    func workoutManager(_ workoutManager: WorkoutManager, didReceive heartRate: Int) {
        hrLabel.setText("\(heartRate) BPM")
        connectionManager.sendHeartRate(heartRate)
    }
}
