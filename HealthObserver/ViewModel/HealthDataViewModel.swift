//////
//////  HealthDataViewModel.swift
//////  HealthObserver
//////
//////  Created by KBS on 1/2/26.
//////
////
///
import Foundation
import Observation
import HealthKit
import Combine

@MainActor
final class HealthDataViewModel: ObservableObject {

    var isAuthorized = false
    var errorMessage: String?

    // Core Metrics
   @Published var stepCount = 0.0
    @Published var heartRate = 0.0
    @Published var restingHeartRate = 0.0
    @Published var activeEnergy = 0.0
    @Published var restingEnergy = 0.0
    @Published var distanceWalkingRunning = 0.0
    @Published var pushCount = 0.0

    // Body Metrics (latest ever)
    @Published var bodyFatPercentage = 0.0
    @Published var bodyMass = 0.0
    @Published var height = 0.0

    // Walking Metrics
    @Published var walkingSpeed = 0.0
    @Published  var walkingStepLength = 0.0
    @Published  var walkingAsymmetry = 0.0
    @Published var walkingDoubleSupport = 0.0
    
    @Published var runningSpeed = 0.0

    // Heart Metrics
    var hrv = 0.0

    // Sleep
    @Published var sleepScore = 0
    @Published var stepsGraph: [HealthGraphPoint] = []
    @Published  var activeEnergyGraph: [HealthGraphPoint] = []
    @Published  var restingEnergyGraph: [HealthGraphPoint] = []
    @Published  var distanceGraph: [HealthGraphPoint] = []
    @Published  var heartRateGraph: [HealthGraphPoint] = []
    @Published  var restingHRGraph: [HealthGraphPoint] = []
    @Published  var hrvGraph: [HealthGraphPoint] = []
    @Published  var walkingSpeedGraph: [HealthGraphPoint] = []
    @Published  var walkingAsymmetryGraph: [HealthGraphPoint] = []
    @Published var doubleSupportGraph: [HealthGraphPoint] = []
    @Published  var bodyFatGraphData: [HealthGraphPoint] = []
    @Published  var bodyMassGraphData: [HealthGraphPoint] = []
    @Published var heightGraphData: [HealthGraphPoint] = []
    @Published var pushCountGraphData: [HealthGraphPoint] = []
    @Published var runningSpeedGraphData: [HealthGraphPoint] = []
    @Published  var stepLengthGraphData: [HealthGraphPoint] = []
    @Published var walkingStepLengthGData: [HealthGraphPoint] = []
    
    func requestAuthorization(complition: @escaping (Bool) -> Void) async {
        do {
            let success = try await HealthKitManager.shared.requestAuthorization()
            isAuthorized = success
            if success {
                await fetchAllHealthData()
                complition(true)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchAllHealthData() async {

        async let steps = HealthKitManager.shared.fetchDailySum(.stepCount)
        async let activeEnergy = HealthKitManager.shared.fetchDailySum(.activeEnergyBurned)
        async let restingEnergy = HealthKitManager.shared.fetchDailySum(.basalEnergyBurned)
        async let distance = HealthKitManager.shared.fetchDailySum(.distanceWalkingRunning)
        async let pushCount = HealthKitManager.shared.fetchDailySum(.pushCount)

        async let heartRate = HealthKitManager.shared.fetchDailyAverage(.heartRate)
        async let restingHR = HealthKitManager.shared.fetchDailyAverage(.restingHeartRate)
        async let hrv = HealthKitManager.shared.fetchDailyAverage(.heartRateVariabilitySDNN)

        async let walkingSpeed = HealthKitManager.shared.fetchDailyAverage(.walkingSpeed)
        async let stepLength = HealthKitManager.shared.fetchDailyAverage(.walkingStepLength)
        async let walkingAsymmetry = HealthKitManager.shared.fetchDailyAverage(.walkingAsymmetryPercentage)
        async let walkingDoubleSupport = HealthKitManager.shared.fetchDailyAverage(.walkingDoubleSupportPercentage)

        async let bodyFat = HealthKitManager.shared.fetchLatestSample(.bodyFatPercentage, unit: .percent())
        async let bodyMass = HealthKitManager.shared.fetchLatestSample(.bodyMass, unit: .gramUnit(with: .kilo))
        async let height = HealthKitManager.shared.fetchLatestSample(.height, unit: .meter())

        async let sleepHours = HealthKitManager.shared.fetchLastNightSleepHours()

        self.stepCount = (try? await steps) ?? 0
        self.activeEnergy = (try? await activeEnergy) ?? 0
        self.restingEnergy = (try? await restingEnergy) ?? 0
        self.distanceWalkingRunning = (try? await distance) ?? 0
        self.pushCount = (try? await pushCount) ?? 0

        self.heartRate = (try? await heartRate) ?? 0
        self.restingHeartRate = (try? await restingHR) ?? 0
        self.hrv = (try? await hrv) ?? 0

        self.walkingSpeed = (try? await walkingSpeed) ?? 0
        self.walkingStepLength = (try? await stepLength) ?? 0
        self.walkingAsymmetry = (try? await walkingAsymmetry) ?? 0
        self.walkingDoubleSupport = (try? await walkingDoubleSupport) ?? 0

        self.bodyFatPercentage = ((try? await bodyFat) ?? 0) * 100
        self.bodyMass = (try? await bodyMass) ?? 0
        self.height = (try? await height) ?? 0

        let hours = (try? await sleepHours) ?? 0
        self.sleepScore = HealthKitManager.shared.calculateSleepScore(hours: hours)
        await self.loadGraph()
    }
    func loadGraph() async {
        async let stepsG = HealthKitManager.shared.fetchDailySeries(.stepCount, unit: .count(), option: .cumulativeSum)
        async let activeEnergyG = HealthKitManager.shared.fetchDailySeries(.activeEnergyBurned, unit: .kilocalorie(), option: .cumulativeSum)
        async let restingEnergyG = HealthKitManager.shared.fetchDailySeries(.basalEnergyBurned, unit: .kilocalorie(), option: .cumulativeSum)
        async let distanceG = HealthKitManager.shared.fetchDailySeries(.distanceWalkingRunning, unit: .meter(), option: .cumulativeSum)

        async let heartRateG = HealthKitManager.shared.fetchDailySeries(.heartRate, unit: .count().unitDivided(by: .minute()), option: .discreteAverage)
        async let restingHRG = HealthKitManager.shared.fetchDailySeries(.restingHeartRate, unit: .count().unitDivided(by: .minute()), option: .discreteAverage)
        async let hrvG = HealthKitManager.shared.fetchDailySeries(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), option: .discreteAverage)

        async let walkingSpeedG = HealthKitManager.shared.fetchDailySeries(.walkingSpeed, unit: .meter().unitDivided(by: .second()), option: .discreteAverage)
        
        async let stepLengthG = HealthKitManager.shared.fetchDailySeries(.walkingStepLength, unit: .meter(), option: .discreteAverage)
        
        async let walkingAsymmetryG = HealthKitManager.shared.fetchDailySeries(.walkingAsymmetryPercentage, unit: .percent(), option: .discreteAverage)
        async let doubleSupportG = HealthKitManager.shared.fetchDailySeries(.walkingDoubleSupportPercentage, unit: .percent(), option: .discreteAverage)
        
        async let bodyFatGraph = HealthKitManager.shared.fetchDailySeries(
            .bodyFatPercentage,
            unit: .percent(),
            option: .discreteAverage
        )

        async let bodyMassGraph = HealthKitManager.shared.fetchDailySeries(
            .bodyMass,
            unit: .gramUnit(with: .kilo),
            option: .discreteAverage
        )

        async let heightGraph = HealthKitManager.shared.fetchDailySeries(
            .height,
            unit: .meter(),
            option: .discreteAverage
        )

        async let pushCountGraph = HealthKitManager.shared.fetchDailySeries(
            .pushCount,
            unit: .count(),
            option: .cumulativeSum
        )

        async let runningSpeedGraph = HealthKitManager.shared.fetchDailySeries(
            .runningSpeed,
            unit: .meter().unitDivided(by: .second()),
            option: .discreteAverage
        )

        async let stepLengthGraph = HealthKitManager.shared.fetchDailySeries(
            .walkingStepLength,
            unit: .meter(),
            option: .discreteAverage
        )

        
        bodyFatGraphData = (try? await bodyFatGraph) ?? []
        bodyMassGraphData = (try? await bodyMassGraph) ?? []
        heightGraphData = (try? await heightGraph) ?? []
        pushCountGraphData = (try? await pushCountGraph) ?? []
        runningSpeedGraphData = (try? await runningSpeedGraph) ?? []
        stepLengthGraphData = (try? await stepLengthGraph) ?? []

        
        
        stepsGraph = (try? await stepsG) ?? []
        activeEnergyGraph = (try? await activeEnergyG) ?? []
        restingEnergyGraph = (try? await restingEnergyG) ?? []
        distanceGraph = (try? await distanceG) ?? []

        heartRateGraph = (try? await heartRateG) ?? []
        restingHRGraph = (try? await restingHRG) ?? []
        hrvGraph = (try? await hrvG) ?? []

        walkingSpeedGraph = (try? await walkingSpeedG) ?? []
        walkingAsymmetryGraph = (try? await walkingAsymmetryG) ?? []
        doubleSupportGraph = (try? await doubleSupportG) ?? []
        
        walkingStepLengthGData = (try? await stepLengthG) ?? []


        }
}
