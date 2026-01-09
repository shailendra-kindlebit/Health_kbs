////
////  HealthKitManager.swift
////  HealthObserver
////
////  Created by KBS on 1/2/26.
////
//

import HealthKit

final class HealthKitManager {

    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    private init() {}

    // MARK: - Authorization
    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let readTypes: Set<HKObjectType> = [
            .quantityType(forIdentifier: .stepCount)!,
            .quantityType(forIdentifier: .heartRate)!,
            .quantityType(forIdentifier: .activeEnergyBurned)!,
            .quantityType(forIdentifier: .basalEnergyBurned)!,
            .quantityType(forIdentifier: .distanceWalkingRunning)!,
            .quantityType(forIdentifier: .bodyFatPercentage)!,
            .quantityType(forIdentifier: .bodyMass)!,
            .quantityType(forIdentifier: .height)!,
            .quantityType(forIdentifier: .pushCount)!,
            .quantityType(forIdentifier: .runningSpeed)!,
            .quantityType(forIdentifier: .walkingSpeed)!,
            .quantityType(forIdentifier: .walkingStepLength)!,
            .quantityType(forIdentifier: .walkingAsymmetryPercentage)!,
            .quantityType(forIdentifier: .walkingDoubleSupportPercentage)!,
            .quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            .quantityType(forIdentifier: .restingHeartRate)!,
            .categoryType(forIdentifier: .sleepAnalysis)!
        ]

        return try await withCheckedThrowingContinuation { cont in
            healthStore.requestAuthorization(toShare: [], read: readTypes) { ok, err in
                
                err != nil ? cont.resume(throwing: err!) : cont.resume(returning: ok)
                
            }
        }
    }

    // MARK: - Helpers

    private func startOfDay() -> Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    func fetchDailySum(_ id: HKQuantityTypeIdentifier) async throws -> Double {
        
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else {
            print("⚠️ Invalid quantity type:", id.rawValue)
            return 0
        }

        let pred = HKQuery.predicateForSamples(withStart: startOfDay(), end: Date())
        print("📅 Predicate start:", startOfDay(), "end:", Date())
        
        return try await withCheckedThrowingContinuation { cont in
            let q = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: pred,
                options: .cumulativeSum
            ) { _, res, error in

                if let error {
                    print("❌ HealthKit error:", error.localizedDescription)
                    cont.resume(throwing: error)
                    return
                }

                guard let sum = res?.sumQuantity() else {
                    print("⚠️ sumQuantity is nil for:", id.rawValue)
                    cont.resume(returning: 0)
                    return
                }

                let unit: HKUnit =
                    id == .stepCount || id == .pushCount ? .count() :
                    id == .distanceWalkingRunning ? .meter() :
                    .kilocalorie()

                let value = sum.doubleValue(for: unit)
                print("✅ HealthKit \(id.rawValue) value:", value)
                
                cont.resume(returning: value)
            }
            
            healthStore.execute(q)
        }
    }


    // Daily AVERAGE (Heart rate, HRV, walking metrics)
    func fetchDailyAverage(_ id: HKQuantityTypeIdentifier) async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return 0 }
        let pred = HKQuery.predicateForSamples(withStart: startOfDay(), end: Date())

        return try await withCheckedThrowingContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .discreteAverage) { _, res, _ in
                guard let avg = res?.averageQuantity() else { cont.resume(returning: 0); return }

                let unit: HKUnit =
                    id == .heartRate || id == .restingHeartRate ? .count().unitDivided(by: .minute()) :
                    id == .heartRateVariabilitySDNN ? .secondUnit(with: .milli) :
                    id == .walkingSpeed || id == .runningSpeed ? .meter().unitDivided(by: .second()) :
                    id == .walkingStepLength ? .meter() :
                    .percent()

                cont.resume(returning: avg.doubleValue(for: unit))
            }
            healthStore.execute(q)
        }
    }

    // Latest EVER (Body metrics)
    func fetchLatestSample(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return 0 }

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit) ?? 0
                cont.resume(returning: value)
            }
            healthStore.execute(q)
        }
    }

    // MARK: - Sleep

    func fetchLastNightSleepHours() async throws -> Double {
        let type = HKCategoryType(.sleepAnalysis)
        let start = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())

        return try await withCheckedThrowingContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let sleep = (samples as? [HKCategorySample] ?? []).filter {
                    [HKCategoryValueSleepAnalysis.asleep.rawValue,
                     HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                     HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                     HKCategoryValueSleepAnalysis.asleepREM.rawValue].contains($0.value)
                }

                let total = sleep.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                cont.resume(returning: total / 3600)
            }
            healthStore.execute(q)
        }
    }

    func calculateSleepScore(hours: Double) -> Int {
        switch hours {
        case 8...: return 95
        case 7..<8: return 85
        case 6..<7: return 70
        case 5..<6: return 55
        default: return 40
        }
    }
    
    func fetchDailySeries(
        _ id: HKQuantityTypeIdentifier,
        unit: HKUnit,
        option: HKStatisticsOptions,
        days: Int = 7
    ) async throws -> [HealthGraphPoint] {

        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return [] }

        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end)!
        let interval = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        return try await withCheckedThrowingContinuation { cont in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: option,
                anchorDate: Calendar.current.startOfDay(for: end),
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, result, _ in
                guard let result else {
                    cont.resume(returning: [])
                    return
                }

                var data: [HealthGraphPoint] = []

                result.enumerateStatistics(from: start, to: end) { stat, _ in
                    let value: Double

                    if option == .cumulativeSum {
                        value = stat.sumQuantity()?.doubleValue(for: unit) ?? 0
                    } else {
                        value = stat.averageQuantity()?.doubleValue(for: unit) ?? 0
                    }

                    data.append(.init(date: stat.startDate, value: value))
                }

                cont.resume(returning: data)
            }

            self.healthStore.execute(query)
        }
    }

}
