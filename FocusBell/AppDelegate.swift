//
//  Untitled.swift
//  FocusTimer
//
//  Created by 甘星 on 02/05/2025.
//
import UIKit
import AVFoundation
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        // 开启音频后台模式
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("通知权限请求失败: \(error.localizedDescription)")
            }
        }
        
        // 加载用户选择的语言
        if let languages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String], let savedLang = languages.first {
            UserDefaults.standard.set([savedLang], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }

        return true
    }
}
