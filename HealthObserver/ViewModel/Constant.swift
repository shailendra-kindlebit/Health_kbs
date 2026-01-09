//
//  Constant.swift
//  HealthObserver
//
//  Created by KBS on 12/31/25.
//
import SwiftUI

extension Color {
    static let healthBackground = Color(
        red: 240/255,
        green: 239/255,
        blue: 245/255
    )
}

enum HealthIcon {

    // Activity
    case steps
    case distance
    case activeEnergy
    case restingEnergy
    case pushCount

    // Heart
    case heartRate
    case restingHR
    case hrv

    // Walking / Running
    case runningSpeed
    case walkingSpeed
    case stepLength
    case walkingAsymmetry
    case doubleSupport

    // Body
    case bodyFat
    case bodyMass
    case height

    // Sleep
    case sleep

    var systemName: String {
        switch self {
        case .steps: return "figure.walk"
        case .distance: return "location.north.line.fill"
        case .activeEnergy: return "flame.fill"
        case .restingEnergy: return "bed.double.fill"
        case .pushCount: return "figure.strengthtraining.traditional"

        case .heartRate: return "heart.fill"
        case .restingHR: return "heart.circle.fill"
        case .hrv: return "waveform.path.ecg"

        case .runningSpeed: return "figure.run"
        case .walkingSpeed: return "figure.walk.motion"
        case .stepLength: return "ruler.fill"
        case .walkingAsymmetry: return "figure.walk.diamond.fill"
        case .doubleSupport: return "figure.walk.circle.fill"

        case .bodyFat: return "figure.stand"
        case .bodyMass: return "scalemass.fill"
        case .height: return "ruler"

        case .sleep: return "bed.double.fill"
        }
    }

    var color: Color {
        switch self {
        case .heartRate, .restingHR, .hrv:
            return .red
        case .steps, .distance, .walkingSpeed, .runningSpeed:
            return .blue
        case .activeEnergy, .restingEnergy, .pushCount:
            return .orange
        case .bodyFat, .bodyMass, .height:
            return .purple
        case .walkingAsymmetry, .doubleSupport, .stepLength:
            return .green
        case .sleep:
            return .indigo
        }
    }
}
