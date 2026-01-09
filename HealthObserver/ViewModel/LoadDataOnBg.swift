////
////  LoadDataOnBg.swift
////  HealthObserver
////
////  Created by Balak Sharma on 06/01/26.
////
//
import HealthKit
import BackgroundTasks

class LoadDataOnBG {
    
        func createSample(from metric: HealthMetric) -> HKQuantitySample? {
            // Map your metric.activity to HealthKit type
            let typeIdentifier: HKQuantityTypeIdentifier?
    
            switch metric.activity.lowercased() {
            case "steps":
                typeIdentifier = .stepCount
            case "heart rate":
                typeIdentifier = .heartRate
            case "active":
                typeIdentifier = .activeEnergyBurned
            case "bodyfat":
                typeIdentifier = .bodyFatPercentage
            case "weight":
                typeIdentifier = .bodyMass
            case "height":
                typeIdentifier = .height
            case "pushcount":
                typeIdentifier = .pushCount // If custom, might need your own logic
            case "runningspeed":
                typeIdentifier = .distanceWalkingRunning // closest approximation
            case "hrv":
                typeIdentifier = .heartRateVariabilitySDNN
            case "resting_hr":
                typeIdentifier = .restingHeartRate
            case "resting_energy":
                typeIdentifier = .basalEnergyBurned
            case "walking + running distance":
                typeIdentifier = .distanceWalkingRunning
            case "double suport time":
                typeIdentifier = nil // HealthKit doesn’t support this directly
            case "walking asymmetry":
                typeIdentifier = nil // Not available in HealthKit
            case "walking speed":
                typeIdentifier = nil // Not available in HealthKit
            case "walking step length":
                typeIdentifier = nil // Not available in HealthKit
            default:
                typeIdentifier = nil
            }
    
            guard let id = typeIdentifier,
                  let quantityType = HKQuantityType.quantityType(forIdentifier: id) else {
                return nil // Skip unsupported metrics
            }
    
            // Remove units from string and convert to Double
            let valueString = metric.value.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            guard let value = Double(valueString) else { return nil }
    
            // Choose the correct HKUnit
            let unit: HKUnit
            switch id {
            case .stepCount, .pushCount:
                unit = HKUnit.count()
            case .heartRate, .restingHeartRate:
                unit = HKUnit.count().unitDivided(by: HKUnit.minute())
            case .activeEnergyBurned, .basalEnergyBurned:
                unit = HKUnit.kilocalorie()
            case .bodyFatPercentage:
                unit = HKUnit.percent()
            case .bodyMass:
                unit = HKUnit.gramUnit(with: .kilo)
            case .height:
                unit = HKUnit.meter()
            case .distanceWalkingRunning:
                unit = HKUnit.mile() // Or .meter() if you prefer
            case .heartRateVariabilitySDNN:
                unit = HKUnit.secondUnit(with: .milli)
            default:
                return nil
            }
    
            let quantity = HKQuantity(unit: unit, doubleValue: value)
            let now = Date()
            return HKQuantitySample(type: quantityType, quantity: quantity, start: now, end: now)
        }
    
    
        func requestAuthorization(completion: @escaping (Bool) -> Void) {
            guard HKHealthStore.isHealthDataAvailable() else {
                completion(false)
                return
            }
    
            let healthStore = HKHealthStore()
            let typesToRead: Set<HKObjectType> = [
                HKObjectType.quantityType(forIdentifier: .stepCount)!,
                HKObjectType.quantityType(forIdentifier: .heartRate)!,
                HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
                HKObjectType.quantityType(forIdentifier: .bodyMass)!,
                HKObjectType.quantityType(forIdentifier: .height)!,
                HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
                HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
                HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
            ]
    
            healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
                if let error = error {
                    print("HealthKit authorization failed: \(error.localizedDescription)")
                }
                completion(success)
            }
        }
    
        func enableBackgroundDelivery() {
            let healthStore = HKHealthStore()
    
            // Include all HealthKit-supported types from your metrics
            let types: [HKQuantityTypeIdentifier] = [
                .stepCount,                     // Steps
                .heartRate,                     // Heart Rate
                .activeEnergyBurned,            // Active Energy
                .bodyFatPercentage,             // Body Fat
                .bodyMass,                      // Body Mass
                .height,                        // Height
                .restingHeartRate,              // Resting HR
                .basalEnergyBurned,             // Resting Energy
                .distanceWalkingRunning,        // Walking + Running Distance
                .heartRateVariabilitySDNN       // HRV
            ]
    
            for typeIdentifier in types {
                if let type = HKQuantityType.quantityType(forIdentifier: typeIdentifier) {
                    healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
                        if let error = error {
                            print("Background delivery error for \(typeIdentifier.rawValue): \(error.localizedDescription)")
                        } else {
                            print("Background delivery enabled for \(typeIdentifier.rawValue)")
                        }
                    }
                }
            }
        }
    


    let store = HKHealthStore()

    let identifiers: [HKQuantityTypeIdentifier] = [
        .stepCount, .heartRate, .activeEnergyBurned, .bodyFatPercentage,
        .bodyMass, .height, .restingHeartRate, .basalEnergyBurned,
        .distanceWalkingRunning, .heartRateVariabilitySDNN
    ]

    func startObserverQueries() {

        for id in identifiers {
            guard let type = HKQuantityType.quantityType(forIdentifier: id) else { continue }

            let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completion, _ in
                self.scheduleBGUpload()
                completion()
            }

            store.execute(query)
        }
    }

    func scheduleBGUpload() {

        let request = BGProcessingTaskRequest(identifier: "com.kbs.health.upload")
        request.requiresNetworkConnectivity = true

        do {
            try BGTaskScheduler.shared.submit(request)
            print("BGTask submitted")
        } catch {
            print("BGTask submit error: \(error.localizedDescription)")
        }
    }


    func fetchAndUploadAllPending(completion: @escaping () -> Void) {

        let group = DispatchGroup()

        for id in identifiers {
            guard let type = HKQuantityType.quantityType(forIdentifier: id) else { continue }

            group.enter()
            fetchLatestSample(for: type) { payload in
                if let payload = payload {
                    self.uploadInBackground(payload)
                }
                group.leave()
            }
            
            
        }

        group.notify(queue: .global()) {
            completion()
        }
    }
    func fetchLatestSample(for type: HKQuantityType,
                           completion: @escaping ([String: Any]?) -> Void) {

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(sampleType: type,
                                  predicate: nil,
                                  limit: 1,
                                  sortDescriptors: [sort]) { [weak self] _, samples, _ in

            guard let self,
                  let sample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }

            let unit = self.unit(for: HKQuantityTypeIdentifier(rawValue: type.identifier))

            let payload: [String: Any] = [
                "id": sample.uuid.uuidString,
                "type": type.identifier,
                "source": unit.unitString,
                "displayName": sample.sourceRevision.source.name
            ]
            
         
            self.uploadInBackground(payload)
            completion(payload)
        }

        store.execute(query)
    }
    func unit(for identifier: HKQuantityTypeIdentifier) -> HKUnit {

        switch identifier {

        case .stepCount:
            return .count()

        case .heartRate:
            return HKUnit.count().unitDivided(by: .minute())

        case .activeEnergyBurned:
            return .kilocalorie()

        case .bodyFatPercentage:
            return .percent()

        case .bodyMass:
            return .gramUnit(with: .kilo)

        case .height:
            return .meter()

        case .distanceWalkingRunning:
            return .meter()

        case .heartRateVariabilitySDNN:
            return .secondUnit(with: .milli)

        case .restingHeartRate:
            return HKUnit.count().unitDivided(by: .minute())

        default:
            return .count()
        }
    }

    func uploadInBackground(_ payload: [String: Any]) {

        let url = URL(string: "https://a912b3fba9dc.ngrok-free.app/api/health-temp-data")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")

        let data = try! JSONSerialization.data(withJSONObject: payload)
        try! data.write(to: fileURL)

        let task = AppDelegate.shared.backgroundSession.uploadTask(with: request, fromFile: fileURL)
        task.resume()
    }
}
