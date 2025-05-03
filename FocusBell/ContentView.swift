//
//  ContentView.swift
//  FocusTimer
//
//  Created by 甘星 on 02/05/2025.
//

import SwiftUI

import AVFoundation
import UserNotifications

struct ContentView: View {
    @State private var status: String = NSLocalizedString("start", comment: "")
    @State private var countdown: Int = 300
    @State private var uiTimer: Timer? = nil
    @State private var beepPlayed: Bool = false
    @State private var player: AVAudioPlayer?
    @State private var roundsCompleted: Int = 0
    @State private var totalSecondsElapsed: Int = 0
    @State private var dingTime: Int = Int.random(in: 1...180)
    @State private var isRunning: Bool = false
    @State private var isPaused: Bool = false
    @State private var secondsPassedThisRound: Int = 0

    var body: some View {
        VStack {
            VStack(spacing: 30) {
                Text(String(format: NSLocalizedString("countdown", comment: ""), countdown))
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(String(format: NSLocalizedString("rounds", comment: ""), roundsCompleted))
                    .font(.title2)

                Text(String(format: NSLocalizedString("elapsed", comment: ""), totalSecondsElapsed / 60))
                    .font(.title3)

                HStack(spacing: 20) {
                    Button(action: {
                        if !isRunning {
                            startRandomBeepLoop()
                            isRunning = true
                            isPaused = false
                        } else {
                            if isPaused {
                                resumeTimer()
                                isPaused = false
                            } else {
                                pauseTimer()
                                isPaused = true
                            }
                        }
                    }) {
                        Text(!isRunning ? NSLocalizedString("start", comment: "") : (isPaused ? NSLocalizedString("resume", comment: "") : NSLocalizedString("pause", comment: "")))
                            .padding()
                            .frame(minWidth: 100)
                            .background(isPaused ? Color.green : (isRunning ? Color.orange : Color.green))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .font(.headline)
                    }

                    Button(action: {
                        uiTimer?.invalidate()
                        countdown = 300
                        beepPlayed = false
                        roundsCompleted = 0
                        totalSecondsElapsed = 0
                        dingTime = Int.random(in: 1...180)
                        isRunning = false
                        isPaused = false
                    }) {
                        Text(NSLocalizedString("reset", comment: ""))
                            .padding()
                            .frame(minWidth: 100)
                            .background(Color.blue.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .font(.headline)
                    }
                }
            }
            .padding()
        }
        .environment(\.locale, Locale.current)
    }

    func startRandomBeepLoop() {
        uiTimer?.invalidate()
        countdown = 300
        beepPlayed = false
        secondsPassedThisRound = 0
        dingTime = Int.random(in: 1...180)
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
                secondsPassedThisRound += 1
                if secondsPassedThisRound == 60 {
                    totalSecondsElapsed += 60
                    secondsPassedThisRound = 0
                }
                if countdown == dingTime && !beepPlayed {
                    playBeep()
                    scheduleNotification()
                    beepPlayed = true
                }
            } else {
                countdown = 300
                beepPlayed = false
                roundsCompleted += 1
                secondsPassedThisRound = 0
                dingTime = Int.random(in: 1...180)
            }
        }
    }

    func pauseTimer() {
        uiTimer?.invalidate()
    }

    func resumeTimer() {
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
                secondsPassedThisRound += 1
                if secondsPassedThisRound == 60 {
                    totalSecondsElapsed += 60
                    secondsPassedThisRound = 0
                }
                if countdown == dingTime && !beepPlayed {
                    playBeep()
                    scheduleNotification()
                    beepPlayed = true
                }
            } else {
                countdown = 300
                beepPlayed = false
                roundsCompleted += 1
                secondsPassedThisRound = 0
                dingTime = Int.random(in: 1...180)
            }
        }
    }

    func playBeep() {
        guard let url = Bundle.main.url(forResource: "ding", withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("播放失败: \(error.localizedDescription)")
        }
    }

    func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("start", comment: "")
        content.body = NSLocalizedString("resume", comment: "")
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

#Preview {
    ContentView()
}
