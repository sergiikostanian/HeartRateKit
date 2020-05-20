//
//  SensorsViewController.swift
//  HeartRateKitExample
//
//  Created by Sergii Kostanian on 3/2/18.
//  Copyright © 2018 MadAppGang. All rights reserved.
//

import UIKit
import HeartRateKit
import HealthKit

final class SensorsViewController: UIViewController {
    
    var heartRateSensorService: HeartRateSensorService!
    
    private let healthStore = HKHealthStore()
    private let watchManager = WatchManager()
    private var sensors: [Sensor] = []
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var hrLabel: UILabel!
    
    deinit {
        heartRateSensorService.stopDiscovering()
        heartRateSensorService.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        watchManager.delegate = self
        heartRateSensorService.addObserver(self)
    }
    
    fileprivate func reloadRow(with sensor: Sensor) {
        guard let index = sensors.firstIndex(of: sensor) else { return }
        sensors[index] = sensor
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    fileprivate func animateHeartRateChange(with heartRate: HeartRate) {
        UIView.animate(withDuration: 0.15, animations: { 
            self.hrLabel.alpha = 0.0
        }) { (_) in
            DispatchQueue.main.async {
                self.hrLabel.text = "\(heartRate) BPM"
            }
            UIView.animate(withDuration: 0.15) {
                self.hrLabel.alpha = 1.0
            }
        }
    }
    
    @IBAction private func resetButtonTapped(_ sender: UIButton) {      
        heartRateSensorService.select(nil)
        hrLabel.text = "--"
        tableView.reloadData()
    }
    
    @IBAction private func startDiscoverButtonTapped(_ sender: UIButton) {
        sensors = Array(heartRateSensorService.discoveredSensors)
        tableView.reloadData()
        heartRateSensorService.startDiscovering()
    }
    
    @IBAction private func stopDiscoverButtonTapped(_ sender: UIButton) {
        heartRateSensorService.stopDiscovering()
        sensors = []
        tableView.reloadData()
    }
}

extension SensorsViewController: WatchManagerDelegate {
    
    func watchManager(_ WatchManager: WatchManager, didReceive heartRate: Int) {
        guard heartRateSensorService.selectedSensor?.source == .appleWatch else { return }
        DispatchQueue.main.async {
            self.animateHeartRateChange(with: HeartRate(heartRate))
        }
    }
}

extension SensorsViewController: HeartRateSensorObserver {
    
    func heartRateSensorService(_ heartRateSensorService: HeartRateSensorService, didReceive heartRate: HeartRate, from sensor: Sensor) {
        guard sensor.source != .appleWatch else { return }
        animateHeartRateChange(with: heartRate)
    }
    
    func heartRateSensorService(_ heartRateSensorService: HeartRateSensorService, didDiscover sensor: Sensor) {
        sensors.append(sensor)
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.sensors.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }
    }
    
    func heartRateSensorService(_ heartRateSensorService: HeartRateSensorService, didConnect sensor: Sensor) {
        reloadRow(with: sensor)
    }
    
    func heartRateSensorService(_ heartRateSensorService: HeartRateSensorService, didDisconnect sensor: Sensor) {
        reloadRow(with: sensor)
    }
    
    func heartRateSensorService(_ heartRateSensorService: HeartRateSensorService, didSelect sensor: Sensor) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }    
}

extension SensorsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sensors.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SensorCell") as? SensorCell else {
            return UITableViewCell()
        }
        let sensor = sensors[indexPath.row]
        let isSensorSelected = heartRateSensorService.selectedSensor == sensor
        cell.setup(with: sensor, selected: isSensorSelected)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sensor = sensors[indexPath.row]
        
        if sensor.source == .appleWatch {
            let typesToShare: Set = [HKQuantityType.workoutType()]
            let typesToRead: Set = [HKQuantityType.quantityType(forIdentifier: .heartRate)!]
            healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] (success, error) in
                self?.heartRateSensorService.select(sensor)
            }
        } else {
            heartRateSensorService.select(sensor)
        }
    }
}
