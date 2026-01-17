//
//  ContentView.swift
//  Nomie
//
//  Created by Michael Suarez-Russell on 1/16/26.
//

import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var screenTimeManager = ScreenTimeManager()

    var body: some View {
        TabView {
            ProfileView(screenTimeManager: screenTimeManager)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }

            DashboardView(screenTimeManager: screenTimeManager)
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.dots.needle.67percent")
                }

            WeeklySummaryView(screenTimeManager: screenTimeManager)
                .tabItem {
                    Label("Weekly", systemImage: "calendar")
                }
        }
    }
}

#Preview {
    ContentView()
}

@MainActor
final class ScreenTimeManager: ObservableObject {
    @Published var summary: UsageSummary
    @Published var weekly: WeeklySummary
    @Published var sessions: [FocusSession]
    let isMockMode: Bool

    init() {
        summary = UsageSummary.sample
        weekly = WeeklySummary.sample
        sessions = FocusSession.sample
        isMockMode = true
    }

    func logFocusSession(minutes: Int = 10) {
        let newSession = FocusSession(date: Date(), minutes: minutes, note: "Stayed off distracting apps")
        sessions.insert(newSession, at: 0)
        summary.checkIns += 1
        summary.savedMinutes += minutes
        weekly.apply(minutes: minutes, for: Date())
    }
}

struct ProfileView: View {
    @ObservedObject var screenTimeManager: ScreenTimeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AuthorizationCard(screenTimeManager: screenTimeManager)
                    SummaryGrid(summary: screenTimeManager.summary)
                }
                .padding()
            }
            .navigationTitle("Profile")
        }
    }
}

struct DashboardView: View {
    @ObservedObject var screenTimeManager: ScreenTimeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DashboardHeader(summary: screenTimeManager.summary)
                    FocusCheckIn(screenTimeManager: screenTimeManager)
                    RecentSessions(sessions: screenTimeManager.sessions)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct WeeklySummaryView: View {
    @ObservedObject var screenTimeManager: ScreenTimeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    WeeklyStatsCard(weekly: screenTimeManager.weekly)
                    WeeklyChart(weekly: screenTimeManager.weekly)
                    TopAppsCard(weekly: screenTimeManager.weekly)
                }
                .padding()
            }
            .navigationTitle("Weekly Summary")
        }
    }
}

struct AuthorizationCard: View {
    @ObservedObject var screenTimeManager: ScreenTimeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Screen Time Access")
                .font(.headline)
            Text(statusDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var statusDescription: String {
        if screenTimeManager.isMockMode {
            return "Running in mock mode while Screen Time entitlements are unavailable."
        }
        return "Screen Time access status unavailable."
    }
}

struct SummaryGrid: View {
    let summary: UsageSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SummaryCard(title: "Focus Time", value: summary.focusTimeText, icon: "clock.arrow.circlepath")
                SummaryCard(title: "Saved Minutes", value: "\(summary.savedMinutes)", icon: "leaf")
                SummaryCard(title: "Streak", value: "\(summary.streakDays) days", icon: "flame")
                SummaryCard(title: "Check-ins", value: "\(summary.checkIns)", icon: "checkmark.circle")
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct DashboardHeader: View {
    let summary: UsageSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("You have stayed focused for")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(summary.focusTimeText)
                .font(.largeTitle.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct FocusCheckIn: View {
    @ObservedObject var screenTimeManager: ScreenTimeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Check-in")
                .font(.headline)
            Text("Log a focus moment when you resist doomscrolling.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("I stayed off distracting apps") {
                screenTimeManager.logFocusSession()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct RecentSessions: View {
    let sessions: [FocusSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
            ForEach(sessions.prefix(5)) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.note)
                            .font(.subheadline)
                        Text(session.date, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(session.minutes) min")
                        .font(.subheadline.weight(.semibold))
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct WeeklyStatsCard: View {
    let weekly: WeeklySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Week")
                .font(.headline)
            Text("\(weekly.totalMinutes) total minutes")
                .font(.title2.bold())
            Text("Average \(weekly.averageMinutes) minutes per day")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct WeeklyChart: View {
    let weekly: WeeklySummary

    var body: some View {
        let maxMinutes = max(weekly.dailyUsage.map(\.minutes).max() ?? 0, 1)
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Focus")
                .font(.headline)
            ForEach(weekly.dailyUsage) { day in
                HStack {
                    Text(day.label)
                        .frame(width: 36, alignment: .leading)
                    GeometryReader { proxy in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentColor)
                            .frame(width: proxy.size.width * (Double(day.minutes) / Double(maxMinutes)), height: 10)
                    }
                    .frame(height: 10)
                    Text("\(day.minutes)m")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 16)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct TopAppsCard: View {
    let weekly: WeeklySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Most distracting apps")
                .font(.headline)
            ForEach(weekly.topApps, id: \.self) { app in
                Text(app)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct UsageSummary {
    var todayMinutes: Int
    var savedMinutes: Int
    var streakDays: Int
    var checkIns: Int

    var focusTimeText: String {
        "\(todayMinutes) minutes"
    }

    static let sample = UsageSummary(todayMinutes: 42, savedMinutes: 120, streakDays: 4, checkIns: 3)
}

struct FocusSession: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
    let note: String

    static let sample: [FocusSession] = [
        FocusSession(date: Date().addingTimeInterval(-1200), minutes: 15, note: "Left Instagram closed"),
        FocusSession(date: Date().addingTimeInterval(-3600), minutes: 25, note: "Read a chapter instead"),
        FocusSession(date: Date().addingTimeInterval(-7200), minutes: 10, note: "Quick walk break")
    ]
}

struct DailyUsage: Identifiable {
    let id = UUID()
    let label: String
    var minutes: Int
}

struct WeeklySummary {
    var dailyUsage: [DailyUsage]
    var totalMinutes: Int
    var averageMinutes: Int
    var topApps: [String]

    mutating func apply(minutes: Int, for date: Date) {
        let label = Self.weekdayLabel(for: date)
        if let index = dailyUsage.firstIndex(where: { $0.label == label }) {
            dailyUsage[index].minutes += minutes
        }
        totalMinutes += minutes
        averageMinutes = totalMinutes / max(dailyUsage.count, 1)
    }

    static func weekdayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    static let sample: WeeklySummary = {
        let labels = Calendar.current.shortWeekdaySymbols
        let usage = labels.enumerated().map { index, label in
            DailyUsage(label: label, minutes: [32, 50, 40, 28, 62, 55, 44][index % 7])
        }
        let total = usage.map(\.minutes).reduce(0, +)
        let average = total / max(usage.count, 1)
        return WeeklySummary(
            dailyUsage: usage,
            totalMinutes: total,
            averageMinutes: average,
            topApps: ["Instagram", "TikTok", "X"]
        )
    }()
}
