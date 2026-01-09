//
//  HealthMetric.swift
//  HealthObserver
//
//  Created by KBS on 12/31/25.
//
import SwiftUI

struct HealthMetric: Identifiable, Equatable {
    let id: UUID
    let title: String
    let value:String
    let unit: String
    let activity: String
    let icon: HealthIcon
    var graphData: [HealthGraphPoint]

    init(title: String,value: String, unit: String, activity: String, icon: HealthIcon, graphData: [HealthGraphPoint]) {
        self.id = UUID()
        self.title = title
        self.value = value
        self.unit = unit
        self.activity = activity
        self.icon = icon
        self.graphData = graphData
    }

    static func == (lhs: HealthMetric, rhs: HealthMetric) -> Bool {
        lhs.id == rhs.id
    }
}


struct HealthSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let tint: Color
    let items: [HealthMetric]
}

struct HealthGraphPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}
