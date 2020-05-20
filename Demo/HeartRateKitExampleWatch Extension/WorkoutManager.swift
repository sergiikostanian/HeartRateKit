//
//  WorkoutSessionManager.swift
//  Watch Extension
//
//  Created by Sergii Kostanian on 11/10/17.
//  Copyright © 2017 MadAppGang. All rights reserved.
//

import Foundation
import HealthKit

protocol WorkoutManagerDelegate: class {
    func workoutManager(_ workoutManager: WorkoutManager, didReceive heartRate: Int)
}

final class WorkoutManager: NSObject {
    
    weak var delegate: WorkoutManagerDelegate?

    private let healthStore = HKHealthStore()
    
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    var hasRunningSession: Bool {
        guard let session = session else { return false }
        return session.state != .notStarted
    }
    
    func startSession(with configuration: HKWorkoutConfiguration, completion: @escaping (Bool)->Void) {        
        let typesToShare: Set = [HKQuantityType.workoutType()]
        let typesToRead: Set = [HKQuantityType.quantityType(forIdentifier: .heartRate)!]
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] (success, error) in
            self?.setupWorkoutSession(with: configuration, completion)
        }
    }
    
    private func setupWorkoutSession(with configuration: HKWorkoutConfiguration, _ completion: @escaping (Bool)->Void) {
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            completion(false)
            return
        }
        
        session?.delegate = self
        builder?.delegate = self
        
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: configuration)
        
        session?.startActivity(with: Date())
        completion(true)
    }

    
    func pauseSession() {
        guard let session = session, session.state != .paused else { return }
        session.pause()
    }
    
    func resumeSession() {
        guard let session = session, session.state == .paused else { return }
        session.resume()
    }

    func stopSession() {
        guard let session = session else { return }
        session.end()
        stopCollectingHeartRate()
    }
    
    func startCollectingHeartRate() {
        builder?.beginCollection(withStart: Date()) { (success, error) in
        }
    }
    
    func stopCollectingHeartRate() {
        builder?.endCollection(withEnd: Date()) { [weak self] (success, error) in
            self?.builder?.finishWorkout { (workout, error) in
            }
        }
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        guard collectedTypes.contains(hrType) else { return }
        guard let hrQuantity = workoutBuilder.statistics(for: hrType)?.mostRecentQuantity() else { return }
        let hrUnit = HKUnit(from: "count/min")
        let hr = Int(hrQuantity.doubleValue(for: hrUnit))
        self.delegate?.workoutManager(self, didReceive: hr)
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate {
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            if fromState == .notStarted { // started
                break
            } else { // resumed
                break
            }
        case .paused: // paused
            break
        case .ended: // ended
            break
        default:
            break
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
    }
}
