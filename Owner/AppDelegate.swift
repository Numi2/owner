//
//  AppDelegate.swift
//  Owner
//
//  Created by T on 6/21/25.
//

import UIKit
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register background tasks
        registerBackgroundTasks()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Schedule background task for income processing
        scheduleBackgroundIncome()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Cancel background tasks as app is now active
        UIApplication.shared.cancelAllLocalNotifications()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Background Tasks
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.numi.Owner.income", using: nil) { task in
            self.handleBackgroundIncome(task: task as! BGProcessingTask)
        }
    }
    
    private func scheduleBackgroundIncome() {
        let request = BGProcessingTaskRequest(identifier: "com.numi.Owner.income")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background income task scheduled")
        } catch {
            print("Failed to schedule background task: \(error)")
        }
    }
    
    private func handleBackgroundIncome(task: BGProcessingTask) {
        // Schedule next background task
        scheduleBackgroundIncome()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Process passive income in background
        // Note: In a real implementation, this would need to access the GameManager
        // For now, we'll just complete the task
        DispatchQueue.global().async {
            // Simulate income processing
            Thread.sleep(forTimeInterval: 1.0)
            
            DispatchQueue.main.async {
                task.setTaskCompleted(success: true)
            }
        }
    }
}

// MARK: - Extensions for iOS 13 compatibility
extension UIApplication {
    func cancelAllLocalNotifications() {
        // iOS 10+ method
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

