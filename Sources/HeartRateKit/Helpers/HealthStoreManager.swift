//
//  HealthStoreManager.swift
//  SmartRun
//
//  Created by Sergii Kostanian on 1/31/18.
//  Copyright © 2018 MadAppGang. All rights reserved.
//

import Foundation
import HealthKit

final class HealthStoreManager {

    private let healthStore = HKHealthStore()
    private var heartRateObserverQuery: HKObserverQuery?
    
    func isHeartRateSharingAuthorized() -> Bool {
        let type = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let status = healthStore.authorizationStatus(for: type)
        return status == .sharingAuthorized
    }

    func requestHeartRateShareAndReadAuthorization(_ completion: @escaping (_ success: Bool) -> ()) {
        guard HKHealthStore.isHealthDataAvailable() == true else {
            completion(false)
            return
        }
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(false)
            return
        }
        healthStore.requestAuthorization(toShare: [heartRateType], read: [heartRateType]) { (success, _) in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    func startObservingHeartRate(_ updateHandler: @escaping (_ heartRate: HeartRate) -> ()) {
        let type = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        heartRateObserverQuery = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] query, completionHandler, error in
            guard error == nil else { return }
            self?.readHeartRate(updateHandler)
        }
        healthStore.execute(heartRateObserverQuery!)
    }
    
    func stopObservingHeartRate() {
        guard let heartRateObserverQuery = heartRateObserverQuery else { return }
        healthStore.stop(heartRateObserverQuery)
        self.heartRateObserverQuery = nil
    }

    func readHeartRate(fromDeviceNamed deviceName: String? = nil, _ completion: @escaping (_ heartRate: HeartRate) -> ()) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let sortDescription = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let heartRateQuery = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [sortDescription]) { query, results, error in

            DispatchQueue.main.async {
                guard let sample = results?.first as? HKQuantitySample else { return }
                if let deviceName = deviceName, sample.device?.name != deviceName { return }
                let heartRateUnit = HKUnit(from: "count/min")
                let value = sample.quantity.doubleValue(for: heartRateUnit)
                completion(HeartRate(value))
            }
        }

        healthStore.execute(heartRateQuery)
    }
}
