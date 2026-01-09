//
//  AppDelegate.swift
//  HealthObserver
//
//  Created by KBS on 1/7/26.
//

import UIKit
import BackgroundTasks

//class AppDelegate: NSObject, UIApplicationDelegate, URLSessionDelegate, URLSessionTaskDelegate {
//
//    private var bgCompletionHandler: (() -> Void)?
//    static var shared: AppDelegate!
//
//    func application(_ application: UIApplication,
//                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
//
//        BGTaskScheduler.shared.register(
//            forTaskWithIdentifier: "com.kbs.HealthObserver",
//            using: nil) { task in
//                self.handleHealthUpload(task: task as! BGProcessingTask)
//        }
//
//        return true
//    }
//
//    func handleHealthUpload(task: BGProcessingTask) {
//
//        scheduleHealthUpload()
//
//        let config = URLSessionConfiguration.background(withIdentifier: "com.kbs.HealthObserver")
//        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
//
//        task.expirationHandler = {
//            session.invalidateAndCancel()
//        }
//
//        bgCompletionHandler = {
//            task.setTaskCompleted(success: true)
//        }
//
//     //   upload(session: session, payLoad: <#[String : Any]#>)
//    }
//
//    func scheduleHealthUpload() {
//        let request = BGProcessingTaskRequest(identifier: "com.kbs.HealthObserver")
//        request.requiresNetworkConnectivity = true
//        request.requiresExternalPower = false
//        try? BGTaskScheduler.shared.submit(request)
//    }
//
//    func urlSession(_ session: URLSession,
//                    task: URLSessionTask,
//                    didCompleteWithError error: Error?) {
//
//        if let error = error {
//            print("❌ Upload failed:", error.localizedDescription)
//        } else {
//            print("✅ Upload completed successfully")
//        }
//
//        bgCompletionHandler?()
//        bgCompletionHandler = nil
//    }
//}
import UIKit
import HealthKit
import BackgroundTasks

class AppDelegate: UIResponder, UIApplicationDelegate, URLSessionDelegate {

    static var shared: AppDelegate!

    var bgCompletionHandler: (() -> Void)?

    lazy var backgroundSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.kbs.health.bg.upload")
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        AppDelegate.shared = self

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.kbs.health.upload",
            using: nil
        ) { task in
            self.handleHealthUpload(task: task as! BGProcessingTask)
        }

        LoadDataOnBG().startObserverQueries()
        LoadDataOnBG().enableBackgroundDelivery()

        return true
    }

    func handleHealthUpload(task: BGProcessingTask) {

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        LoadDataOnBG().fetchAndUploadAllPending {
            task.setTaskCompleted(success: true)
        }
    }

    func application(_ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void) {

        bgCompletionHandler = completionHandler
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.bgCompletionHandler?()
            self.bgCompletionHandler = nil
        }
    }
}
