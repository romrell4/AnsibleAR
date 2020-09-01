//
//  AppDelegate.swift
//  BerryPlus
//
//  Created by Gavin Jensen on 7/27/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

import UIKit
import CoreNFC

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
//    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
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
    
//    func application(_ application: UIApplication,
//                     continue userActivity: NSUserActivity,
//                     restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
//
//        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else {
//            return false
//        }
//
//        // Confirm that the NSUserActivity object contains a valid NDEF message.
//        let ndefMessage = userActivity.ndefMessagePayload
//        guard ndefMessage.records.count > 0,
//            ndefMessage.records[0].typeNameFormat != .empty else {
//                return false
//        }
//
//        // Send the message to `MessagesTableViewController` for processing.
//        guard let navigationController = window?.rootViewController as? UINavigationController else {
//            return false
//        }
//
//        navigationController.popToRootViewController(animated: true)
//        let viewController = navigationController.topViewController as? ViewController
//        viewController?.addMessage(fromUserActivity: ndefMessage)
//
//        return true
//    }


}

