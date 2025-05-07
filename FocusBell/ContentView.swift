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

    // MARK: - 配置常量
    /// 单轮时长（秒）——未来要改成 300，只改这里
    private let cycleDuration: Int = 300        // 300 亦可

    // MARK: - 核心状态（持久化）
    @AppStorage("countdown")          private var countdown: Int = 300
    @AppStorage("roundsCompleted")    private var roundsCompleted: Int = 0
    @AppStorage("totalSeconds")       private var totalSecondsElapsed: Int = 0
    @AppStorage("dingTime")           private var dingTime: Int = Int.random(in: 1...180)
    @AppStorage("beepPlayed")         private var beepPlayed: Bool = false
    @AppStorage("isRunning")          private var isRunning: Bool = false
    @AppStorage("isPaused")           private var isPaused: Bool = false
    @AppStorage("cycleStart")         private var cycleStartTime: Double = 0

    // MARK: - 运行期对象
    @State private var bgTimer: DispatchSourceTimer?
    @State private var player: AVAudioPlayer?          // 播放 ding
    @State private var silencePlayer: AVAudioPlayer?   // 后台保活

    @Environment(\.scenePhase) private var scenePhase

    // MARK: - 计算属性
    private var elapsedMinutes: Int {
        (roundsCompleted * cycleDuration + (cycleDuration - countdown)) / 60
    }

    // MARK: - 视图
    var body: some View {
        VStack(spacing: 30) {

            Text(String(format: NSLocalizedString("countdown", comment: ""), countdown))
                .font(.largeTitle).bold()

            Text(String(format: NSLocalizedString("rounds", comment: ""), roundsCompleted))
                .font(.title2)

            Text(String(format: NSLocalizedString("elapsed", comment: ""), elapsedMinutes))
                .font(.title3)

            HStack(spacing: 20) {

                Button(action: startPauseResume) {
                    Text(buttonTitle)
                        .frame(minWidth: 100).padding()
                        .background(buttonColor).foregroundColor(.white)
                        .cornerRadius(12).font(.headline)
                }

                Button(action: resetAll) {
                    Text(NSLocalizedString("reset", comment: ""))
                        .frame(minWidth: 100).padding()
                        .background(Color.blue.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(12).font(.headline)
                }
            }
        }
        .padding()
        .onChange(of: scenePhase, perform: handleSceneChange)
    }

    // MARK: - UI 计算
    private var buttonTitle: String {
        if !isRunning { NSLocalizedString("start", comment: "") }
        else { isPaused ? NSLocalizedString("resume", comment: "")
                        : NSLocalizedString("pause",  comment: "") }
    }
    private var buttonColor: Color { (!isRunning || isPaused) ? .green : .orange }

    // MARK: - 开始 / 暂停 / 恢复
    private func startPauseResume() {
        if !isRunning { startNewCycle() }
        else { isPaused ? resumeTimer() : pauseTimer() }
    }

    // MARK: - 新周期
    private func startNewCycle() {
        countdown      = cycleDuration
        dingTime       = Int.random(in: 1...(cycleDuration * 3 / 5)) // 60% 区间随机
        beepPlayed     = false
        isRunning      = true
        isPaused       = false
        
        startBackgroundTimer()
        startKeepAliveAudio()
        scheduleBeepNotification()
        cycleStartTime = Date().timeIntervalSince1970
    }

    // MARK: - 后台定时
    private func startBackgroundTimer() {
        bgTimer?.cancel()

        let timer = DispatchSource.makeTimerSource(queue: .global())
        timer.schedule(deadline: .now() + 1, repeating: 1)
        timer.setEventHandler {        // struct 无需 weak
            tick()
        }
        timer.resume()
        bgTimer = timer
    }

    private func tick() {
        guard isRunning, !isPaused else { return }

        if countdown > 0 {
            countdown -= 1
            totalSecondsElapsed += 1

            if countdown == dingTime && !beepPlayed {
                // 前台才直接播放；后台靠本地通知响
                if UIApplication.shared.applicationState == .active {
                    playBeep()
                }
                beepPlayed = true
            }

        } else {                        // 下一轮
            roundsCompleted += 1
            startNewCycle()
        }
    }

    // MARK: - 暂停 / 恢复
    private func pauseTimer() {
        bgTimer?.suspend()
        silencePlayer?.pause()
        isPaused = true
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["FocusBell_Ding"])
    }

    private func resumeTimer() {
        isPaused = false
        silencePlayer?.play()
        bgTimer?.resume()
        scheduleBeepNotification()
    }

    // MARK: - 重置
    private func resetAll() {
        bgTimer?.cancel(); bgTimer = nil
        silencePlayer?.stop(); silencePlayer = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        countdown = cycleDuration
        roundsCompleted = 0
        totalSecondsElapsed = 0
        beepPlayed = false
        isRunning = false
        isPaused = false
        cycleStartTime = 0
    }

    // MARK: - ding & 保活
    private func playBeep() {
        guard let url = Bundle.main.url(forResource: "ding", withExtension: "mp3") else { return }
        player = try? AVAudioPlayer(contentsOf: url); player?.play()
    }

    private func startKeepAliveAudio() {
        guard silencePlayer == nil,
              let url = Bundle.main.url(forResource: "silence", withExtension: "mp3") else { return }

        silencePlayer = try? AVAudioPlayer(contentsOf: url)
        silencePlayer?.numberOfLoops = -1
        silencePlayer?.volume = 0
        silencePlayer?.play()
    }

    // MARK: - 兜底通知（仅做后台响铃）
    private func scheduleBeepNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["FocusBell_Ding"])

        let secondsUntilBeep = countdown - dingTime      // 只响一次
        guard secondsUntilBeep > 0 else { return }

        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound(named: .init(rawValue: "ding.mp3"))
        content.body  = "FocusBell"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(secondsUntilBeep),
                                                        repeats: false)
        let request = UNNotificationRequest(identifier: "FocusBell_Ding",
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 前后台切换
    private func handleSceneChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            break                            // 后台保持计时
        case .active:
            if !isRunning || isPaused {      // 未运行或暂停时不恢复
                return
            }
            restoreStateFromTimestamp()
        default:
            break
        }
    }

    // MARK: - 状态恢复
    private func restoreStateFromTimestamp() {
        guard isRunning, cycleStartTime > 0 else { return }

        let now   = Date().timeIntervalSince1970
        let delta = Int(now - cycleStartTime)

        let fullRounds = delta / cycleDuration
        let leftover   = delta % cycleDuration

        roundsCompleted += fullRounds
        countdown        = cycleDuration - leftover
        totalSecondsElapsed += delta

        beepPlayed       = countdown <= dingTime

        cycleStartTime = now - TimeInterval(leftover)
        scheduleBeepNotification()
    }
}

#Preview { ContentView() }
