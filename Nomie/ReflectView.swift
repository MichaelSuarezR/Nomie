//
//  ReflectView.swift
//  Nomie
//

import SwiftUI
import UIKit

private let reflectLandingMoodCardHeight: CGFloat = 228

enum ReflectLandingSection: String, CaseIterable, Identifiable {
    case dailyMood = "Daily Mood"
    case selfJournal = "Self-Journal"
    case patternsTrends = "Patterns & Trends"

    var id: String { rawValue }
}

struct ReflectView: View {
    @State private var loggedMoods: [ReflectDateKey: ReflectMoodOption] = [:]
    @State private var journalPrompt = ReflectJournalPrompt.randomPrompt()
    @State private var journalPromptResponse = ""
    @State private var selectedLandingSection: ReflectLandingSection = .dailyMood
    @State private var activeLandingSection: ReflectLandingSection?
    private let calendar = Calendar.current
    private let tabBarColor = Color(red: 0.97, green: 0.97, blue: 0.97)
    private let surfaceColor = Color(red: 0.985, green: 0.975, blue: 0.955)
    private let inkColor = Color(red: 0.12, green: 0.12, blue: 0.12)
    private let accentColor = Color(red: 0.15, green: 0.25, blue: 0.2)

    private var todayMood: ReflectMoodOption? {
        moodForDate(Date())
    }

    private var yesterdayMood: ReflectMoodOption? {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return nil }
        return moodForDate(yesterday)
    }

    private var moodStreakDays: Int {
        guard let latestLoggedDate = latestLoggedMoodDate else { return 0 }
        let today = calendar.startOfDay(for: Date())
        let daysSinceLatest = calendar.dateComponents([.day], from: latestLoggedDate, to: today).day ?? .max

        // Keep streak on the first unlogged day, then reset if another day passes.
        guard daysSinceLatest <= 1 else { return 0 }
        return streakEnding(on: latestLoggedDate)
    }

    private func yesterdayReflectionPrompt(for mood: ReflectMoodOption) -> String {
        let moodName = mood.name.lowercased()
        let emotionNoun = mood.reflectionEmotionNoun
        return """
        What made you \(moodName) yesterday? What are some ways you expressed and felt your \(emotionNoun)? How does this relate to your goals and productivity yesterday?
        """
    }

    private var latestLoggedMoodDate: Date? {
        loggedMoods.keys
            .compactMap { date(for: $0) }
            .max()
    }

    private func streakEnding(on endDate: Date) -> Int {
        var streak = 0
        var probeDate = calendar.startOfDay(for: endDate)

        while true {
            let key = ReflectDateKey(date: probeDate, calendar: calendar)
            guard loggedMoods[key] != nil else { break }
            streak += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: probeDate) else { break }
            probeDate = previousDate
        }

        return streak
    }

    private func date(for key: ReflectDateKey) -> Date? {
        var components = DateComponents()
        components.year = key.year
        components.month = key.month
        components.day = key.day
        return calendar.date(from: components).map { calendar.startOfDay(for: $0) }
    }

    private var journalDateLabel: String {
        ReflectJournalPrompt.dateLabel(Date())
    }

    private var journalPreviewText: String {
        let trimmed = journalPromptResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ReflectJournalPrompt.displayPrompt(journalPrompt)
        }

        if journalPrompt.contains("...") {
            return journalPrompt.replacingOccurrences(of: "...", with: trimmed)
        }
        if journalPrompt.contains("_____") {
            return journalPrompt.replacingOccurrences(of: "_____", with: trimmed)
        }
        return "\(journalPrompt) \(trimmed)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ReflectHeader()

                    ReflectLandingTabs(selectedSection: selectedLandingSection) { section in
                        selectedLandingSection = section
                        activeLandingSection = section
                    }

                    ReflectSectionTitle(text: "Daily Mood")
                    HStack(alignment: .top, spacing: 14) {
                        NavigationLink {
                            DailyMoodView(loggedMoods: $loggedMoods)
                        } label: {
                            ReflectTodayMoodCard(mood: todayMood)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)

                        ReflectStreakCard(days: moodStreakDays)
                            .frame(maxWidth: .infinity)
                    }

                    if let yesterdayMood {
                        HStack(alignment: .top, spacing: 14) {
                            VStack(alignment: .center, spacing: 10) {
                                Text("Reflect on yesterday:")
                                    .font(.custom("SortsMillGoudy-Italic", size: 22))
                                    .foregroundStyle(inkColor.opacity(0.92))
                                    .multilineTextAlignment(.center)

                                Text(yesterdayReflectionPrompt(for: yesterdayMood))
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundStyle(inkColor.opacity(0.88))
                                    .lineSpacing(2)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)

                            ReflectYesterdayMoodSummary(mood: yesterdayMood)
                                .frame(maxWidth: .infinity, alignment: .top)
                        }
                    }

                    ReflectSectionTitle(text: "Self-Journal")
                    NavigationLink {
                        SelfJournalView(
                            initialPrompt: journalPrompt,
                            onPromptChange: { journalPrompt = $0 },
                            onPromptResponseSave: { journalPromptResponse = $0 },
                            loggedMoods: $loggedMoods
                        )
                    } label: {
                        ReflectGradientCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Label("Today's prompt", systemImage: "sparkles")
                                        .font(.custom("AvenirNext-Medium", size: 13))
                                        .foregroundStyle(inkColor.opacity(0.65))
                                    Spacer()
                                    Text(journalDateLabel)
                                        .font(.custom("AvenirNext-Medium", size: 12))
                                        .foregroundStyle(inkColor.opacity(0.45))
                                }

                                Text(journalPreviewText)
                                    .font(.custom("Georgia", size: ReflectJournalPrompt.promptFontSize(for: journalPrompt)))
                                    .foregroundStyle(inkColor.opacity(0.9))
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)

                                HStack(spacing: 10) {
                                    Image(systemName: "book.closed")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Open journal")
                                        .font(.custom("AvenirNext-Medium", size: 13))
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 18)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    accentColor.opacity(0.16),
                                                    accentColor.opacity(0.34)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                                        .blendMode(.softLight)
                                )
                                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    ReflectSectionTitle(text: "Patterns & Trends")
                    NavigationLink {
                        PatternsTrendsView()
                    } label: {
                        ReflectPatternsGradientCard {
                            VStack(alignment: .leading, spacing: 12) {
                                TrendsScatterPlot(accentColor: accentColor, inkColor: inkColor)
                                    .frame(height: 128)

                                HStack {
                                    HStack(spacing: 8) {
                                        Image(systemName: "chart.xyaxis.line")
                                            .font(.system(size: 12, weight: .semibold))
                                        Text("See more")
                                            .font(.custom("AvenirNext-Medium", size: 13))
                                    }
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 18)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        accentColor.opacity(0.16),
                                                        accentColor.opacity(0.32)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.7), lineWidth: 1)
                                            .blendMode(.softLight)
                                    )
                                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 5)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .padding(.top, 8)
                .nomieTabBarContentPadding()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.94, green: 0.94, blue: 0.93),
                        surfaceColor,
                        tabBarColor
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationDestination(item: $activeLandingSection) { section in
                switch section {
                case .dailyMood:
                    DailyMoodView(loggedMoods: $loggedMoods)
                case .selfJournal:
                    SelfJournalView(
                        initialPrompt: journalPrompt,
                        onPromptChange: { journalPrompt = $0 },
                        onPromptResponseSave: { journalPromptResponse = $0 },
                        loggedMoods: $loggedMoods
                    )
                case .patternsTrends:
                    PatternsTrendsView()
                }
            }
        }
        .toolbarBackground(tabBarColor, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onAppear {
            if loggedMoods.isEmpty {
                loggedMoods = ReflectMoodStore.loadMoods()
            }
            let todayKey = ReflectDateKey(date: Date(), calendar: calendar)
            let entries = ReflectJournalStore.loadEntries()
            if let todayEntry = entries.first(where: { ReflectDateKey(date: $0.date, calendar: calendar) == todayKey }) {
                journalPrompt = todayEntry.prompt
                journalPromptResponse = todayEntry.promptResponse
            } else {
                journalPromptResponse = ""
            }
        }
        .onChange(of: loggedMoods) { _ in
            ReflectMoodStore.saveMoods(loggedMoods)
        }
    }
}

struct ReflectHeader: View {
    var body: some View {
        HStack(alignment: .top, spacing: -8) {
            Image("R")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 102)

            VStack(alignment: .leading, spacing: 6) {
                Image("eflect")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 56)

                Rectangle()
                    .fill(Color.black.opacity(0.35))
                    .frame(height: 1)
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReflectSectionTitle: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Text(text)
                .font(.custom("SortsMillGoudy-Regular", size: 24))
                .foregroundStyle(Color.black.opacity(0.88))
                .fixedSize()
            Rectangle()
                .fill(Color.black.opacity(0.35))
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReflectLandingTabs: View {
    let selectedSection: ReflectLandingSection
    let onSelect: (ReflectLandingSection) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(ReflectLandingSection.allCases) { section in
                Button {
                    onSelect(section)
                } label: {
                    ReflectLandingTabChip(
                        title: section.rawValue,
                        isSelected: selectedSection == section
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReflectLandingTabChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.custom("Poppins-Regular", size: 12))
            .foregroundStyle(Color.black.opacity(0.84))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.96) : Color.white.opacity(0.72))
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
    }
}

struct ReflectTodayMoodCard: View {
    let mood: ReflectMoodOption?

    var body: some View {
        VStack(spacing: 12) {
            Text("Today's Mood:")
                .font(.custom("SortsMillGoudy-Italic", size: 20))
                .foregroundStyle(Color.black.opacity(0.85))

            if let mood {
                MoodAssetImage(
                    assetName: mood.assetName,
                    intensity: 0.85
                )
                .frame(width: 102, height: 102)
            } else {
                Circle()
                    .stroke(
                        Color.black.opacity(0.65),
                        style: StrokeStyle(lineWidth: 1.2, dash: [4, 4])
                    )
                    .frame(width: 102, height: 102)
            }

            Text("Daily Mood")
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundStyle(Color.black.opacity(0.82))
                .padding(.vertical, 7)
                .padding(.horizontal, 20)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.12), radius: 5, x: 0, y: 3)
                )
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .frame(
            maxWidth: .infinity,
            minHeight: reflectLandingMoodCardHeight,
            maxHeight: reflectLandingMoodCardHeight,
            alignment: .top
        )
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.93, green: 0.9, blue: 0.58),
                            Color(red: 0.97, green: 0.6, blue: 0.71),
                            Color(red: 0.95, green: 0.86, blue: 0.63)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
    }
}

struct ReflectStreakCard: View {
    let days: Int

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image("Streak")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 18)

                Text("Streak")
                    .font(.custom("SortsMillGoudy-Regular", size: 32))
                    .foregroundStyle(Color.black.opacity(0.9))
            }

            Text("\(days)")
                .font(.custom("BricolageGrotesque-96ptExtraBold_Regular", size: 62))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.97, green: 0.63, blue: 0.35),
                            Color(red: 0.88, green: 0.68, blue: 0.31)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("Days")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundStyle(Color.black.opacity(0.9))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .frame(
            maxWidth: .infinity,
            minHeight: reflectLandingMoodCardHeight,
            maxHeight: reflectLandingMoodCardHeight,
            alignment: .top
        )
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

}

struct ReflectYesterdayMoodSummary: View {
    let mood: ReflectMoodOption

    var body: some View {
        VStack(spacing: 8) {
            Text("Yesterday's mood:")
                .font(.custom("SortsMillGoudy-Italic", size: 20))
                .foregroundStyle(Color.black.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .center)

            MoodAssetImage(assetName: mood.assetName, intensity: 0.85)
                .frame(width: 122, height: 122)

            Text(mood.name)
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundStyle(Color.black.opacity(0.88))
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

struct ReflectHero: View {
    let title: String
    let subtitle: String
    let accentColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.custom("Georgia", size: 26))
                    .foregroundStyle(Color.black.opacity(0.88))
                Text(subtitle)
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(Color.black.opacity(0.6))
            }
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.12),
                                accentColor.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 68)
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(accentColor.opacity(0.9))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

struct ReflectCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.14), lineWidth: 1)
            )
    }
}

struct ReflectGradientCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.92, blue: 0.74),
                                    Color(red: 0.94, green: 0.84, blue: 0.56)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.45, blue: 0.57).opacity(0.45),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 170
                            )
                        )

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.74, green: 0.9, blue: 0.88).opacity(0.45),
                                    .clear
                                ],
                                center: .trailing,
                                startRadius: 8,
                                endRadius: 180
                            )
                        )
                }
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.14), lineWidth: 1)
            )
    }
}

struct ReflectTodayGradientCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.93, green: 0.9, blue: 0.58),
                                Color(red: 0.97, green: 0.6, blue: 0.71),
                                Color(red: 0.95, green: 0.86, blue: 0.63)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            )
    }
}

struct ReflectPatternsGradientCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.82, green: 0.93, blue: 0.9),
                                    Color(red: 0.92, green: 0.83, blue: 0.66)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.76, green: 0.88, blue: 0.62).opacity(0.6),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 185
                            )
                        )

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.96, green: 0.81, blue: 0.58).opacity(0.34),
                                    .clear
                                ],
                                center: .topTrailing,
                                startRadius: 6,
                                endRadius: 170
                            )
                        )
                }
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.14), lineWidth: 1)
            )
    }
}

struct ReflectSoftCard<Content: View>: View {
    let content: Content
    private let fixedHeight: CGFloat = 210

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: fixedHeight, maxHeight: fixedHeight, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            .blendMode(.softLight)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 8)
            )
    }
}

struct ReflectMoodCard: View {
    let title: String
    let mood: ReflectMoodOption?
    let isActionable: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.custom("AvenirNext-Medium", size: 13))
                .foregroundStyle(Color.black.opacity(0.7))

            if let mood {
                MoodAssetImage(
                    assetName: mood.assetName,
                    intensity: 0.75,
                    contentMode: .fit
                )
                .frame(width: 84, height: 84)
                .scaleEffect(1.15)
                Text(mood.name)
                    .font(.custom("AvenirNext-Medium", size: 13))
                    .foregroundStyle(Color.black.opacity(0.8))
            } else if isActionable {
                Circle()
                    .stroke(
                        Color.black.opacity(0.7),
                        style: StrokeStyle(lineWidth: 1.2, dash: [4, 4])
                    )
                    .frame(width: 84, height: 84)

                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)
                        Image(systemName: "plus")
                            .foregroundStyle(Color.black.opacity(0.7))
                    }

                    Text("Log Mood")
                        .font(.custom("AvenirNext-Medium", size: 12))
                        .foregroundStyle(Color.black.opacity(0.7))
                }
                .frame(height: 54)
            } else {
                Circle()
                    .fill(Color.black.opacity(0.12))
                    .frame(width: 84, height: 84)
                Text("No entry")
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .foregroundStyle(Color.black.opacity(0.6))
                    .frame(height: 54)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct DailyMoodView: View {
    @Binding var loggedMoods: [ReflectDateKey: ReflectMoodOption]
    @State private var selectedMoodIndex: Int? = nil
    @State private var moodLevels: [MoodLevelState] = [
        .init(label: "stress", value: 0.5),
        .init(label: "fun", value: 0.5),
        .init(label: "laziness", value: 0.25),
        .init(label: "inspired", value: 0.75)
    ]
    @State private var currentMonth = Date()
    private let calendar = Calendar.current
    private let sectionTitleFontSize: CGFloat = 20
    @Environment(\.dismiss) private var dismiss
    private var todayKey: ReflectDateKey {
        ReflectDateKey(date: Date(), calendar: calendar)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Daily Mood")
                    .font(.custom("SortsMillGoudy-Regular", size: 28))
                    .foregroundStyle(Color.black.opacity(0.92))

                Rectangle()
                    .fill(Color.black.opacity(0.7))
                    .frame(height: 1)
                    .padding(.horizontal, 6)

                Text("How was your overall mood today?")
                    .font(.custom("SortsMillGoudy-Italic", size: 17))
                    .foregroundStyle(Color.black.opacity(0.95))
                    .multilineTextAlignment(.center)

                MoodOrbitPicker(
                    selectedMoodIndex: $selectedMoodIndex,
                    onSelect: { index in
                        guard ReflectMoodOption.moods.indices.contains(index) else { return }
                        let mood = ReflectMoodOption.moods[index]
                        logMood(mood)
                    }
                )
                    .frame(height: 280)
                    .onAppear {
                        if let todayMood = moodForDate(Date()),
                           let index = ReflectMoodOption.moods.firstIndex(of: todayMood) {
                            selectedMoodIndex = index
                        } else {
                            selectedMoodIndex = nil
                        }
                    }

                ReflectGradientCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Past 7 days")
                            .font(.custom("SortsMillGoudy-Regular", size: sectionTitleFontSize))
                            .foregroundStyle(Color.black.opacity(0.7))
                        HStack(spacing: 10) {
                            ForEach(last7Days()) { day in
                                VStack(spacing: 6) {
                                    if let mood = day.mood {
                                        MoodAssetImage(assetName: mood.assetName, intensity: 0.7)
                                            .frame(width: 34, height: 34)
                                    } else {
                                        Circle()
                                            .stroke(
                                                Color.black.opacity(0.7),
                                                style: StrokeStyle(lineWidth: 1.2, dash: [3, 3])
                                            )
                                            .frame(width: 34, height: 34)
                                    }
                                    Text(day.dayLabel)
                                        .font(.custom("Poppins-Regular", size: 10))
                                    Text(day.dateLabel)
                                        .font(.custom("Poppins-Regular", size: 10))
                                        .foregroundStyle(Color.black.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }

                ReflectTodayGradientCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mood Levels")
                            .font(.custom("SortsMillGoudy-Regular", size: sectionTitleFontSize))
                            .foregroundStyle(Color.black.opacity(0.8))

                        Rectangle()
                            .fill(Color.black.opacity(0.25))
                            .frame(height: 1)

                        Text("How much did you experience each of these moods today?")
                            .font(.custom("SortsMillGoudy-Italic", size: 18))
                            .foregroundStyle(Color.black.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 6)

                        if let selectedMoodIndex, ReflectMoodOption.moods.indices.contains(selectedMoodIndex) {
                            ForEach($moodLevels) { $level in
                                MoodLevelRow(level: $level)
                            }
                        } else {
                            Text("Select a mood to personalize your levels.")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundStyle(Color.black.opacity(0.55))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 12)
                        }
                    }
                }

                ReflectTodayGradientCard {
                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            Button {
                                currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(width: 34, height: 34)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.9))
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                    )
                            }

                            Spacer(minLength: 6)
                            Text(monthTitle(currentMonth))
                                .font(.custom("SortsMillGoudy-Italic", size: 24))
                                .foregroundStyle(Color(red: 0.18, green: 0.08, blue: 0.08))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 22)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.white.opacity(0.95))
                                        .shadow(color: Color.black.opacity(0.14), radius: 10, x: 0, y: 6)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                                )
                            Spacer(minLength: 6)

                            Button {
                                currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(width: 34, height: 34)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.9))
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                    )
                            }
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.75))

                        HStack {
                            ForEach(["Su", "M", "Tu", "W", "Th", "F", "S"], id: \.self) { day in
                                Text(day)
                                    .font(.custom("Poppins-Regular", size: 11))
                                    .foregroundStyle(Color.black.opacity(0.85))
                                    .tracking(0.6)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.bottom, 2)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                            let gridDays = monthGridDays(for: currentMonth)
                            ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                                if day == 0 {
                                    Color.clear.frame(height: 32)
                                } else {
                                    VStack(spacing: 6) {
                                        if let mood = moodForDay(day, in: currentMonth) {
                                            MoodAssetImage(
                                                assetName: mood.assetName,
                                                intensity: 0.7
                                            )
                                            .frame(width: 26, height: 26)
                                        } else {
                                            Color.clear.frame(width: 26, height: 26)
                                        }
                                        Text("\(day)")
                                            .font(.custom("Poppins-Regular", size: 10))
                                            .foregroundStyle(Color.black.opacity(moodForDay(day, in: currentMonth) == nil ? 0.3 : 0.75))
                                    }
                                }
                            }
                        }
                    }
                }

                if !mostExperiencedMoods.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            Text("Most experienced moods")
                                .font(.custom("SortsMillGoudy-Regular", size: sectionTitleFontSize))
                                .foregroundStyle(Color.black.opacity(0.86))
                                .fixedSize(horizontal: true, vertical: false)
                                .layoutPriority(1)

                            MostExperiencedSectionRule()
                        }

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 14),
                                GridItem(.flexible(), spacing: 14)
                            ],
                            spacing: 14
                        ) {
                            ForEach(mostExperiencedMoods) { item in
                                MostExperiencedMoodCard(item: item)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .nomieTabBarContentPadding()
        }
        .background(Color(red: 0.97, green: 0.97, blue: 0.97))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onAppear {
            moodLevels = ReflectMoodLevelStore.loadLevels(for: todayKey, defaults: moodLevels)
        }
        .onChange(of: moodLevels) { _ in
            ReflectMoodLevelStore.saveLevels(moodLevels, for: todayKey)
        }
    }

    private func logMood(_ mood: ReflectMoodOption) {
        let key = ReflectDateKey(date: Date(), calendar: calendar)
        loggedMoods[key] = mood
    }

    private func last7Days() -> [ReflectMoodDayDisplay] {
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "M.d"
        let weekdayLabels = ["SU", "M", "TU", "W", "TH", "F", "S"]

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -6 + offset, to: today) else { return nil }
            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            let key = ReflectDateKey(date: date, calendar: calendar)
            let mood = loggedMoods[key]
            return ReflectMoodDayDisplay(
                dayLabel: weekdayLabels[weekdayIndex],
                dateLabel: formatter.string(from: date),
                mood: mood
            )
        }
    }
}

private struct MostExperiencedSectionRule: View {
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.32))
            .frame(height: 0.7)
            .frame(maxWidth: .infinity)
    }
}

struct MoodAssetImage: View {
    let assetName: String
    let intensity: Double
    let contentMode: ContentMode

    init(assetName: String, intensity: Double, contentMode: ContentMode = .fit) {
        self.assetName = assetName
        self.intensity = intensity
        self.contentMode = contentMode
    }

    var body: some View {
        Image(assetName)
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .saturation(0.6 + (0.4 * intensity))
            .opacity(0.4 + (0.6 * intensity))
            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 4)
    }
}

struct MoodSelectorPreview: View {
    let mood: ReflectMoodOption
    let size: CGFloat
    let isSelected: Bool
    let showLabel: Bool

    init(
        mood: ReflectMoodOption,
        size: CGFloat,
        isSelected: Bool,
        showLabel: Bool = true
    ) {
        self.mood = mood
        self.size = size
        self.isSelected = isSelected
        self.showLabel = showLabel
    }

    var body: some View {
        VStack(spacing: 6) {
            MoodAssetImage(assetName: mood.assetName, intensity: 0.7)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.black.opacity(0.6) : Color.clear, lineWidth: 1)
                )
            if showLabel {
                Text(mood.name)
                    .font(.custom("AvenirNext-Regular", size: isSelected ? 13 : 11))
                    .foregroundStyle(Color.black.opacity(isSelected ? 0.75 : 0.6))
            }
        }
    }
}

struct MoodOrbitPicker: View {
    @Binding var selectedMoodIndex: Int?
    let onSelect: (Int) -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let positions = moodPositions(in: size, count: ReflectMoodOption.moods.count)
            let selectedMood = selectedMoodIndex.flatMap { index in
                ReflectMoodOption.moods.indices.contains(index) ? ReflectMoodOption.moods[index] : nil
            }

            ZStack {
                if let selectedMood {
                    VStack(spacing: 8) {
                        MoodAssetImage(assetName: selectedMood.assetName, intensity: 0.85)
                            .frame(width: 130, height: 130)
                        Text(selectedMood.name)
                            .font(.custom("SortsMillGoudy-Regular", size: 22))
                            .foregroundStyle(Color.black.opacity(0.8))
                    }
                    .position(x: center.x, y: center.y)
                } else {
                    VStack(spacing: 10) {
                        Circle()
                            .stroke(
                                Color.black.opacity(0.25),
                                style: StrokeStyle(lineWidth: 1.5, dash: [5, 5])
                            )
                            .frame(width: 130, height: 130)
                        Text("Select a mood")
                            .font(.custom("SortsMillGoudy-Italic", size: 16))
                            .foregroundStyle(Color.black.opacity(0.6))
                    }
                    .position(x: center.x, y: center.y)
                }

                ForEach(ReflectMoodOption.moods.indices, id: \.self) { idx in
                    let mood = ReflectMoodOption.moods[idx]
                    let offset = positions[idx % positions.count]
                    Button {
                        selectedMoodIndex = idx
                        onSelect(idx)
                    } label: {
                        MoodSelectorPreview(
                            mood: mood,
                            size: 60,
                            isSelected: idx == selectedMoodIndex,
                            showLabel: false
                        )
                        .frame(width: 72, height: 72)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .position(x: center.x + offset.x, y: center.y + offset.y)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func moodPositions(in size: CGSize, count: Int) -> [CGPoint] {
        let radius = min(size.width, size.height) * 0.42
        let step = 2 * Double.pi / Double(max(count, 1))
        let start = -Double.pi / 2
        return (0..<count).map { index in
            let angle = start + (Double(index) * step)
            return CGPoint(x: CGFloat(cos(angle)) * radius,
                           y: CGFloat(sin(angle)) * radius)
        }
    }
}



struct PatternsTrendsView: View {
    private let surfaceColor = Color(red: 0.985, green: 0.975, blue: 0.955)
    private let inkColor = Color(red: 0.13, green: 0.13, blue: 0.13)
    private let accentColor = Color(red: 0.16, green: 0.3, blue: 0.22)
    private let calendar = Calendar.current
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRange: TrendsRange = .past7Days
    @State private var journalEntries: [ReflectJournalEntry] = []
    @State private var isGradientBoosted = false

    private enum TrendsRange: String, CaseIterable, Identifiable {
        case today = "Today"
        case past7Days = "Past 7 days"
        case past30Days = "Past 30 days"

        var id: String { rawValue }
    }

    private struct AnalyticsExcerpt: Identifiable {
        let id: UUID
        let text: String
        let weekday: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(spacing: 10) {
                    Text("Patterns & Trends")
                        .font(.custom("SortsMillGoudy-Regular", size: 28))
                        .foregroundStyle(Color.black.opacity(0.92))

                    Rectangle()
                        .fill(Color.black.opacity(0.7))
                        .frame(height: 1)
                        .padding(.horizontal, 6)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)

                TrendsMoodAnalyticsCard(isGradientBoosted: isGradientBoosted) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Spacer()
                                Button {
                                    selectedRange = nextRange(after: selectedRange)
                                } label: {
                                    Text(selectedRange.rawValue)
                                        .font(.custom("AvenirNext-Regular", size: 11))
                                        .foregroundStyle(inkColor.opacity(0.7))
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 10)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.6))
                                        )
                                }
                                .buttonStyle(.plain)
                            }

                            HStack(spacing: 10) {
                                Text("Mood vs. app usage")
                                    .font(.custom("SortsMillGoudy-Regular", size: 20))
                                    .foregroundStyle(inkColor.opacity(0.95))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)

                                Rectangle()
                                    .fill(Color.black.opacity(0.68))
                                    .frame(height: 1)
                            }
                        }

                        HStack(alignment: .center, spacing: 8) {
                            Text("inspiration level")
                                .font(.custom("AvenirNext-Regular", size: 13))
                                .foregroundStyle(inkColor.opacity(0.9))
                                .rotationEffect(.degrees(-90))
                                .fixedSize()
                                .frame(width: 12)

                            VStack(spacing: 8) {
                                TrendsScatterPlot(
                                    accentColor: accentColor,
                                    inkColor: inkColor,
                                    onPlotTap: {
                                        withAnimation(.easeInOut(duration: 0.24)) {
                                            isGradientBoosted.toggle()
                                        }
                                    }
                                )
                                .frame(height: 320)

                                Text("productivity app usage")
                                    .font(.custom("AvenirNext-Medium", size: 13))
                                    .foregroundStyle(inkColor.opacity(0.9))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(inkColor.opacity(0.85))
                                Text("Analytics")
                                    .font(.custom("SortsMillGoudy-Italic", size: 22))
                                    .foregroundStyle(inkColor.opacity(0.95))
                            }

                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.custom("AvenirNext-Medium", size: 17))
                                    .foregroundStyle(inkColor.opacity(0.85))
                                Text(analyticsSummaryLine)
                                    .font(.custom("AvenirNext-Regular", size: 14))
                                    .foregroundStyle(inkColor.opacity(0.86))
                            }

                            if analyticsExcerpts.isEmpty {
                                Text(emptyAnalyticsText)
                                    .font(.custom("AvenirNext-Regular", size: 14))
                                    .foregroundStyle(inkColor.opacity(0.62))
                                    .padding(.top, 2)
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(analyticsExcerpts) { excerpt in
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\"\(excerpt.text)\"")
                                                .font(.custom("AvenirNext-Regular", size: 15))
                                                .foregroundStyle(inkColor.opacity(0.9))
                                            Text("- \(excerpt.weekday)")
                                                .font(.custom("AvenirNext-Regular", size: 13))
                                                .foregroundStyle(inkColor.opacity(0.68))
                                                .padding(.leading, 8)
                                        }
                                    }
                                }
                                .padding(.top, 2)
                            }
                        }
                    }
                }

                TrendsSurfaceCard {
                    VStack(spacing: 12) {
                        Text("Insights")
                            .font(.custom("SortsMillGoudy-Italic", size: 22))
                            .foregroundStyle(inkColor.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .center)

                        Rectangle()
                            .fill(Color.black.opacity(0.6))
                            .frame(height: 1)

                        Text("On days when Escape apps were over 2 hours,\nyour stress levels were higher.")
                            .font(.custom("SortsMillGoudy-Regular", size: 14))
                            .foregroundStyle(inkColor.opacity(0.86))
                            .multilineTextAlignment(.center)
                            .lineSpacing(1)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 2)
                }

                ReflectPatternsGradientCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Text("Suggestions")
                                .font(.custom("SortsMillGoudy-Regular", size: 20))
                                .foregroundStyle(inkColor.opacity(0.95))

                            Rectangle()
                                .fill(Color.black.opacity(0.58))
                                .frame(height: 1)
                        }

                        Text("Attempt to take intermittent breaks from\nDrifting apps in order to increase productivity\non a daily basis!")
                            .font(.custom("AvenirNext-Medium", size: 14))
                            .foregroundStyle(inkColor.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .nomieTabBarContentPadding()
        }
        .background(
            LinearGradient(
                colors: [surfaceColor, Color(red: 0.98, green: 0.98, blue: 0.965)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onAppear {
            journalEntries = normalizeEntries(ReflectJournalStore.loadEntries())
        }
    }

    private func nextRange(after range: TrendsRange) -> TrendsRange {
        let all = TrendsRange.allCases
        guard let index = all.firstIndex(of: range) else { return .past7Days }
        let nextIndex = all.index(after: index)
        return nextIndex == all.endIndex ? all[all.startIndex] : all[nextIndex]
    }

    private var analyticsSummaryLine: String {
        switch selectedRange {
        case .today:
            return "Today pulls one excerpt from your journal entry."
        case .past7Days:
            return "Past 7 days surfaces meaningful excerpts from entries in the last week."
        case .past30Days:
            return "Past 30 days surfaces meaningful excerpts from entries in the last month."
        }
    }

    private var emptyAnalyticsText: String {
        switch selectedRange {
        case .today:
            return "No journal entry for today yet."
        case .past7Days:
            return "No journal entries found in the past 7 days."
        case .past30Days:
            return "No journal entries found in the past 30 days."
        }
    }

    private var analyticsExcerpts: [AnalyticsExcerpt] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return filteredEntries.prefix(excerptLimit).map { entry in
            AnalyticsExcerpt(
                id: entry.id,
                text: meaningfulExcerpt(from: entry),
                weekday: formatter.string(from: entry.date)
            )
        }
    }

    private var excerptLimit: Int {
        switch selectedRange {
        case .today:
            return 1
        case .past7Days:
            return 3
        case .past30Days:
            return 5
        }
    }

    private var filteredEntries: [ReflectJournalEntry] {
        let today = calendar.startOfDay(for: Date())
        let contentEntries = journalEntries.filter(hasJournalContent)
        switch selectedRange {
        case .today:
            return contentEntries.filter { calendar.isDate($0.date, inSameDayAs: today) }
        case .past7Days:
            guard let start = calendar.date(byAdding: .day, value: -6, to: today) else { return [] }
            return contentEntries.filter { entry in
                let day = calendar.startOfDay(for: entry.date)
                return day >= start && day <= today
            }
        case .past30Days:
            guard let start = calendar.date(byAdding: .day, value: -29, to: today) else { return [] }
            return contentEntries.filter { entry in
                let day = calendar.startOfDay(for: entry.date)
                return day >= start && day <= today
            }
        }
    }

    private func normalizeEntries(_ entries: [ReflectJournalEntry]) -> [ReflectJournalEntry] {
        var buckets: [ReflectDateKey: ReflectJournalEntry] = [:]
        for entry in entries.sorted(by: { $0.date > $1.date }) {
            let key = ReflectDateKey(date: entry.date, calendar: calendar)
            if buckets[key] == nil {
                buckets[key] = entry
            }
        }
        return buckets.values.sorted(by: { $0.date > $1.date })
    }

    private func meaningfulExcerpt(from entry: ReflectJournalEntry) -> String {
        let journal = entry.journalText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !journal.isEmpty {
            return shortenExcerpt(journal)
        }

        let response = entry.promptResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if !response.isEmpty {
            return shortenExcerpt(filledPromptString(entry.prompt, with: response))
        }

        return shortenExcerpt(ReflectJournalPrompt.displayPrompt(entry.prompt))
    }

    private func hasJournalContent(_ entry: ReflectJournalEntry) -> Bool {
        let journal = entry.journalText.trimmingCharacters(in: .whitespacesAndNewlines)
        let response = entry.promptResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        return !journal.isEmpty || !response.isEmpty
    }

    private func filledPromptString(_ prompt: String, with entry: String) -> String {
        let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ReflectJournalPrompt.displayPrompt(prompt) }

        if prompt.contains("...") {
            return prompt.replacingOccurrences(of: "...", with: trimmed)
        }
        if prompt.contains("_____") {
            return prompt.replacingOccurrences(of: "_____", with: trimmed)
        }
        return "\(prompt) \(trimmed)"
    }

    private func shortenExcerpt(_ text: String, maxLength: Int = 110) -> String {
        let condensed = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard condensed.count > maxLength else { return condensed }
        let prefix = condensed.prefix(max(0, maxLength - 1))
        return "\(prefix)…"
    }
}

struct TrendsHeroPill: View {
    let title: String
    let subtitle: String
    let accentColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.custom("Georgia", size: 22))
                    .foregroundStyle(Color.black.opacity(0.86))
                Text(subtitle)
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundStyle(Color.black.opacity(0.6))
            }
            Spacer()
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.16), accentColor.opacity(0.32)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(accentColor.opacity(0.8))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

struct TrendsSectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom("Georgia", size: 20))
            .foregroundStyle(Color.black.opacity(0.82))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TrendsSurfaceCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
    }
}

struct TrendsMoodAnalyticsCard<Content: View>: View {
    let isGradientBoosted: Bool
    let content: Content

    init(isGradientBoosted: Bool, @ViewBuilder content: () -> Content) {
        self.isGradientBoosted = isGradientBoosted
        self.content = content()
    }

    var body: some View {
        let boost = isGradientBoosted ? 1.0 : 0.0
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.93, green: 0.9, blue: 0.58),
                                    Color(red: 0.97, green: 0.6, blue: 0.71),
                                    Color(red: 0.95, green: 0.86, blue: 0.63)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.93, green: 0.9, blue: 0.58).opacity(0.18 * boost),
                                    Color(red: 0.97, green: 0.6, blue: 0.71).opacity(0.28 * boost),
                                    Color(red: 0.95, green: 0.86, blue: 0.63).opacity(0.18 * boost)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
    }
}

struct TrendsScatterPlot: View {
    let accentColor: Color
    let inkColor: Color
    var onPlotTap: (() -> Void)? = nil

    private let points: [CGPoint] = [
        CGPoint(x: 0.15, y: 0.78),
        CGPoint(x: 0.22, y: 0.5),
        CGPoint(x: 0.3, y: 0.62),
        CGPoint(x: 0.45, y: 0.35),
        CGPoint(x: 0.55, y: 0.58),
        CGPoint(x: 0.7, y: 0.28),
        CGPoint(x: 0.8, y: 0.45),
        CGPoint(x: 0.9, y: 0.2)
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 6)

                Path { path in
                    let stepX = size.width / 4
                    let stepY = size.height / 4
                    for index in 1..<4 {
                        let x = CGFloat(index) * stepX
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    for index in 1..<4 {
                        let y = CGFloat(index) * stepY
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                }
                .stroke(inkColor.opacity(0.08), lineWidth: 1)

                ForEach(points.indices, id: \.self) { idx in
                    let point = points[idx]
                    Circle()
                        .fill(accentColor.opacity(0.7))
                        .frame(width: 10, height: 10)
                        .position(
                            x: point.x * size.width,
                            y: point.y * size.height
                        )
                }

                if let onPlotTap {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.clear)
                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .onTapGesture {
                            onPlotTap()
                        }
                }
            }
        }
    }
}

struct TrendsMetricBadge: View {
    let label: String
    let value: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom("AvenirNext-Regular", size: 11))
                .foregroundStyle(Color.black.opacity(0.55))
            Text(value)
                .font(.custom("AvenirNext-Medium", size: 13))
                .foregroundStyle(Color.black.opacity(0.8))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(accentColor.opacity(0.12))
        )
    }
}

struct TrendsInsightRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accentColor: Color
    let inkColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.18))
                    .frame(width: 30, height: 30)
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accentColor.opacity(0.8))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("AvenirNext-Medium", size: 13))
                    .foregroundStyle(inkColor.opacity(0.85))
                Text(subtitle)
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(inkColor.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SelfJournalView: View {
    @State private var promptResponse = ""
    @State private var prompt: String
    @State private var journalEntries: [ReflectJournalEntry] = []
    @State private var entryTags: [UUID: Set<JournalTag>] = [:]
    @State private var placedStamps: [ReflectPlacedStamp] = []
    @State private var earnedStamps: [ReflectStampDefinition] = []
    @State private var selectedEntryID: UUID? = nil
    @FocusState private var isEntryFocused: Bool
    private let today = Date()
    private let calendar = Calendar.current
    private let entryHint = "Keep it short"
    private let tabBarColor = Color(red: 0.97, green: 0.97, blue: 0.97)
    private let surfaceColor = Color(red: 0.985, green: 0.975, blue: 0.95)
    private let inkColor = Color(red: 0.14, green: 0.14, blue: 0.14)
    private let accentColor = Color(red: 0.16, green: 0.3, blue: 0.22)
    private let onPromptChange: (String) -> Void
    private let onPromptResponseSave: (String) -> Void
    @Binding private var loggedMoods: [ReflectDateKey: ReflectMoodOption]
    @Environment(\.dismiss) private var dismiss

    init(
        initialPrompt: String,
        onPromptChange: @escaping (String) -> Void,
        onPromptResponseSave: @escaping (String) -> Void,
        loggedMoods: Binding<[ReflectDateKey: ReflectMoodOption]>
    ) {
        _prompt = State(initialValue: initialPrompt)
        self.onPromptChange = onPromptChange
        self.onPromptResponseSave = onPromptResponseSave
        _loggedMoods = loggedMoods
    }

    private var wordCount: Int {
        promptResponse.split { $0 == " " || $0 == "\n" || $0 == "\t" }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Text("Self-Journal")
                        .font(.custom("SortsMillGoudy-Regular", size: 28))
                        .foregroundStyle(Color.black.opacity(0.92))

                    Rectangle()
                        .fill(Color.black.opacity(0.7))
                        .frame(height: 1)
                        .padding(.horizontal, 6)

                    Text("Today • \(ReflectJournalPrompt.dateLabel(today))")
                        .font(.custom("AvenirNext-Medium", size: 11))
                        .foregroundStyle(inkColor.opacity(0.55))
                }
                .frame(maxWidth: .infinity)

                ReflectGradientCard {
                    VStack(spacing: 12) {
                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today's prompt")
                                    .font(.custom("AvenirNext-Medium", size: 11))
                                    .foregroundStyle(inkColor.opacity(0.55))
                                Text(promptPreviewText)
                                    .font(.custom("Georgia", size: max(14, ReflectJournalPrompt.promptFontSize(for: prompt) - 8)))
                                    .foregroundStyle(inkColor.opacity(0.88))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 8)
                            Button {
                                let newPrompt = ReflectJournalPrompt.randomPrompt()
                                prompt = newPrompt
                                onPromptChange(newPrompt)
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(inkColor.opacity(0.75))
                                    .frame(width: 30, height: 30)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.06))
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $promptResponse)
                                .font(.custom("AvenirNext-Regular", size: 13))
                                .foregroundStyle(inkColor.opacity(0.86))
                                .padding(.horizontal, 8)
                                .padding(.top, 8)
                                .frame(minHeight: 92, maxHeight: 118)
                                .scrollContentBackground(.hidden)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(0.96))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(
                                                    isEntryFocused ? accentColor.opacity(0.35) : Color.black.opacity(0.08),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                                .focused($isEntryFocused)

                            if promptResponse.isEmpty {
                                Text("Start writing...")
                                    .font(.custom("AvenirNext-Regular", size: 13))
                                    .foregroundStyle(inkColor.opacity(0.35))
                                    .padding(.horizontal, 14)
                                    .padding(.top, 14)
                            }
                        }

                        HStack {
                            Text(entryHint)
                                .font(.custom("AvenirNext-Regular", size: 11))
                                .foregroundStyle(inkColor.opacity(0.48))
                            Spacer()
                            Text("\(wordCount) words")
                                .font(.custom("AvenirNext-Medium", size: 10))
                                .foregroundStyle(inkColor.opacity(0.45))
                        }

                        if let todayEntryID = todayEntryID {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tags")
                                    .font(.custom("AvenirNext-Medium", size: 11))
                                    .foregroundStyle(inkColor.opacity(0.58))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(JournalTag.allCases) { tag in
                                            let isSelected = entryTags[todayEntryID, default: []].contains(tag)
                                            Button {
                                                toggleTag(tag, for: todayEntryID)
                                            } label: {
                                                Text(tag.title)
                                                    .font(.custom("AvenirNext-Medium", size: 11))
                                                    .foregroundStyle(isSelected ? Color.black.opacity(0.9) : Color.black.opacity(0.65))
                                                    .padding(.vertical, 5)
                                                    .padding(.horizontal, 10)
                                                    .background(
                                                        Capsule()
                                                            .fill(isSelected ? tag.color.opacity(0.28) : Color.black.opacity(0.06))
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 2)
                                }
                            }
                        }

                        HStack(spacing: 8) {
                            Button {
                                promptResponse = ""
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark")
                                    Text("Clear")
                                }
                                .font(.custom("AvenirNext-Medium", size: 11))
                                .foregroundStyle(inkColor.opacity(0.72))
                                .padding(.vertical, 7)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.06))
                                )
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button {
                                let trimmed = promptResponse.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                upsertEntryForToday(promptResponse: trimmed)
                                onPromptResponseSave(trimmed)
                                promptResponse = ""
                                isEntryFocused = false
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark")
                                    Text("Done")
                                }
                                .font(.custom("AvenirNext-Medium", size: 11))
                                .foregroundStyle(inkColor.opacity(0.88))
                                .padding(.vertical, 7)
                                .padding(.horizontal, 14)
                                .background(
                                    Capsule()
                                        .fill(accentColor.opacity(0.2))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                ReflectJournalSurfaceCard {
                    VStack(alignment: .center, spacing: 14) {
                        Text("Take time to reflect")
                            .font(.custom("SortsMillGoudy-Italic", size: 18))
                            .foregroundStyle(inkColor.opacity(0.84))
                            .multilineTextAlignment(.center)

                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .frame(height: 1)

                        Text("How did you consciously move toward achieving your goals? Unconsciously? What are some ways you were more productive this week than last week?")
                            .font(.custom("AvenirNext-Regular", size: 14))
                            .foregroundStyle(inkColor.opacity(0.82))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                }

                ReflectJournalCoverSection(
                    entries: $journalEntries,
                    entryTags: $entryTags,
                    placedStamps: $placedStamps,
                    loggedMoods: $loggedMoods,
                    selectedEntryID: $selectedEntryID
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .nomieTabBarContentPadding()
        }
        .background(
            LinearGradient(
                colors: [surfaceColor, Color(red: 0.98, green: 0.98, blue: 0.965), tabBarColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .toolbarBackground(tabBarColor, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onAppear {
            if journalEntries.isEmpty {
                journalEntries = normalizeEntries(ReflectJournalStore.loadEntries())
            }
            if entryTags.isEmpty {
                entryTags = ReflectJournalTagStore.loadTags()
            }
            let todayKey = ReflectDateKey(date: today, calendar: calendar)
            if let todayEntry = journalEntries.first(where: { ReflectDateKey(date: $0.date, calendar: calendar) == todayKey }) {
                promptResponse = ""
                prompt = todayEntry.prompt
                onPromptChange(todayEntry.prompt)
                onPromptResponseSave(todayEntry.promptResponse)
                selectedEntryID = todayEntry.id
            } else {
                let newEntry = ReflectJournalEntry(
                    date: today,
                    prompt: prompt,
                    promptResponse: "",
                    journalText: ""
                )
                journalEntries.insert(newEntry, at: 0)
                onPromptResponseSave("")
                selectedEntryID = newEntry.id
            }
        }
        .onChange(of: journalEntries) { _ in
            ReflectJournalStore.saveEntries(journalEntries)
        }
        .onChange(of: entryTags) { _ in
            ReflectJournalTagStore.saveTags(entryTags)
        }
        .onChange(of: prompt) { _ in
            upsertPromptForToday()
        }
    }

    private func upsertEntryForToday(promptResponse: String) {
        let todayKey = ReflectDateKey(date: today, calendar: calendar)
        if let index = journalEntries.firstIndex(where: { ReflectDateKey(date: $0.date, calendar: calendar) == todayKey }) {
            journalEntries[index].prompt = prompt
            journalEntries[index].promptResponse = promptResponse
        } else {
            journalEntries.insert(
                ReflectJournalEntry(date: today, prompt: prompt, promptResponse: promptResponse, journalText: ""),
                at: 0
            )
        }
    }

    private func normalizeEntries(_ entries: [ReflectJournalEntry]) -> [ReflectJournalEntry] {
        var buckets: [ReflectDateKey: ReflectJournalEntry] = [:]
        for entry in entries.sorted(by: { $0.date > $1.date }) {
            let key = ReflectDateKey(date: entry.date, calendar: calendar)
            if buckets[key] == nil {
                buckets[key] = entry
            }
        }
        return buckets.values.sorted { $0.date > $1.date }
    }

    private var todayEntryID: UUID? {
        let todayKey = ReflectDateKey(date: today, calendar: calendar)
        return journalEntries.first(where: { ReflectDateKey(date: $0.date, calendar: calendar) == todayKey })?.id
    }

    private var savedPromptResponseForToday: String {
        let todayKey = ReflectDateKey(date: today, calendar: calendar)
        return journalEntries.first(where: { ReflectDateKey(date: $0.date, calendar: calendar) == todayKey })?.promptResponse ?? ""
    }

    private var promptPreviewText: String {
        let saved = savedPromptResponseForToday.trimmingCharacters(in: .whitespacesAndNewlines)
        if !saved.isEmpty {
            return filledPromptPreview(prompt, with: saved)
        }

        let draft = promptResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if !draft.isEmpty {
            return filledPromptPreview(prompt, with: draft)
        }

        return ReflectJournalPrompt.displayPrompt(prompt)
    }

    private func toggleTag(_ tag: JournalTag, for entryID: UUID) {
        var tags = entryTags[entryID, default: []]
        if tags.contains(tag) {
            tags.remove(tag)
        } else {
            tags.insert(tag)
        }
        entryTags[entryID] = tags
    }

    private func upsertPromptForToday() {
        let todayKey = ReflectDateKey(date: today, calendar: calendar)
        if let index = journalEntries.firstIndex(where: { ReflectDateKey(date: $0.date, calendar: calendar) == todayKey }) {
            journalEntries[index].prompt = prompt
        } else {
            journalEntries.insert(
                ReflectJournalEntry(date: today, prompt: prompt, promptResponse: "", journalText: ""),
                at: 0
            )
        }
    }

    private func filledPromptPreview(_ prompt: String, with entry: String) -> String {
        let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ReflectJournalPrompt.displayPrompt(prompt)
        }

        if prompt.contains("...") {
            return prompt.replacingOccurrences(of: "...", with: trimmed)
        }
        if prompt.contains("_____") {
            return prompt.replacingOccurrences(of: "_____", with: trimmed)
        }
        return "\(prompt) \(trimmed)"
    }

    private var loggedEntryDates: [Date] {
        journalEntries.compactMap { entry in
            let hasContent = !entry.promptResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !entry.journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return hasContent ? calendar.startOfDay(for: entry.date) : nil
        }
    }

    private var currentStreak: Int {
        let loggedDays = Set(loggedEntryDates)
        var streak = 0
        var day = calendar.startOfDay(for: Date())
        while loggedDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    private var longestStreak: Int {
        let days = Set(loggedEntryDates).sorted()
        guard !days.isEmpty else { return 0 }
        var longest = 1
        var current = 1
        for idx in 1..<days.count {
            let prev = days[idx - 1]
            let currentDay = days[idx]
            if calendar.date(byAdding: .day, value: 1, to: prev) == currentDay {
                current += 1
            } else {
                longest = max(longest, current)
                current = 1
            }
        }
        return max(longest, current)
    }
}

struct ReflectJournalSurfaceCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
    }
}

struct ReflectJournalActionButton<Fill: ShapeStyle>: View {
    let title: String
    let systemImage: String
    let fill: Fill
    let textColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(.custom("AvenirNext-Medium", size: 13))
        }
        .foregroundStyle(textColor)
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(
            Capsule().fill(fill)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                .blendMode(.softLight)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 6)
    }
}

struct ReflectLinedPaper: View {
    private let lineSpacing: CGFloat = 22

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            Path { path in
                var y: CGFloat = 0
                while y < height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                    y += lineSpacing
                }
            }
            .stroke(Color.black.opacity(0.08), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

private enum ReflectJournalCoverTab: String, CaseIterable, Identifiable {
    case today = "Today"
    case thisWeek = "This week"
    case pastEntries = "Past Entries"

    var id: String { rawValue }
}

struct ReflectJournalCoverSection: View {
    @Binding var entries: [ReflectJournalEntry]
    @Binding var entryTags: [UUID: Set<JournalTag>]
    @Binding var placedStamps: [ReflectPlacedStamp]
    @Binding var loggedMoods: [ReflectDateKey: ReflectMoodOption]
    @Binding var selectedEntryID: UUID?

    @State private var selectedTab: ReflectJournalCoverTab = .today
    @State private var isOpen = false
    @State private var isWritingToday = false
    @FocusState private var isTodayEditorFocused: Bool

    private let tabTextColor = Color.black.opacity(0.8)
    private let tabInactiveColor = Color.black.opacity(0.56)
    private let pageCardBackground = Color(red: 0.98, green: 0.98, blue: 0.97)
    private let coverPanelHeight: CGFloat = 520
    private var calendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        return cal
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Text("My Journal")
                    .font(.custom("Georgia", size: 22))
                    .foregroundStyle(Color.black.opacity(0.85))

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        if isOpen {
                            isWritingToday = false
                            isTodayEditorFocused = false
                        }
                        isOpen.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isOpen ? "book.closed" : "book.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(isOpen ? "Close" : "Open")
                            .font(.custom("AvenirNext-Medium", size: 12))
                    }
                    .foregroundStyle(Color.black.opacity(0.75))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 0) {
                ForEach(ReflectJournalCoverTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            selectedTab = tab
                            isOpen = true
                            if tab != .today {
                                isWritingToday = false
                                isTodayEditorFocused = false
                            }
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(tab.rawValue)
                                .font(.custom("SortsMillGoudy-Regular", size: 13))
                                .foregroundStyle(selectedTab == tab ? tabTextColor : tabInactiveColor)
                                .frame(maxWidth: .infinity)

                            Rectangle()
                                .fill(selectedTab == tab ? Color.black.opacity(0.34) : Color.clear)
                                .frame(height: 1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)

                    if tab != ReflectJournalCoverTab.allCases.last {
                        Rectangle()
                            .fill(Color.black.opacity(0.08))
                            .frame(width: 1, height: 22)
                    }
                }
            }
            .padding(.horizontal, 10)

            Group {
                if isOpen {
                    openJournalContent
                } else {
                    coverImage
                        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                isOpen = true
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, minHeight: coverPanelHeight, maxHeight: coverPanelHeight, alignment: .top)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .overlay(alignment: .bottomTrailing) {
                if isOpen && selectedTab == .today && !isWritingToday {
                    Button {
                        activateWritingMode()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.95, green: 0.92, blue: 0.74),
                                            Color(red: 0.97, green: 0.73, blue: 0.53),
                                            Color(red: 0.95, green: 0.44, blue: 0.59)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 52, height: 52)
                                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)

                            if let pencil = UIImage(named: "pencil") ?? UIImage(named: "pencil.png") {
                                Image(uiImage: pencil)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                            } else {
                                Image(systemName: "pencil")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 14)
                    .padding(.bottom, 14)
                }
            }
            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var coverImage: some View {
        ZStack(alignment: .leading) {
            Group {
                if let cover = UIImage(named: "journal") ?? UIImage(named: "journal.png") {
                    Image(uiImage: cover)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.85))
                        .frame(height: coverPanelHeight)
                        .overlay(
                            Text("journal.png not found")
                                .font(.custom("AvenirNext-Medium", size: 13))
                                .foregroundStyle(Color.black.opacity(0.5))
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.18)],
                startPoint: .top,
                endPoint: .bottom
            )

            Text("My Journal")
                .font(.custom("Georgia", size: 34))
                .foregroundStyle(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.28), radius: 6, x: 0, y: 3)
                .multilineTextAlignment(.leading)
                .padding(.leading, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var openJournalContent: some View {
        switch selectedTab {
        case .today:
            ReflectJournalPageCard {
                VStack(alignment: .leading, spacing: 14) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.92, green: 0.95, blue: 0.77),
                                    Color(red: 0.98, green: 0.65, blue: 0.57),
                                    Color(red: 0.98, green: 0.91, blue: 0.92)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 86)
                        .overlay(
                            Text(todayPromptLine)
                                .font(.custom("Georgia", size: 14))
                                .foregroundStyle(Color.black.opacity(0.88))
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                                .padding(.horizontal, 18)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 5)

                    HStack(spacing: 12) {
                        Text("Today (\(dayMonthFormatter.string(from: Date())))")
                            .font(.custom("SortsMillGoudy-Italic", size: 18))
                            .foregroundStyle(Color.black.opacity(0.84))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)

                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .frame(height: 1)
                    }

                    if isWritingToday {
                        TextEditor(text: todayJournalTextBinding)
                            .font(.custom("AvenirNext-Regular", size: 14))
                            .foregroundStyle(Color.black.opacity(0.84))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 180)
                            .padding(.horizontal, 10)
                            .padding(.top, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.88))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                    )
                            )
                            .focused($isTodayEditorFocused)

                        HStack {
                            Spacer()
                            Button("Done") {
                                isWritingToday = false
                                isTodayEditorFocused = false
                            }
                            .font(.custom("AvenirNext-Medium", size: 12))
                            .foregroundStyle(Color.black.opacity(0.72))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.06))
                            )
                        }
                    } else {
                        Text(todayJournalBody)
                            .font(.custom("AvenirNext-Regular", size: 13))
                            .foregroundStyle(Color.black.opacity(0.82))
                            .lineSpacing(3)
                    }

                    Spacer(minLength: 170)
                }
            }

        case .thisWeek:
            ReflectJournalPageCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("This week")
                        .font(.custom("SortsMillGoudy-Italic", size: 24))
                        .foregroundStyle(Color.black.opacity(0.84))

                    HStack(spacing: 10) {
                        Text("\(monthDayFormatter.string(from: weekDates.first ?? Date())) - \(monthDayFormatter.string(from: weekDates.last ?? Date()))")
                            .font(.custom("AvenirNext-Medium", size: 11))
                            .foregroundStyle(Color.black.opacity(0.55))
                        Rectangle()
                            .fill(Color.black.opacity(0.2))
                            .frame(height: 1)
                    }

                    VStack(spacing: 0) {
                        ForEach(weekDates, id: \.self) { date in
                            let entry = entryForDate(date)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("\(weekdayFormatter.string(from: date)) (\(dayMonthFormatter.string(from: date)))")
                                        .font(.custom("AvenirNext-DemiBold", size: 12))
                                        .foregroundStyle(Color.black.opacity(0.75))
                                    Spacer()
                                    if entry != nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Color(red: 0.2, green: 0.45, blue: 0.28))
                                    }
                                }

                                Text(weeklyLine(for: entry))
                                    .font(.custom("AvenirNext-Regular", size: 12))
                                    .foregroundStyle(Color.black.opacity(0.78))
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 10)

                            if date != weekDates.last {
                                Rectangle()
                                    .fill(Color.black.opacity(0.08))
                                    .frame(height: 1)
                            }
                        }
                    }
                }
            }

        case .pastEntries:
            ReflectNotebookView(
                entries: $entries,
                placedStamps: $placedStamps,
                loggedMoods: $loggedMoods,
                entryTags: $entryTags,
                selectedEntryID: $selectedEntryID,
                preferredHeight: coverPanelHeight
            )
            .background(pageCardBackground)
        }
    }

    private var todayPromptLine: String {
        guard let todayEntry = entryForDate(Date()) else {
            return "I enjoyed ___."
        }

        let response = todayEntry.promptResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if response.isEmpty {
            return ReflectJournalPrompt.displayPrompt(todayEntry.prompt)
        }
        return filledPromptString(todayEntry.prompt, with: response)
    }

    private var todayJournalBody: String {
        guard let todayEntry = entryForDate(Date()) else {
            return "Log your thoughts, emotions, and events from today."
        }

        let body = todayEntry.journalText.trimmingCharacters(in: .whitespacesAndNewlines)
        if body.isEmpty {
            return "Log your thoughts, emotions, and events from today."
        }
        return body
    }

    private var weekDates: [Date] {
        guard let start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func entryForDate(_ date: Date) -> ReflectJournalEntry? {
        entries.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private var todayJournalTextBinding: Binding<String> {
        Binding(
            get: {
                entryForDate(Date())?.journalText ?? ""
            },
            set: { newValue in
                upsertTodayJournalText(newValue)
            }
        )
    }

    private func weeklyLine(for entry: ReflectJournalEntry?) -> String {
        guard let entry else { return "No entry yet." }

        let journal = entry.journalText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !journal.isEmpty {
            return journal
        }

        let response = entry.promptResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if !response.isEmpty {
            return filledPromptString(entry.prompt, with: response)
        }

        return ReflectJournalPrompt.displayPrompt(entry.prompt)
    }

    private var weekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE"
        return formatter
    }

    private var dayMonthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "M/d"
        return formatter
    }

    private var monthDayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM d"
        return formatter
    }

    private func activateWritingMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isOpen = true
            selectedTab = .today
            isWritingToday = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            isTodayEditorFocused = true
        }
    }

    private func upsertTodayJournalText(_ text: String) {
        if let index = entries.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: Date()) }) {
            entries[index].journalText = text
            selectedEntryID = entries[index].id
            return
        }

        let newEntry = ReflectJournalEntry(
            date: Date(),
            prompt: ReflectJournalPrompt.randomPrompt(),
            promptResponse: "",
            journalText: text
        )
        entries.insert(newEntry, at: 0)
        selectedEntryID = newEntry.id
    }

    private func filledPromptString(_ prompt: String, with entry: String) -> String {
        let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ReflectJournalPrompt.displayPrompt(prompt) }

        if prompt.contains("...") {
            return prompt.replacingOccurrences(of: "...", with: trimmed)
        }
        if prompt.contains("_____") {
            return prompt.replacingOccurrences(of: "_____", with: trimmed)
        }
        return "\(prompt) \(trimmed)"
    }
}

private struct ReflectJournalPageCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.98, green: 0.98, blue: 0.97))
            )
    }
}

enum JournalSortOption: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case oldest = "Oldest"
    case tags = "Tags"

    var id: String { rawValue }
}

struct ReflectNotebookView: View {
    @Binding var entries: [ReflectJournalEntry]
    @Binding var placedStamps: [ReflectPlacedStamp]
    @Binding var loggedMoods: [ReflectDateKey: ReflectMoodOption]
    @Binding var entryTags: [UUID: Set<JournalTag>]
    @Binding var selectedEntryID: UUID?
    let preferredHeight: CGFloat
    @FocusState private var focusedEntryID: UUID?
    private let calendar = Calendar.current
    private let cardCornerRadius: CGFloat = 24
    @State private var searchText: String = ""
    @State private var sortOption: JournalSortOption = .recent
    @State private var selectedTag: JournalTag? = nil
    @State private var showEntryDetail = false

    init(
        entries: Binding<[ReflectJournalEntry]>,
        placedStamps: Binding<[ReflectPlacedStamp]>,
        loggedMoods: Binding<[ReflectDateKey: ReflectMoodOption]>,
        entryTags: Binding<[UUID: Set<JournalTag>]>,
        selectedEntryID: Binding<UUID?>,
        preferredHeight: CGFloat = 460
    ) {
        _entries = entries
        _placedStamps = placedStamps
        _loggedMoods = loggedMoods
        _entryTags = entryTags
        _selectedEntryID = selectedEntryID
        self.preferredHeight = preferredHeight
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let filteredEntries = filteredAndSortedEntries()
            let selectedEntry = entries.first { $0.id == selectedEntryID }
            let fallbackEntry = entries.sorted { $0.date < $1.date }.last
            let selectedMood: ReflectMoodOption? = {
                guard let date = selectedEntry?.date else { return nil }
                let key = ReflectDateKey(date: date, calendar: calendar)
                return loggedMoods[key]
            }()
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        if showEntryDetail {
                            Button {
                                showEntryDetail = false
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.black.opacity(0.75))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.06))
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        Text("My Journal")
                            .font(.custom("Georgia", size: 22))
                            .foregroundStyle(Color.black.opacity(0.8))
                        Spacer()
                    }
                    .padding(.top, 18)
                    .padding(.horizontal, 24)

                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    if showEntryDetail {
                        if let entryIndex = entries.firstIndex(where: { $0.id == selectedEntryID }) {
                            let entry = entries[entryIndex]
                            let promptLine = ReflectJournalPrompt.filledPrompt(
                                entry.prompt,
                                with: entry.promptResponse
                            )
                            let tags = entryTags[entry.id, default: []]
                            VStack(alignment: .leading, spacing: 12) {
                                Text(ReflectJournalPrompt.dateLabel(entry.date))
                                    .font(.custom("AvenirNext-Medium", size: 11))
                                    .foregroundStyle(Color.black.opacity(0.55))
                                Group {
                                    if entry.promptResponse.isEmpty {
                                        Text(ReflectJournalPrompt.displayPrompt(entry.prompt))
                                    } else {
                                        promptLine
                                    }
                                }
                                .font(.custom("Georgia", size: 20))
                                .foregroundStyle(Color.black.opacity(0.86))
                                .fixedSize(horizontal: false, vertical: true)
                                if !tags.isEmpty {
                                    HStack(spacing: 6) {
                                        ForEach(tags.sorted(by: { $0.title < $1.title })) { tag in
                                            Text(tag.title)
                                                .font(.custom("AvenirNext-Medium", size: 10))
                                                .foregroundStyle(Color.black.opacity(0.7))
                                                .padding(.vertical, 4)
                                                .padding(.horizontal, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(tag.color.opacity(0.2))
                                                )
                                        }
                                    }
                                }
                                ZStack(alignment: .topLeading) {
                                    TextEditor(text: $entries[entryIndex].journalText)
                                        .font(.custom("AvenirNext-Regular", size: 14))
                                        .foregroundStyle(Color.black.opacity(0.82))
                                        .scrollContentBackground(.hidden)
                                        .frame(minHeight: 140)
                                        .focused($focusedEntryID, equals: entry.id)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(Color.black.opacity(0.03))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                                )
                                        )

                                    if entry.journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text("Tap to write...")
                                            .font(.custom("AvenirNext-Regular", size: 13))
                                            .foregroundStyle(Color.black.opacity(0.35))
                                            .padding(.horizontal, 12)
                                            .padding(.top, 12)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(Color.black.opacity(0.35))
                                Text("Select an entry")
                                    .font(.custom("AvenirNext-Regular", size: 13))
                                    .foregroundStyle(Color.black.opacity(0.55))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 34)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color.black.opacity(0.45))
                                    TextField("Search answers", text: $searchText)
                                        .font(.custom("AvenirNext-Regular", size: 12))
                                        .foregroundStyle(Color.black.opacity(0.8))
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.black.opacity(0.04))
                                )

                                Menu {
                                    ForEach(JournalSortOption.allCases) { option in
                                        Button(option.rawValue) {
                                            sortOption = option
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(sortOption.rawValue)
                                            .font(.custom("AvenirNext-Medium", size: 11))
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                    .foregroundStyle(Color.black.opacity(0.7))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.06))
                                    )
                                }
                            }

                            if sortOption == .tags {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        Button {
                                            selectedTag = nil
                                        } label: {
                                            Text("All Tags")
                                                .font(.custom("AvenirNext-Medium", size: 11))
                                                .foregroundStyle(selectedTag == nil ? Color.black.opacity(0.9) : Color.black.opacity(0.6))
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 12)
                                                .background(
                                                    Capsule()
                                                        .fill(selectedTag == nil ? Color.black.opacity(0.08) : Color.black.opacity(0.04))
                                                )
                                        }
                                        .buttonStyle(.plain)

                                        ForEach(JournalTag.allCases) { tag in
                                            let isSelected = selectedTag == tag
                                            Button {
                                                selectedTag = tag
                                            } label: {
                                                Text(tag.title)
                                                    .font(.custom("AvenirNext-Medium", size: 11))
                                                    .foregroundStyle(isSelected ? Color.black.opacity(0.9) : Color.black.opacity(0.6))
                                                    .padding(.vertical, 6)
                                                    .padding(.horizontal, 12)
                                                    .background(
                                                        Capsule()
                                                            .fill(isSelected ? tag.color.opacity(0.25) : Color.black.opacity(0.04))
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 2)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                        if filteredEntries.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(Color.black.opacity(0.35))
                                Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No entries yet" : "No matching entries")
                                    .font(.custom("AvenirNext-Regular", size: 13))
                                    .foregroundStyle(Color.black.opacity(0.55))
                                Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Start with today's prompt above, then write freely here." : "Try a different search or tag.")
                                    .font(.custom("AvenirNext-Regular", size: 11))
                                    .foregroundStyle(Color.black.opacity(0.4))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 34)
                        } else {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(filteredEntries.indices, id: \.self) { index in
                                        let entry = filteredEntries[index]
                                        let promptLine = ReflectJournalPrompt.filledPrompt(
                                            entry.prompt,
                                            with: entry.promptResponse
                                        )
                                        Button {
                                            selectedEntryID = entry.id
                                            focusedEntryID = entry.id
                                            showEntryDetail = true
                                        } label: {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(ReflectJournalPrompt.dateLabel(entry.date))
                                                    .font(.custom("AvenirNext-Medium", size: 11))
                                                    .foregroundStyle(Color.black.opacity(0.55))
                                                Group {
                                                    if entry.promptResponse.isEmpty {
                                                        Text(ReflectJournalPrompt.displayPrompt(entry.prompt))
                                                    } else {
                                                        promptLine
                                                    }
                                                }
                                                .font(.custom("Georgia", size: 18))
                                                .foregroundStyle(Color.black.opacity(0.85))
                                                .lineLimit(2)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 24)
                                        }
                                        .buttonStyle(.plain)

                                        if index < filteredEntries.count - 1 {
                                            Rectangle()
                                                .fill(Color.black.opacity(0.06))
                                                .frame(height: 1)
                                                .padding(.horizontal, 24)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 6)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                if showEntryDetail, let selectedMood {
                    MoodAssetImage(
                        assetName: selectedMood.assetName,
                        intensity: 0.85,
                        contentMode: .fit
                    )
                    .frame(width: 72, height: 72)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 20)
                    .padding(.bottom, 18)
                }

                if showEntryDetail {
                    ForEach($placedStamps) { $stamp in
                        ReflectStampBadge(stamp: stamp.stamp)
                            .frame(width: 54, height: 54)
                            .position(stamp.position)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        stamp.position = ReflectStampPlacement.clampedPosition(
                                            proposed: value.location,
                                            in: size,
                                            stampSize: CGSize(width: 54, height: 54)
                                        )
                                    }
                            )
                    }
                }
            }
            .onAppear {
                if selectedEntryID == nil {
                    selectedEntryID = fallbackEntry?.id
                }
            }
            .onChange(of: entries) { _ in
                if let selectedEntryID,
                   entries.contains(where: { $0.id == selectedEntryID }) {
                    return
                }
                selectedEntryID = entries.sorted { $0.date < $1.date }.last?.id
            }
            .onChange(of: searchText) { _ in
                showEntryDetail = false
                if !filteredAndSortedEntries().contains(where: { $0.id == selectedEntryID }) {
                    selectedEntryID = filteredAndSortedEntries().first?.id
                }
            }
            .onChange(of: sortOption) { _ in
                showEntryDetail = false
                if !filteredAndSortedEntries().contains(where: { $0.id == selectedEntryID }) {
                    selectedEntryID = filteredAndSortedEntries().first?.id
                }
            }
            .onChange(of: selectedTag) { _ in
                showEntryDetail = false
                if !filteredAndSortedEntries().contains(where: { $0.id == selectedEntryID }) {
                    selectedEntryID = filteredAndSortedEntries().first?.id
                }
            }
        }
        .frame(height: preferredHeight)
    }

    private func filteredAndSortedEntries() -> [ReflectJournalEntry] {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var results = entries
        if !trimmedQuery.isEmpty {
            let lowered = trimmedQuery.lowercased()
            results = results.filter { entry in
                entry.promptResponse.lowercased().contains(lowered)
            }
        }

        if sortOption == .tags, let selectedTag {
            results = results.filter { entryTags[$0.id, default: []].contains(selectedTag) }
        }

        switch sortOption {
        case .oldest:
            return results.sorted { $0.date < $1.date }
        case .recent, .tags:
            return results.sorted { $0.date > $1.date }
        }
    }

}

struct ReflectMoodDayDisplay: Identifiable {
    let id = UUID()
    let dayLabel: String
    let dateLabel: String
    let mood: ReflectMoodOption?
}

enum JournalTag: String, CaseIterable, Identifiable, Hashable {
    case reflection = "Reflection"
    case work = "Work"
    case creativity = "Creativity"
    case rest = "Rest"

    var id: String { rawValue }
    var title: String { rawValue }

    var color: Color {
        switch self {
        case .reflection: return Color(red: 0.16, green: 0.3, blue: 0.22)
        case .work: return Color(red: 0.22, green: 0.24, blue: 0.45)
        case .creativity: return Color(red: 0.6, green: 0.33, blue: 0.2)
        case .rest: return Color(red: 0.28, green: 0.44, blue: 0.5)
        }
    }
}

struct ReflectJournalEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    var prompt: String
    var promptResponse: String
    var journalText: String

    init(id: UUID = UUID(), date: Date, prompt: String, promptResponse: String, journalText: String) {
        self.id = id
        self.date = date
        self.prompt = prompt
        self.promptResponse = promptResponse
        self.journalText = journalText
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case date
        case prompt
        case promptResponse
        case journalText
        case text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decode(Date.self, forKey: .date)
        prompt = try container.decode(String.self, forKey: .prompt)
        promptResponse = try container.decodeIfPresent(String.self, forKey: .promptResponse)
            ?? container.decodeIfPresent(String.self, forKey: .text)
            ?? ""
        journalText = try container.decodeIfPresent(String.self, forKey: .journalText) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(promptResponse, forKey: .promptResponse)
        try container.encode(journalText, forKey: .journalText)
    }
}

struct ReflectJournalPrompt {
    static let prompts: [String] = [
        "I enjoyed ...",
        "One small win today was ...",
        "I felt calm when ...",
        "Something that made me laugh ...",
        "I’m grateful for ...",
        "I learned that ...",
        "A moment I want to remember is ...",
        "A thought I keep returning to is ...",
        "I felt most like myself when ...",
        "A challenge I handled well was ...",
        "I surprised myself by ...",
        "I want to bring more of ... into tomorrow.",
        "I felt supported when ...",
        "A boundary I honored today was ...",
        "A habit that helped me today was ...",
        "A moment of peace came from ...",
        "I recharged by ...",
        "The best part of my day was ...",
        "A conversation that mattered was ...",
        "Something I’d like to let go of is ...",
        "One moment I felt fully focused was ...",
        "An app or activity that pulled me off track was ...",
        "I felt most present when ...",
        "A choice that supported my goals was ...",
        "I felt stressed when ...",
        "I felt energized after ...",
        "A small act of kindness I noticed was ...",
        "I want to remember how I felt when ...",
        "My attention felt scattered when ...",
        "One thing I did for myself today was ..."
    ]

    static func randomPrompt() -> String {
        prompts.randomElement() ?? "I enjoyed ..."
    }

    static func displayPrompt(_ prompt: String) -> String {
        if prompt.contains("...") {
            return prompt.replacingOccurrences(of: "...", with: "_____")
        }
        if prompt.contains("_____") {
            return prompt
        }
        return prompt
    }

    static func promptFontSize(for prompt: String) -> CGFloat {
        let length = prompt.count
        if length > 110 { return 18 }
        if length > 80 { return 20 }
        if length > 60 { return 22 }
        return 24
    }

    static func filledPrompt(_ prompt: String, with entry: String) -> Text {
        let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return Text(displayPrompt(prompt))
        }

        if let range = prompt.range(of: "...") {
            let prefix = String(prompt[..<range.lowerBound])
            let suffix = String(prompt[range.upperBound...])
            return Text(prefix) + Text(trimmed).underline() + Text(suffix)
        }

        if let range = prompt.range(of: "_____") {
            let prefix = String(prompt[..<range.lowerBound])
            let suffix = String(prompt[range.upperBound...])
            return Text(prefix) + Text(trimmed).underline() + Text(suffix)
        }

        return Text(prompt + " ") + Text(trimmed).underline()
    }

    static func dateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

struct ReflectJournalStore {
    private static let entriesKey = "reflect.journal.entries"

    static func loadEntries() -> [ReflectJournalEntry] {
        guard let data = UserDefaults.standard.data(forKey: entriesKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([ReflectJournalEntry].self, from: data)) ?? []
    }

    static func saveEntries(_ entries: [ReflectJournalEntry]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: entriesKey)
    }
}

struct ReflectJournalTagStore {
    private struct TagRecord: Codable {
        let id: UUID
        let tags: [String]
    }

    private static let tagsKey = "reflect.journal.tags"

    static func loadTags() -> [UUID: Set<JournalTag>] {
        guard let data = UserDefaults.standard.data(forKey: tagsKey) else { return [:] }
        let decoder = JSONDecoder()
        guard let records = try? decoder.decode([TagRecord].self, from: data) else { return [:] }
        var results: [UUID: Set<JournalTag>] = [:]
        for record in records {
            let tags = record.tags.compactMap { JournalTag(rawValue: $0) }
            results[record.id] = Set(tags)
        }
        return results
    }

    static func saveTags(_ tagsByID: [UUID: Set<JournalTag>]) {
        let records = tagsByID.map { id, tags in
            TagRecord(id: id, tags: tags.map(\.rawValue))
        }
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(records) else { return }
        UserDefaults.standard.set(data, forKey: tagsKey)
    }
}

struct ReflectMoodStore {
    private struct MoodRecord: Codable {
        let year: Int
        let month: Int
        let day: Int
        let moodName: String
    }

    private static let moodsKey = "reflect.moods.entries"

    static func loadMoods() -> [ReflectDateKey: ReflectMoodOption] {
        guard let data = UserDefaults.standard.data(forKey: moodsKey) else { return [:] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let records = try? decoder.decode([MoodRecord].self, from: data) else { return [:] }
        var results: [ReflectDateKey: ReflectMoodOption] = [:]
        for record in records {
            guard let mood = ReflectMoodOption.fromName(record.moodName) else { continue }
            let key = ReflectDateKey(year: record.year, month: record.month, day: record.day)
            results[key] = mood
        }
        return results
    }

    static func saveMoods(_ moods: [ReflectDateKey: ReflectMoodOption]) {
        let records = moods.map { key, mood in
            MoodRecord(year: key.year, month: key.month, day: key.day, moodName: mood.name)
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(records) else { return }
        UserDefaults.standard.set(data, forKey: moodsKey)
    }
}

struct ReflectMoodLevelStore {
    private static func levelsKey(for dateKey: ReflectDateKey) -> String {
        "reflect.mood.levels.\(dateKey.year)-\(dateKey.month)-\(dateKey.day)"
    }

    static func loadLevels(for dateKey: ReflectDateKey, defaults: [MoodLevelState]) -> [MoodLevelState] {
        let key = levelsKey(for: dateKey)
        guard let data = UserDefaults.standard.data(forKey: key) else { return defaults }
        let decoder = JSONDecoder()
        return (try? decoder.decode([MoodLevelState].self, from: data)) ?? defaults
    }

    static func saveLevels(_ levels: [MoodLevelState], for dateKey: ReflectDateKey) {
        let key = levelsKey(for: dateKey)
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(levels) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

struct ReflectStampDefinition: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let color: Color
    let symbol: String

    static let samples: [ReflectStampDefinition] = [
        .init(title: "Hibernator", subtitle: "refrain from using your device for over 24 hrs", color: .red, symbol: "pawprint"),
        .init(title: "Inspired", subtitle: "spend 3+ hours on creativity apps", color: .blue, symbol: "paintbrush"),
        .init(title: "Gardener", subtitle: "spend 1+ hr daily on productivity", color: .green, symbol: "leaf"),
        .init(title: "Anti-Scroller", subtitle: "avoid spending over 30 minutes drifting", color: .purple, symbol: "lotus")
    ]
}

struct ReflectPlacedStamp: Identifiable {
    let id = UUID()
    let stamp: ReflectStampDefinition
    var position: CGPoint
}

struct ReflectStampBadge: View {
    let stamp: ReflectStampDefinition

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(stamp.color.opacity(0.12))
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    stamp.color.opacity(0.7),
                    style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])
                )
            VStack(spacing: 4) {
                Image(systemName: stamp.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(stamp.color.opacity(0.8))
                Text(stamp.title)
                    .font(.custom("AvenirNext-DemiBold", size: 8))
                    .foregroundStyle(stamp.color.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 4)
        }
    }
}

struct ReflectStampPlacement {
    static func clampedPosition(proposed: CGPoint, in size: CGSize, stampSize: CGSize) -> CGPoint {
        let halfW = stampSize.width / 2
        let halfH = stampSize.height / 2
        let minX = halfW + 6
        let maxX = size.width - halfW - 6
        let minY = halfH + 6
        let maxY = size.height - halfH - 6

        let clampedX = min(max(proposed.x, minX), maxX)
        let clampedY = min(max(proposed.y, minY), maxY)
        let borderBand: CGFloat = 26

        let distLeft = clampedX - minX
        let distRight = maxX - clampedX
        let distTop = clampedY - minY
        let distBottom = maxY - clampedY
        let minDist = min(distLeft, distRight, distTop, distBottom)

        if minDist <= borderBand {
            return CGPoint(x: clampedX, y: clampedY)
        }

        if minDist == distLeft {
            return CGPoint(x: minX, y: clampedY)
        } else if minDist == distRight {
            return CGPoint(x: maxX, y: clampedY)
        } else if minDist == distTop {
            return CGPoint(x: clampedX, y: minY)
        } else {
            return CGPoint(x: clampedX, y: maxY)
        }
    }
}

struct ReflectMoodOption: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let assetName: String

    static let moods: [ReflectMoodOption] = [
        .init(name: "Happy", assetName: "Illustration294 1"),
        .init(name: "Fine", assetName: "Illustration295 1"),
        .init(name: "Frustrated", assetName: "Illustration296 1"),
        .init(name: "Anxious", assetName: "Illustration297 1"),
        .init(name: "Excited", assetName: "Illustration298 1"),
        .init(name: "Sad", assetName: "Illustration299 1"),
        .init(name: "Tired", assetName: "Illustration300 1"),
        .init(name: "Bored", assetName: "Illustration301 1"),
        .init(name: "Content", assetName: "Illustration302 1")
    ]

    static func fromName(_ name: String) -> ReflectMoodOption? {
        moods.first { $0.name == name }
    }

    var reflectionEmotionNoun: String {
        switch name {
        case "Happy": return "happiness"
        case "Fine": return "sense of feeling fine"
        case "Frustrated": return "frustration"
        case "Anxious": return "anxiety"
        case "Excited": return "excitement"
        case "Sad": return "sadness"
        case "Tired": return "tiredness"
        case "Bored": return "boredom"
        case "Content": return "contentment"
        default: return name.lowercased()
        }
    }
}

struct MoodLevelState: Identifiable, Codable, Equatable {
    let id = UUID()
    let label: String
    var value: Double

    var iconAssetName: String {
        label.lowercased()
    }
}

struct MoodLevelRow: View {
    @Binding var level: MoodLevelState
    private let segmentValues: [Double] = [0, 0.25, 0.5, 0.75, 1]

    var body: some View {
        HStack(spacing: 14) {
            Image(level.iconAssetName)
                .interpolation(.high)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)

            Text(level.label.capitalized)
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundStyle(Color.black.opacity(0.8))
                .frame(width: 86, alignment: .leading)

            MoodLevelBar(value: $level.value, segmentValues: segmentValues)
                .frame(height: 22)
        }
    }
}

struct MoodLevelBar: View {
    @Binding var value: Double
    let segmentValues: [Double]

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let fillWidth = width * CGFloat(value)
            let visibleFillWidth: CGFloat = value > 0 ? max(10, fillWidth) : 0
            let segmentCount = max(segmentValues.count - 1, 1)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.96))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.94, green: 0.42, blue: 0.57).opacity(0.85),
                                Color(red: 0.95, green: 0.63, blue: 0.35).opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: min(width, visibleFillWidth))

                Capsule()
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)

                Capsule()
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    .padding(0.5)

                ForEach(1..<segmentCount, id: \.self) { idx in
                    Rectangle()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: 1)
                        .position(
                            x: (width * CGFloat(idx)) / CGFloat(segmentCount),
                            y: proxy.size.height / 2
                        )
                }
            }
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.14), radius: 2, x: 0, y: 1)
            .contentShape(Rectangle())
            .animation(.easeOut(duration: 0.12), value: value)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let clampedX = min(max(gesture.location.x, 0), width)
                        let rawValue = Double(clampedX / max(width, 1))
                        let steps = max(Double(segmentValues.count - 1), 1)
                        let stepped = (rawValue * steps).rounded() / steps
                        value = min(max(stepped, 0), 1)
                    }
            )
        }
    }
}

struct MostExperiencedMood: Identifiable {
    let id = UUID()
    let monthLabel: String
    let mood: ReflectMoodOption
}

struct MostExperiencedMoodCard: View {
    let item: MostExperiencedMood

    var body: some View {
        VStack(spacing: 0) {
            Text(item.monthLabel)
                .font(.custom("SortsMillGoudy-Italic", size: 20))
                .foregroundStyle(Color.black.opacity(0.88))

            Spacer(minLength: 12)

            MoodAssetImage(assetName: item.mood.assetName, intensity: 0.7)
                .frame(width: 104, height: 104)

            Spacer(minLength: 12)

            Text(item.mood.name)
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundStyle(Color.black.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

struct ReflectDateKey: Hashable {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    init(date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        year = components.year ?? 0
        month = components.month ?? 0
        day = components.day ?? 0
    }
}

extension ReflectView {
    private func last7Days() -> [ReflectMoodDayDisplay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "M.d"
        let weekdayLabels = ["SU", "M", "TU", "W", "TH", "F", "S"]

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -6 + offset, to: today) else { return nil }
            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            let key = ReflectDateKey(date: date, calendar: calendar)
            let mood = loggedMoods[key]
            return ReflectMoodDayDisplay(
                dayLabel: weekdayLabels[weekdayIndex],
                dateLabel: formatter.string(from: date),
                mood: mood
            )
        }
    }

    private func moodForDate(_ date: Date) -> ReflectMoodOption? {
        let key = ReflectDateKey(date: date, calendar: calendar)
        return loggedMoods[key]
    }
}

extension DailyMoodView {
    private var mostExperiencedMoods: [MostExperiencedMood] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"

        var monthBuckets: [MonthKey: [ReflectMoodOption]] = [:]

        for (key, mood) in loggedMoods {
            let monthKey = MonthKey(year: key.year, month: key.month)
            monthBuckets[monthKey, default: []].append(mood)
        }

        let sortedMonths = monthBuckets.keys.sorted {
            if $0.year != $1.year { return $0.year > $1.year }
            return $0.month > $1.month
        }

        return sortedMonths.compactMap { monthKey in
            guard let moods = monthBuckets[monthKey], let most = mostFrequentMood(in: moods) else { return nil }
            var components = DateComponents()
            components.year = monthKey.year
            components.month = monthKey.month
            components.day = 1
            let date = calendar.date(from: components) ?? Date()
            return MostExperiencedMood(
                monthLabel: formatter.string(from: date),
                mood: most
            )
        }
    }

    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func monthGridDays(for date: Date) -> [Int] {
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else { return [] }

        let weekdayIndex = calendar.component(.weekday, from: firstOfMonth) - 1
        let padding = Array(repeating: 0, count: weekdayIndex)
        return padding + Array(range)
    }

    private func moodForDay(_ day: Int, in month: Date) -> ReflectMoodOption? {
        var components = calendar.dateComponents([.year, .month], from: month)
        components.day = day
        guard let date = calendar.date(from: components) else { return nil }
        let key = ReflectDateKey(date: date, calendar: calendar)
        return loggedMoods[key]
    }

    private func moodForDate(_ date: Date) -> ReflectMoodOption? {
        let key = ReflectDateKey(date: date, calendar: calendar)
        return loggedMoods[key]
    }

    private func mostFrequentMood(in moods: [ReflectMoodOption]) -> ReflectMoodOption? {
        var counts: [ReflectMoodOption: Int] = [:]
        for mood in moods {
            counts[mood, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key
    }
}

struct MonthKey: Hashable {
    let year: Int
    let month: Int
}


#Preview {
    ReflectView()
}
