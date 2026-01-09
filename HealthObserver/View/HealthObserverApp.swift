//
//  HealthObserverApp.swift
//  HealthObserver
//
//  Created by KBS on 12/31/25.
//

import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct HealthObserverApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    LoadDataOnBG().requestAuthorization { granted in
                        if granted {
                            LoadDataOnBG().startObserverQueries()
                            LoadDataOnBG().enableBackgroundDelivery()
                        }
                    }
                }
        }
    }
}
