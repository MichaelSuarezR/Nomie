//
//  ReflectView.swift
//  Nomie
//

import SwiftUI
import UIKit

private let reflectLandingMoodCardHeight: CGFloat = 228
private enum ReflectPalette {
    static let primaryGreen = Color(red: 47.0 / 255.0, green: 61.0 / 255.0, blue: 37.0 / 255.0)
    static let secondaryGreen = Color(red: 106.0 / 255.0, green: 119.0 / 255.0, blue: 97.0 / 255.0)
    static let lightGreen = Color(red: 228.0 / 255.0, green: 236.0 / 255.0, blue: 199.0 / 255.0)
    static let brown = Color(red: 81.0 / 255.0, green: 59.0 / 255.0, blue: 55.0 / 255.0)
    static let lightBrown = Color(red: 179.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0)
    static let warmWhite = Color(red: 1.0, green: 254.0 / 255.0, blue: 249.0 / 255.0)
}

private struct ReflectTabBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.98, green: 0.94, blue: 0.80), location: 0.0),
                    .init(color: Color(red: 0.95, green: 0.97, blue: 0.90), location: 0.56),
                    .init(color: Color(red: 0.99, green: 0.93, blue: 0.88), location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .topTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 0.98, green: 0.83, blue: 0.67).opacity(0.42),
                    Color.clear
                ],
                center: UnitPoint(x: 0.66, y: 0.72),
                startRadius: 24,
                endRadius: 380
            )

            RadialGradient(
                colors: [
                    Color(red: 0.97, green: 0.74, blue: 0.66).opacity(0.28),
                    Color.clear
                ],
                center: UnitPoint(x: 0.94, y: 0.70),
                startRadius: 18,
                endRadius: 260
            )

            RadialGradient(
                colors: [
                    Color(red: 0.98, green: 0.90, blue: 0.66).opacity(0.30),
                    Color.clear
                ],
                center: UnitPoint(x: 0.12, y: 0.04),
                startRadius: 12,
                endRadius: 220
            )
        }
        .ignoresSafeArea()
    }
}

enum ReflectLandingSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case dailyMood = "Daily Mood"
    case journal = "Journal"
    case patternsTrends = "Trends"

    var id: String { rawValue }
}

struct ReflectView: View {
    @State private var loggedMoods: [ReflectDateKey: ReflectMoodOption] = [:]
    @State private var journalPrompt = ReflectJournalPrompt.randomPrompt()
    @State private var journalPromptResponse = ""
    @State private var selectedLandingSection: ReflectLandingSection = .overview
    @State private var moodLevelsRefreshTick: Int = 0
    @State private var isLandingMoodOrbitDragging = false
    @State private var isLandingJournalCoverEditing = false
    @State private var journalDeepLinkDate: Date? = nil
    @State private var journalDeepLinkToken: UUID? = nil
    private let topScrollID = "reflect.top.scroll.id"
    private let calendar = Calendar.current
    private let tabBarColor = ReflectPalette.warmWhite
    private let inkColor = ReflectPalette.brown
    private let accentColor = ReflectPalette.primaryGreen

    private var todayMood: ReflectMoodOption? {
        moodForDate(Date())
    }

    private var yesterdayMood: ReflectMoodOption? {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return nil }
        return moodForDate(yesterday)
    }

    private var yesterdayDate: Date? {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return nil }
        return calendar.startOfDay(for: yesterday)
    }

    private var yesterdayJournalEntry: ReflectJournalEntry? {
        guard let yesterdayDate else { return nil }
        return ReflectJournalStore.loadEntries()
            .filter { calendar.isDate($0.date, inSameDayAs: yesterdayDate) }
            .sorted { $0.date > $1.date }
            .first(where: hasJournalContent)
    }

    private var yesterdayJournalExcerpt: String {
        guard let entry = yesterdayJournalEntry else { return "No journal entry from yesterday." }
        let text = journalPreviewText(for: entry)
        return shortenedOverviewExcerpt(text, maxLength: 115)
    }

    private var moodStreakDays: Int {
        guard let latestLoggedDate = latestLoggedMoodDate else { return 0 }
        let today = calendar.startOfDay(for: Date())
        let daysSinceLatest = calendar.dateComponents([.day], from: latestLoggedDate, to: today).day ?? .max

        // Keep streak on the first unlogged day, then reset if another day passes.
        guard daysSinceLatest <= 1 else { return 0 }
        return streakEnding(on: latestLoggedDate)
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

    private func hasJournalContent(_ entry: ReflectJournalEntry) -> Bool {
        !entry.promptResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !entry.journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func journalPreviewText(for entry: ReflectJournalEntry) -> String {
        let journalBody = entry.journalText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !journalBody.isEmpty { return journalBody }

        let response = entry.promptResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if !response.isEmpty {
            return ReflectJournalPrompt.filledPromptString(entry.prompt, with: response)
        }
        return ReflectJournalPrompt.displayPrompt(entry.prompt)
    }

    private func shortenedOverviewExcerpt(_ text: String, maxLength: Int) -> String {
        let condensed = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard condensed.count > maxLength else { return condensed }
        let cutoffIndex = condensed.index(condensed.startIndex, offsetBy: maxLength)
        let leadingChunk = String(condensed[..<cutoffIndex])
        if let lastWordBoundary = leadingChunk.lastIndex(where: \.isWhitespace) {
            let trimmed = leadingChunk[..<lastWordBoundary].trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return "\(trimmed)..."
            }
        }
        return "\(leadingChunk)..."
    }

    private func openYesterdayJournalEntry() {
        guard let yesterdayDate else { return }
        journalDeepLinkDate = yesterdayDate
        journalDeepLinkToken = UUID()
        selectedLandingSection = .journal
    }

    private var journalPreviewText: String {
        ReflectJournalPrompt.filledPromptString(journalPrompt, with: journalPromptResponse)
    }

    private var past7DayMoodScores: [CGFloat] {
        _ = moodLevelsRefreshTick
        let today = calendar.startOfDay(for: Date())
        let fallbackLevels: [MoodLevelState] = [
            .init(label: "stress", value: 0.5),
            .init(label: "fun", value: 0.5),
            .init(label: "laziness", value: 0.5),
            .init(label: "inspired", value: 0.5)
        ]

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -6 + offset, to: today) else {
                return CGFloat(3)
            }
            let key = ReflectDateKey(date: date, calendar: calendar)
            guard ReflectMoodLevelStore.hasLevels(for: key) else { return CGFloat(3) }
            let levels = ReflectMoodLevelStore.loadLevels(for: key, defaults: fallbackLevels)
            return moodScore(from: levels)
        }
    }

    private var past7DayDriftHours: [CGFloat] {
        _ = moodLevelsRefreshTick
        let today = calendar.startOfDay(for: Date())
        let fallbackLevels: [MoodLevelState] = [
            .init(label: "stress", value: 0.5),
            .init(label: "fun", value: 0.5),
            .init(label: "laziness", value: 0.5),
            .init(label: "inspired", value: 0.5)
        ]

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -6 + offset, to: today) else {
                return CGFloat(3)
            }
            let key = ReflectDateKey(date: date, calendar: calendar)
            let levels = ReflectMoodLevelStore.loadLevels(for: key, defaults: fallbackLevels)
            return driftHours(from: levels)
        }
    }

    private func moodScore(from levels: [MoodLevelState]) -> CGFloat {
        let stress = levelValue(for: "stress", in: levels)
        let fun = levelValue(for: "fun", in: levels)
        let laziness = levelValue(for: "laziness", in: levels)
        let inspired = levelValue(for: "inspired", in: levels)

        let normalized = (((fun + inspired) - (stress + laziness)) + 2) / 4
        let clamped = min(max(normalized, 0), 1)
        return CGFloat(1 + (4 * (1 - clamped)))
    }

    private func levelValue(for label: String, in levels: [MoodLevelState]) -> Double {
        levels.first(where: { $0.label.caseInsensitiveCompare(label) == .orderedSame })?.value ?? 0.5
    }

    private func driftHours(from levels: [MoodLevelState]) -> CGFloat {
        let stress = CGFloat(levelValue(for: "stress", in: levels))
        let laziness = CGFloat(levelValue(for: "laziness", in: levels))
        let fun = CGFloat(levelValue(for: "fun", in: levels))
        let inspired = CGFloat(levelValue(for: "inspired", in: levels))

        let driftSignal = (0.46 * stress) + (0.32 * laziness) + (0.14 * (1 - fun)) + (0.08 * (1 - inspired))
        let clamped = min(max(driftSignal, 0), 1)
        return 0.5 + (clamped * 4.5)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    Color.clear
                        .frame(height: 0)
                        .id(topScrollID)

                    VStack(spacing: 20) {
                        ReflectHeader()

                        VStack(spacing: 0) {
                            ReflectLandingTabs(selectedSection: selectedLandingSection) { section in
                                selectedLandingSection = section
                            }
                            .padding(.horizontal, 0)
                            .padding(.bottom, -10)
                            .zIndex(0)

                            landingPanelContent
                            .padding(.horizontal, 10)
                            .padding(.top, 28)
                            .padding(.bottom, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.96))
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 3)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(red: 0.9, green: 0.89, blue: 0.8), lineWidth: 1)
                            )
                            .zIndex(1)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 24)
                    .padding(.top, 8)
                    .nomieTabBarContentPadding()
                }
                .scrollDisabled(selectedLandingSection == .dailyMood && isLandingMoodOrbitDragging)
                .background(ReflectTabBackground())
                .onChange(of: selectedLandingSection) { _ in
                    withAnimation(.easeInOut(duration: 0.28)) {
                        proxy.scrollTo(topScrollID, anchor: .top)
                    }
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
        .onReceive(NotificationCenter.default.publisher(for: ReflectMoodLevelStore.didChangeNotification)) { _ in
            moodLevelsRefreshTick += 1
        }
    }

    @ViewBuilder
    private var landingPanelContent: some View {
        switch selectedLandingSection {
        case .overview:
            overviewPanelContent
        case .dailyMood:
            dailyMoodTabContent
        case .journal:
            journalTabContent
        case .patternsTrends:
            patternsTabContent
        }
    }

    private var overviewPanelContent: some View {
        VStack(spacing: 24) {
            dailyMoodOverviewSection
            journalOverviewSection
            patternsOverviewSection
        }
    }

    private var dailyMoodOverviewSection: some View {
        VStack(spacing: 22) {
            ReflectSectionTitle(text: "Daily Mood", leadingAssetName: "planet2")
            HStack(alignment: .top, spacing: 10) {
                Button {
                    selectedLandingSection = .dailyMood
                } label: {
                    ReflectTodayMoodCard(mood: todayMood)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)

                ReflectStreakCard(days: moodStreakDays)
                    .frame(maxWidth: .infinity)
            }

            if let yesterdayMood {
                let reflectionRowHeight: CGFloat = reflectLandingMoodCardHeight
                HStack(alignment: .top, spacing: 10) {
                    ReflectDailyMoodOverviewCard(minHeight: reflectionRowHeight, horizontalPadding: 12) {
                        VStack(alignment: .center, spacing: 10) {
                            Text("Reflect on yesterday:")
                                .font(.custom("SortsMillGoudy-Italic", size: 20))
                                .foregroundStyle(inkColor.opacity(0.92))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .layoutPriority(1)
                                .frame(maxWidth: .infinity, alignment: .center)

                            Text(yesterdayJournalExcerpt)
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundStyle(inkColor.opacity(0.88))
                                .lineSpacing(2)
                                .multilineTextAlignment(.center)
                                .lineLimit(5)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .center)

                            Spacer(minLength: 0)

                            Button {
                                openYesterdayJournalEntry()
                            } label: {
                                ReflectOutlineActionButton(title: "See More")
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .disabled(yesterdayJournalEntry == nil)
                            .opacity(yesterdayJournalEntry == nil ? 0.45 : 1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)

                    ReflectYesterdayMoodSummary(
                        mood: yesterdayMood,
                        alignMoodLabelToBottom: true,
                        minHeight: reflectionRowHeight
                    )
                        .frame(maxWidth: .infinity, alignment: .top)
                }
            }
        }
    }

    private var dailyMoodTabContent: some View {
        DailyMoodView(
            loggedMoods: $loggedMoods,
            isEmbeddedInLanding: true,
            externalIsMoodOrbitDragging: $isLandingMoodOrbitDragging
        )
    }

    private var journalOverviewSection: some View {
        VStack(spacing: 22) {
            ReflectSectionTitle(text: "Journal", leadingAssetName: "planet2")
            Button {
                selectedLandingSection = .journal
            } label: {
                ReflectGradientCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's prompt:")
                            .font(.custom("SortsMillGoudy-Italic", size: 17))
                            .foregroundStyle(inkColor.opacity(0.86))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(journalPreviewText)
                            .font(.custom("SortsMillGoudy-Regular", size: 18))
                            .foregroundStyle(inkColor.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.78)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50, alignment: .center)
                            .padding(.vertical, 2)

                        ReflectActionButton(title: "Log Journal")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var journalTabContent: some View {
        SelfJournalView(
            initialPrompt: journalPrompt,
            onPromptChange: { journalPrompt = $0 },
            onPromptResponseSave: { journalPromptResponse = $0 },
            isEmbeddedInLanding: true,
            externalIsJournalCoverEditing: $isLandingJournalCoverEditing,
            externalPastEntriesJumpDate: $journalDeepLinkDate,
            externalPastEntriesJumpToken: $journalDeepLinkToken
        )
    }

    private var patternsOverviewSection: some View {
        VStack(spacing: 22) {
            ReflectSectionTitle(text: "Trends", leadingAssetName: "planet2")
            VStack(spacing: 14) {
                ReflectPatternsPreviewChart(
                    scores: past7DayMoodScores,
                    driftHours: past7DayDriftHours
                )
                .frame(height: 214)

                Button {
                    selectedLandingSection = .patternsTrends
                } label: {
                    ReflectOutlineActionButton(title: "See More")
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var patternsTabContent: some View {
        PatternsTrendsView(isEmbeddedInLanding: true)
    }

}

struct ReflectHeader: View {
    var body: some View {
        HStack(alignment: .top) {
            Text("Reflect")
                .font(.custom("SortsMillGoudy-Regular", size: 52))
                .foregroundStyle(Color.black.opacity(0.86))
            Spacer()
            Image("planet")
                .resizable()
                .scaledToFit()
                .frame(width: 62, height: 62)
                .opacity(0.92)
                .padding(.trailing, 6)
                .offset(y: -10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReflectSectionTitle: View {
    let text: String
    var leadingAssetName: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let leadingAssetName {
                Image(leadingAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }

            Text(text)
                .font(.custom("SortsMillGoudy-Regular", size: 24))
                .foregroundStyle(Color.black.opacity(0.88))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReflectLandingTabs: View {
    let selectedSection: ReflectLandingSection
    let onSelect: (ReflectLandingSection) -> Void

    var body: some View {
        HStack(spacing: 20) {
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
        .padding(.horizontal, 2)
        .padding(.top, 2)
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct ReflectLandingTabChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.custom("Poppins-Regular", size: 11))
            .foregroundStyle(ReflectPalette.secondaryGreen.opacity(0.96))
            .lineLimit(1)
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .frame(minHeight: 39)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isSelected
                        ? AnyShapeStyle(Color.white.opacity(0.98))
                        : AnyShapeStyle(
                            LinearGradient(
                                stops: [
                                    .init(color: Color(red: 0.97, green: 0.91, blue: 0.74), location: 0.0),
                                    .init(color: Color(red: 0.97, green: 0.86, blue: 0.65), location: 0.62),
                                    .init(color: Color(red: 0.96, green: 0.82, blue: 0.60), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                    .shadow(
                        color: isSelected ? Color.black.opacity(0.08) : Color.black.opacity(0.06),
                        radius: 4,
                        x: 0,
                        y: 3
                    )
                    .shadow(
                        color: Color.white.opacity(isSelected ? 0.55 : 0.25),
                        radius: 0.9,
                        x: 0,
                        y: -0.8
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected
                        ? ReflectPalette.lightGreen.opacity(0.9)
                        : Color.white.opacity(0.72),
                        lineWidth: 1
                    )
            )
    }
}

private struct ReflectActionButton: View {
    let title: String
    var fillHorizontally: Bool = false
    var fontSize: CGFloat = 16
    var verticalPadding: CGFloat = 8
    var horizontalPadding: CGFloat = 20

    var body: some View {
        Group {
            if fillHorizontally {
                buttonLabel
                    .frame(maxWidth: .infinity)
            } else {
                buttonLabel
            }
        }
    }

    private var buttonLabel: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.custom("SortsMillGoudy-Regular", size: fontSize))
                .foregroundStyle(ReflectPalette.primaryGreen)
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.98, green: 0.89, blue: 0.73), location: 0.0),
                            .init(color: Color(red: 0.93, green: 0.91, blue: 0.69), location: 0.55),
                            .init(color: Color(red: 0.88, green: 0.91, blue: 0.70), location: 1.0)
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.68), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 3)
        )
    }
}

private struct ReflectOutlineActionButton: View {
    let title: String
    var fontSize: CGFloat = 16
    var verticalPadding: CGFloat = 8
    var horizontalPadding: CGFloat = 24
    var textColor: Color = Color.black.opacity(0.86)

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.custom("SortsMillGoudy-Regular", size: fontSize))
                .foregroundStyle(textColor)
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(ReflectPalette.lightGreen, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 3)
        )
    }
}

private struct ReflectPatternsPreviewChart: View {
    let scores: [CGFloat]
    let driftHours: [CGFloat]
    private let weekdayAxis = ["M", "T", "W", "T", "F", "S", "S"]
    private let chartHeight: CGFloat = 186

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            leftAxis

            VStack(spacing: 10) {
                chartSurface
                weekdayLabels
            }
            .frame(maxWidth: .infinity)

            rightAxis
        }
    }

    private var leftAxis: some View {
        HStack(spacing: 6) {
            Text("Stress Level")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundStyle(ReflectPalette.secondaryGreen)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)
                .rotationEffect(.degrees(-90))
                .frame(width: 14)

            VStack(alignment: .trailing, spacing: 0) {
                Text("10 (Tense)")
                Spacer(minLength: 0)
                Text("5 (Okay)")
                Spacer(minLength: 0)
                Text("0 (Calm)")
            }
            .font(.custom("Poppins-Regular", size: 11))
            .foregroundStyle(ReflectPalette.secondaryGreen)
        }
        .frame(width: 88, height: chartHeight)
        .padding(.top, 2)
    }

    private var rightAxis: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 0) {
                Text("6hr")
                Spacer(minLength: 0)
                Text("3hr")
                Spacer(minLength: 0)
                Text("0hr")
            }
            .font(.custom("Poppins-Regular", size: 11))
            .foregroundStyle(ReflectPalette.secondaryGreen)

            Text("Drift Hours")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundStyle(ReflectPalette.secondaryGreen)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)
                .rotationEffect(.degrees(90))
                .frame(width: 14)
        }
        .frame(width: 56, height: chartHeight)
        .padding(.top, 2)
    }

    private var chartSurface: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let points = chartPoints(in: size)
            let barWidth = barWidth(for: size.width, pointCount: chartValues.count)
            let driftData = alignedDriftValues(for: chartValues.count)

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ReflectPalette.warmWhite.opacity(0.82))

                ForEach(points.indices, id: \.self) { idx in
                    let x = points[idx].x
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: ReflectPalette.lightGreen.opacity(0.60), location: 0.0),
                                    .init(color: ReflectPalette.warmWhite.opacity(0.38), location: 0.45),
                                    .init(color: ReflectPalette.lightBrown.opacity(0.54), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(ReflectPalette.secondaryGreen.opacity(0.22), lineWidth: 1)
                        )
                        .frame(width: barWidth, height: size.height)
                        .position(x: x, y: size.height / 2)
                }

                ForEach(points.indices, id: \.self) { idx in
                    let driftValue = driftData[idx]
                    let x = points[idx].x
                    let topY = driftYPosition(for: driftValue, in: size.height)
                    let height = max(size.height - topY, 6)
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: ReflectPalette.lightGreen.opacity(0.78), location: 0.0),
                                    .init(color: Color(red: 0.98, green: 0.78, blue: 0.50).opacity(0.93), location: 0.62),
                                    .init(color: Color(red: 0.95, green: 0.63, blue: 0.38).opacity(0.98), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.40), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)
                        .frame(width: barWidth, height: height)
                        .position(x: x, y: topY + (height / 2))
                }

                ForEach(points.indices, id: \.self) { idx in
                    Path { path in
                        path.move(to: CGPoint(x: points[idx].x, y: 0))
                        path.addLine(to: CGPoint(x: points[idx].x, y: size.height))
                    }
                    .stroke(ReflectPalette.secondaryGreen.opacity(0.16), lineWidth: 1)
                }

                horizontalGridLine(at: yPosition(for: 5, in: size.height), in: size, opacity: 0.22)
                horizontalGridLine(at: yPosition(for: 3, in: size.height), in: size, opacity: 0.18)
                horizontalGridLine(at: yPosition(for: 1, in: size.height), in: size, opacity: 0.2)

                if points.count > 1 {
                    areaPath(from: points, in: size)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: ReflectPalette.lightGreen.opacity(0.18), location: 0.0),
                                    .init(color: Color(red: 0.98, green: 0.77, blue: 0.47).opacity(0.22), location: 0.58),
                                    .init(color: Color(red: 0.96, green: 0.64, blue: 0.42).opacity(0.30), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    smoothedLinePath(from: points)
                        .stroke(Color(red: 0.96, green: 0.63, blue: 0.36).opacity(0.84), lineWidth: 2)

                    ForEach(points.indices, id: \.self) { idx in
                        Circle()
                            .fill(Color(red: 0.98, green: 0.66, blue: 0.30))
                            .frame(width: 7, height: 7)
                            .position(points[idx])
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(height: chartHeight)
    }

    private var weekdayLabels: some View {
        GeometryReader { proxy in
            let labels = xAxisLabels
            ZStack {
                ForEach(labels.indices, id: \.self) { index in
                    Text(labels[index])
                        .font(.custom("Poppins-Regular", size: 10))
                        .foregroundStyle(ReflectPalette.secondaryGreen)
                        .position(
                            x: chartXPosition(for: index, in: proxy.size.width, pointCount: labels.count),
                            y: 9
                        )
                }
            }
        }
        .frame(height: 18)
    }

    private var chartValues: [CGFloat] {
        let cleaned = scores.map { min(max($0, 1), 5) }
        return cleaned.isEmpty ? [3, 3, 3, 3, 3, 3, 3] : cleaned
    }

    private func alignedDriftValues(for count: Int) -> [CGFloat] {
        let cleaned = driftHours.map { min(max($0, 0), 6) }
        if cleaned.count == count {
            return cleaned
        }
        if cleaned.isEmpty {
            return Array(repeating: 3.0, count: count)
        }
        if cleaned.count > count {
            return Array(cleaned.suffix(count))
        }
        return Array(repeating: cleaned.first ?? 3.0, count: count - cleaned.count) + cleaned
    }

    private var xAxisLabels: [String] {
        let count = max(chartValues.count, 2)
        if count == weekdayAxis.count {
            return weekdayAxis
        }
        if count < weekdayAxis.count {
            return Array(weekdayAxis.suffix(count))
        }
        return (1...count).map { "\($0)" }
    }

    private func chartPoints(in size: CGSize) -> [CGPoint] {
        guard chartValues.count > 1 else { return [] }
        return chartValues.enumerated().map { index, value in
            CGPoint(
                x: chartXPosition(for: index, in: size.width, pointCount: chartValues.count),
                y: yPosition(for: value, in: size.height)
            )
        }
    }

    private func chartXPosition(for index: Int, in width: CGFloat, pointCount: Int) -> CGFloat {
        guard pointCount > 1 else { return width / 2 }
        let inset: CGFloat = 14
        let usableWidth = max(width - (inset * 2), 0)
        let step = usableWidth / CGFloat(pointCount - 1)
        return inset + (step * CGFloat(index))
    }

    private func barWidth(for width: CGFloat, pointCount: Int) -> CGFloat {
        let inset: CGFloat = 14
        let usableWidth = max(width - (inset * 2), 0)
        guard pointCount > 1 else { return usableWidth * 0.7 }
        let slot = usableWidth / CGFloat(pointCount)
        return min(52, max(24, slot * 0.78))
    }

    private func driftYPosition(for value: CGFloat, in height: CGFloat) -> CGFloat {
        let clamped = min(max(value, 0), 6)
        let normalized = clamped / 6
        return height * (1 - normalized)
    }

    private func yPosition(for value: CGFloat, in height: CGFloat) -> CGFloat {
        let clamped = min(max(value, 1), 5)
        let normalized = (clamped - 1) / 4
        return height * (1 - normalized)
    }

    private func horizontalGridLine(at y: CGFloat, in size: CGSize, opacity: Double) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }
        .stroke(ReflectPalette.secondaryGreen.opacity(opacity), lineWidth: 1)
    }

    private func smoothedLinePath(from points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        guard points.count > 1 else { return path }

        for idx in 0..<(points.count - 1) {
            let p0 = idx > 0 ? points[idx - 1] : points[idx]
            let p1 = points[idx]
            let p2 = points[idx + 1]
            let p3 = idx + 2 < points.count ? points[idx + 2] : p2

            let control1 = CGPoint(
                x: p1.x + ((p2.x - p0.x) / 6),
                y: p1.y + ((p2.y - p0.y) / 6)
            )
            let control2 = CGPoint(
                x: p2.x - ((p3.x - p1.x) / 6),
                y: p2.y - ((p3.y - p1.y) / 6)
            )

            path.addCurve(to: p2, control1: control1, control2: control2)
        }

        return path
    }

    private func areaPath(from points: [CGPoint], in size: CGSize) -> Path {
        var path = Path()
        guard let first = points.first, let last = points.last else { return path }
        path.move(to: CGPoint(x: first.x, y: size.height))
        path.addLine(to: first)

        for idx in 0..<(points.count - 1) {
            let p0 = idx > 0 ? points[idx - 1] : points[idx]
            let p1 = points[idx]
            let p2 = points[idx + 1]
            let p3 = idx + 2 < points.count ? points[idx + 2] : p2

            let control1 = CGPoint(
                x: p1.x + ((p2.x - p0.x) / 6),
                y: p1.y + ((p2.y - p0.y) / 6)
            )
            let control2 = CGPoint(
                x: p2.x - ((p3.x - p1.x) / 6),
                y: p2.y - ((p3.y - p1.y) / 6)
            )

            path.addCurve(to: p2, control1: control1, control2: control2)
        }

        path.addLine(to: CGPoint(x: last.x, y: size.height))
        path.closeSubpath()
        return path
    }
}

private struct ReflectDailyMoodOverviewCard<Content: View>: View {
    let minHeight: CGFloat
    var horizontalPadding: CGFloat = 10
    var verticalPadding: CGFloat = 14
    let content: Content

    init(
        minHeight: CGFloat,
        horizontalPadding: CGFloat = 10,
        verticalPadding: CGFloat = 14,
        @ViewBuilder content: () -> Content
    ) {
        self.minHeight = minHeight
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.content = content()
    }

    var body: some View {
        content
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: minHeight, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
    }
}

struct ReflectTodayMoodCard: View {
    let mood: ReflectMoodOption?

    var body: some View {
        ReflectDailyMoodOverviewCard(minHeight: reflectLandingMoodCardHeight, horizontalPadding: 10) {
            VStack(spacing: 12) {
                Text("Today's mood:")
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

                ReflectActionButton(title: "Log Mood", fillHorizontally: true)
            }
        }
    }
}

struct ReflectStreakCard: View {
    let days: Int

    var body: some View {
        ReflectDailyMoodOverviewCard(minHeight: reflectLandingMoodCardHeight, horizontalPadding: 12) {
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image("Streak")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .offset(y: -3)

                    Text("Streak")
                        .font(.custom("SortsMillGoudy-Regular", size: 20))
                        .foregroundStyle(Color.black.opacity(0.9))
                }

                Text("\(days)")
                    .font(.custom("Poppins-SemiBold", size: 68))
                    .foregroundStyle(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.98, green: 0.53, blue: 0.42), location: 0.02),
                                .init(color: Color(red: 0.97, green: 0.66, blue: 0.38), location: 0.48),
                                .init(color: Color(red: 0.90, green: 0.72, blue: 0.36), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("Days")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundStyle(Color.black.opacity(0.9))

                if days > 0 {
                    Text("Keep it up!")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(Color.black.opacity(0.7))
                        .padding(.top, 2)
                }
            }
        }
    }

}

struct ReflectYesterdayMoodSummary: View {
    let mood: ReflectMoodOption
    var alignMoodLabelToBottom: Bool = false
    var minHeight: CGFloat? = nil

    var body: some View {
        ReflectDailyMoodOverviewCard(minHeight: minHeight ?? reflectLandingMoodCardHeight, horizontalPadding: 10) {
            VStack(spacing: 8) {
                Text("Yesterday's mood:")
                    .font(.custom("SortsMillGoudy-Italic", size: 20))
                    .foregroundStyle(Color.black.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .center)

                MoodAssetImage(assetName: mood.assetName, intensity: 0.85)
                    .frame(width: 122, height: 122)

                if alignMoodLabelToBottom {
                    Spacer(minLength: 0)
                }

                Text(mood.name)
                    .font(.custom("Poppins-Regular", size: 18))
                    .foregroundStyle(Color.black.opacity(0.88))
            }
        }
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
                    .fill(accentColor.opacity(0.22))
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
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 3)
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
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 3)
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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 3)
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
                    .fill(Color.white.opacity(0.92))
                    .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 3)
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
                    .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 3)
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
                            .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 3)
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
    var isEmbeddedInLanding: Bool = false
    var externalIsMoodOrbitDragging: Binding<Bool>? = nil
    @State private var selectedMoodIndex: Int? = nil
    @State private var isMoodOrbitDragging = false
    @State private var moodLevels: [MoodLevelState] = [
        .init(label: "stress", value: 0.5),
        .init(label: "laziness", value: 0.25),
        .init(label: "fun", value: 0.5),
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
        Group {
            if isEmbeddedInLanding {
                VStack(spacing: 28) {
                    dailyMoodCoreContent
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 28) {
                            dailyMoodCoreContent
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 22)
                        .padding(.bottom, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.96))
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(red: 0.9, green: 0.89, blue: 0.8), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                    .nomieTabBarContentPadding()
                }
                .background(ReflectTabBackground())
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
                .scrollDisabled(isMoodOrbitDragging)
            }
        }
        .onAppear {
            moodLevels = orderedMoodLevels(
                ReflectMoodLevelStore.loadLevels(for: todayKey, defaults: moodLevels)
            )
            externalIsMoodOrbitDragging?.wrappedValue = false
        }
        .onChange(of: moodLevels) { _ in
            ReflectMoodLevelStore.saveLevels(moodLevels, for: todayKey)
        }
        .onChange(of: isMoodOrbitDragging) { dragging in
            externalIsMoodOrbitDragging?.wrappedValue = dragging
        }
        .onDisappear {
            externalIsMoodOrbitDragging?.wrappedValue = false
        }
    }

    private var dailyMoodCoreContent: some View {
        Group {
            if !isEmbeddedInLanding {
                Text("Daily Mood")
                    .font(.custom("SortsMillGoudy-Regular", size: 28))
                    .foregroundStyle(Color.black.opacity(0.92))
            }

            Text("How was your overall mood today?")
                .font(.custom("SortsMillGoudy-Italic", size: 17))
                .foregroundStyle(Color.black.opacity(0.95))
                .multilineTextAlignment(.center)

            MoodOrbitPicker(
                selectedMoodIndex: $selectedMoodIndex,
                isDragging: $isMoodOrbitDragging,
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
                                    .font(.custom("Poppins-SemiBold", size: 11))
                                    .foregroundStyle(ReflectPalette.primaryGreen.opacity(0.98))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                                Text(day.dateLabel)
                                    .font(.custom("Poppins-Regular", size: 10))
                                    .foregroundStyle(Color.black.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }

            ReflectSectionTitle(text: "Mood Levels", leadingAssetName: "planet2")

            ReflectTodayGradientCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How much did you experience each of these moods today?")
                        .font(.custom("SortsMillGoudy-Italic", size: 18))
                        .foregroundStyle(Color.black.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
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

            ReflectSectionTitle(text: "Past Moods", leadingAssetName: "planet2")
                .padding(.top, 8)

            ReflectTodayGradientCard {
                VStack(spacing: 12) {
                    HStack(spacing: 14) {
                        Button {
                            triggerArrowHaptic()
                            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 34, height: 34)
                        }

                        Spacer(minLength: 6)
                        Text(monthTitle(currentMonth))
                            .font(.custom("SortsMillGoudy-Italic", size: 24))
                            .foregroundStyle(Color(red: 0.18, green: 0.08, blue: 0.08))
                        Spacer(minLength: 6)

                        Button {
                            triggerArrowHaptic()
                            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 34, height: 34)
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
                        let calendarCellHeight: CGFloat = 42
                        ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                            Group {
                                if day == 0 {
                                    Color.clear
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
                            .frame(maxWidth: .infinity, minHeight: calendarCellHeight, maxHeight: calendarCellHeight, alignment: .top)
                        }
                    }
                }
            }
            .padding(.bottom, 8)

            if !mostExperiencedMoods.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    ReflectSectionTitle(text: "Most Experienced Moods", leadingAssetName: "planet2")

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
                .padding(.top, 8)
            }
        }
    }

    private func logMood(_ mood: ReflectMoodOption) {
        let key = ReflectDateKey(date: Date(), calendar: calendar)
        loggedMoods[key] = mood
    }

    private func orderedMoodLevels(_ levels: [MoodLevelState]) -> [MoodLevelState] {
        let order = ["stress", "laziness", "fun", "inspired"]
        let lookup = Dictionary(
            uniqueKeysWithValues: levels.map { ($0.label.lowercased(), $0) }
        )
        return order.map { label in
            lookup[label] ?? MoodLevelState(label: label, value: 0.5)
        }
    }

    private func last7Days() -> [ReflectMoodDayDisplay] {
        let today = calendar.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M.d"
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: "en_US_POSIX")
        weekdayFormatter.dateFormat = "EEE"

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -6 + offset, to: today) else { return nil }
            let key = ReflectDateKey(date: date, calendar: calendar)
            let mood = loggedMoods[key]
            return ReflectMoodDayDisplay(
                dayLabel: weekdayFormatter.string(from: date).uppercased(),
                dateLabel: dateFormatter.string(from: date),
                mood: mood
            )
        }
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
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 3)
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
            MoodAssetImage(assetName: mood.assetName, intensity: isSelected ? 0.85 : 0.7)
                .frame(width: size, height: size)
                .scaleEffect(isSelected ? 1.08 : 1.0)
                .overlay {
                    if isSelected {
                        Circle()
                            .stroke(
                                ReflectPalette.lightGreen,
                                style: StrokeStyle(lineWidth: 1.4, dash: [4, 3])
                            )
                            .padding(-7)
                    }
                }
                .animation(.easeOut(duration: 0.16), value: isSelected)

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
    @Binding var isDragging: Bool
    let onSelect: (Int) -> Void
    @State private var feedbackGenerator = UISelectionFeedbackGenerator()
    @State private var impactGenerator = UIImpactFeedbackGenerator(style: .soft)

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
                            .font(.custom("SortsMillGoudy-Regular", size: 14))
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
                        selectMood(at: idx)
                    } label: {
                        MoodSelectorPreview(
                            mood: mood,
                            size: 54,
                            isSelected: idx == selectedMoodIndex,
                            showLabel: false
                        )
                        .frame(width: 76, height: 76)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .position(x: center.x + offset.x, y: center.y + offset.y)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                            impactGenerator.impactOccurred(intensity: 0.65)
                            impactGenerator.prepare()
                        }
                        guard let nearestIndex = nearestMoodIndex(
                            to: gesture.location,
                            center: center,
                            positions: positions
                        ) else { return }
                        selectMood(at: nearestIndex)
                    }
                    .onEnded { _ in
                        impactGenerator.impactOccurred(intensity: 0.45)
                        impactGenerator.prepare()
                        isDragging = false
                    }
            )
            .onAppear {
                feedbackGenerator.prepare()
                impactGenerator.prepare()
            }
            .onDisappear {
                isDragging = false
            }
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

    private func nearestMoodIndex(to point: CGPoint, center: CGPoint, positions: [CGPoint]) -> Int? {
        guard !positions.isEmpty else { return nil }
        var nearest: (index: Int, distance: CGFloat)?
        for idx in ReflectMoodOption.moods.indices {
            let offset = positions[idx % positions.count]
            let moodCenter = CGPoint(x: center.x + offset.x, y: center.y + offset.y)
            let distance = hypot(point.x - moodCenter.x, point.y - moodCenter.y)
            if nearest == nil || distance < nearest!.distance {
                nearest = (index: idx, distance: distance)
            }
        }

        guard let nearest, nearest.distance <= 70 else { return nil }
        return nearest.index
    }

    private func selectMood(at index: Int) {
        guard ReflectMoodOption.moods.indices.contains(index) else { return }
        guard selectedMoodIndex != index else { return }
        selectedMoodIndex = index
        onSelect(index)
        feedbackGenerator.selectionChanged()
        feedbackGenerator.prepare()
        impactGenerator.impactOccurred(intensity: 0.8)
        impactGenerator.prepare()
    }
}



struct PatternsTrendsView: View {
    private let inkColor = ReflectPalette.brown
    private let sectionTitleSize: CGFloat = 24
    private let bodyFontSize: CGFloat = 14
    private let calendar = Calendar.current
    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    @Environment(\.dismiss) private var dismiss
    @State private var journalEntries: [ReflectJournalEntry] = []
    @State private var moodLevelsRefreshTick: Int = 0
    var isEmbeddedInLanding: Bool = false

    private struct AnalyticsExcerpt: Identifiable {
        let id: UUID
        let text: String
        let weekday: String
    }

    private struct MoodDayMetrics {
        let date: Date
        let stress: CGFloat
        let fun: CGFloat
        let inspired: CGFloat
        let tenseScore: CGFloat
        let driftHours: CGFloat
    }

    var body: some View {
        Group {
            if isEmbeddedInLanding {
                patternsPageContent
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
            } else {
                ScrollView {
                    patternsPageContent
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .nomieTabBarContentPadding()
                }
                .background(ReflectTabBackground())
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
            }
        }
        .onAppear {
            journalEntries = normalizeEntries(ReflectJournalStore.loadEntries())
        }
        .onReceive(NotificationCenter.default.publisher(for: ReflectMoodLevelStore.didChangeNotification)) { _ in
            moodLevelsRefreshTick += 1
        }
    }

    private var patternsPageContent: some View {
        VStack(alignment: .leading, spacing: 30) {
            if !isEmbeddedInLanding {
                VStack(spacing: 10) {
                    Text("Trends")
                        .font(.custom("SortsMillGoudy-Regular", size: 28))
                        .foregroundStyle(Color.black.opacity(0.92))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }

            TrendsMoodAnalyticsCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image("planet2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text("Mood Levels")
                            .font(.custom("SortsMillGoudy-Regular", size: sectionTitleSize))
                            .foregroundStyle(inkColor.opacity(0.92))
                    }

                    ReflectPatternsPreviewChart(
                        scores: trendGraphScores,
                        driftHours: past7DayDriftHours
                    )
                    .frame(height: 214)
                }
            }

            TrendsMoodAnalyticsCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image("planet2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text("Analytics")
                            .font(.custom("SortsMillGoudy-Regular", size: sectionTitleSize))
                            .foregroundStyle(inkColor.opacity(0.95))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(analyticsInsightLines.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.custom("AvenirNext-Regular", size: bodyFontSize))
                                    .foregroundStyle(inkColor.opacity(0.85))
                                analyticsInsightText(analyticsInsightLines[index])
                                    .foregroundStyle(inkColor.opacity(0.86))
                            }
                        }
                    }

                    if analyticsExcerpts.isEmpty {
                        Text(emptyAnalyticsText)
                            .font(.custom("AvenirNext-Regular", size: bodyFontSize))
                            .foregroundStyle(inkColor.opacity(0.62))
                            .padding(.top, 2)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(analyticsExcerpts) { excerpt in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.custom("AvenirNext-Regular", size: bodyFontSize))
                                        .foregroundStyle(inkColor.opacity(0.85))
                                    Text("\"\(excerpt.text)\" — \(excerpt.weekday)")
                                        .font(.custom("AvenirNext-Regular", size: bodyFontSize))
                                        .foregroundStyle(inkColor.opacity(0.86))
                                        .lineLimit(2)
                                        .truncationMode(.tail)
                                }
                            }
                        }
                    }
                }
            }

            ReflectPatternsGradientCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image("planet2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text("Suggestions")
                            .font(.custom("SortsMillGoudy-Regular", size: sectionTitleSize))
                            .foregroundStyle(inkColor.opacity(0.95))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(suggestionLines.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.custom("AvenirNext-Regular", size: bodyFontSize))
                                    .foregroundStyle(inkColor.opacity(0.85))
                                Text(suggestionLines[index])
                                    .font(.custom("AvenirNext-Regular", size: bodyFontSize))
                                    .foregroundStyle(inkColor.opacity(0.88))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var trackedMoodMetrics: [MoodDayMetrics] {
        past7DayDates.compactMap { date in
            let key = ReflectDateKey(date: date, calendar: calendar)
            guard ReflectMoodLevelStore.hasLevels(for: key) else { return nil }

            let defaults: [MoodLevelState] = [
                .init(label: "stress", value: 0.5),
                .init(label: "laziness", value: 0.5),
                .init(label: "fun", value: 0.5),
                .init(label: "inspired", value: 0.5)
            ]
            let levels = ReflectMoodLevelStore.loadLevels(for: key, defaults: defaults)
            return MoodDayMetrics(
                date: date,
                stress: CGFloat(levelValue(for: "stress", in: levels)),
                fun: CGFloat(levelValue(for: "fun", in: levels)),
                inspired: CGFloat(levelValue(for: "inspired", in: levels)),
                tenseScore: moodScore(for: date),
                driftHours: driftHours(from: levels)
            )
        }
    }

    private var analyticsInsightLines: [String] {
        let metrics = trackedMoodMetrics
        guard metrics.count >= 3 else {
            return ["Log mood levels on at least 3 days to unlock percentage-based analytics."]
        }

        var lines: [String] = []

        let anxiousDays = metrics.filter { $0.stress >= 0.6 }
        let lowerStressDays = metrics.filter { $0.stress < 0.6 }
        if !anxiousDays.isEmpty && !lowerStressDays.isEmpty {
            let tenseChange = percentageChange(
                from: average(lowerStressDays.map(\.tenseScore)),
                to: average(anxiousDays.map(\.tenseScore))
            )
            let driftChange = percentageChange(
                from: average(lowerStressDays.map(\.driftHours)),
                to: average(anxiousDays.map(\.driftHours))
            )
            let tenseText = tenseChange >= 0 ? "\(abs(tenseChange))% more tense" : "\(abs(tenseChange))% calmer"
            let driftText = driftChange >= 0 ? "\(abs(driftChange))% higher drift hours" : "\(abs(driftChange))% lower drift hours"
            lines.append("On more anxious days, you were \(tenseText) with \(driftText).")
        }

        let happierDays = metrics.filter { (($0.fun + $0.inspired) / 2) >= 0.6 }
        let lowerHappyDays = metrics.filter { (($0.fun + $0.inspired) / 2) < 0.6 }
        if !happierDays.isEmpty && !lowerHappyDays.isEmpty {
            let calmOnHappier = average(happierDays.map { 6 - $0.tenseScore })
            let calmOnLowerHappy = average(lowerHappyDays.map { 6 - $0.tenseScore })
            let calmChange = percentageChange(from: calmOnLowerHappy, to: calmOnHappier)
            let driftChange = percentageChange(
                from: average(lowerHappyDays.map(\.driftHours)),
                to: average(happierDays.map(\.driftHours))
            )
            let calmText = calmChange >= 0 ? "\(abs(calmChange))% more calm" : "\(abs(calmChange))% less calm"
            let driftText = driftChange <= 0 ? "\(abs(driftChange))% lower drift hours" : "\(abs(driftChange))% higher drift hours"
            lines.append("On happier days, you felt \(calmText) and had \(driftText).")
        }

        if lines.isEmpty {
            let moodAvg = average(metrics.map(\.tenseScore))
            let driftAvg = average(metrics.map(\.driftHours))
            lines.append("From your \(metrics.count) logged days, mood averaged \(String(format: "%.1f", moodAvg))/5 and drift was about \(String(format: "%.1f", driftAvg))h.")
        }

        return Array(lines.prefix(2))
    }

    private func analyticsInsightText(_ line: String) -> Text {
        let pattern = #"(?i)\b(?:anxious|happier|happy|tense|calm|calmer)\b|\d+(?:\.\d+)?%"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return Text(line).font(.custom("AvenirNext-Regular", size: bodyFontSize))
        }

        let nsRange = NSRange(line.startIndex..., in: line)
        let matches = regex.matches(in: line, options: [], range: nsRange)
        guard !matches.isEmpty else {
            return Text(line).font(.custom("AvenirNext-Regular", size: bodyFontSize))
        }

        var cursor = line.startIndex
        var output = Text("")

        for match in matches {
            guard let range = Range(match.range, in: line) else { continue }
            if cursor < range.lowerBound {
                output = output + Text(String(line[cursor..<range.lowerBound]))
                    .font(.custom("AvenirNext-Regular", size: bodyFontSize))
            }
            output = output + Text(String(line[range]))
                .font(.custom("AvenirNext-DemiBold", size: bodyFontSize))
            cursor = range.upperBound
        }

        if cursor < line.endIndex {
            output = output + Text(String(line[cursor...]))
                .font(.custom("AvenirNext-Regular", size: bodyFontSize))
        }

        return output
    }

    private var emptyAnalyticsText: String {
        "No journal entries found in the past 7 days."
    }

    private var analyticsExcerpts: [AnalyticsExcerpt] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return filteredEntries.prefix(3).map { entry in
            AnalyticsExcerpt(
                id: entry.id,
                text: meaningfulExcerpt(from: entry),
                weekday: formatter.string(from: entry.date)
            )
        }
    }

    private var filteredEntries: [ReflectJournalEntry] {
        let today = calendar.startOfDay(for: Date())
        let contentEntries = journalEntries.filter(hasJournalContent)
        guard let start = calendar.date(byAdding: .day, value: -6, to: today) else { return [] }
        return contentEntries.filter { entry in
            let day = calendar.startOfDay(for: entry.date)
            return day >= start && day <= today
        }
    }

    private var trendGraphScores: [CGFloat] {
        _ = moodLevelsRefreshTick
        return scoresForPastDays(7)
    }

    private var past7DayDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -6 + offset, to: today)
        }
    }

    private var past7DayDriftHours: [CGFloat] {
        _ = moodLevelsRefreshTick
        return past7DayDates.map(driftHours(for:))
    }

    private func scoresForPastDays(_ dayCount: Int) -> [CGFloat] {
        let today = calendar.startOfDay(for: Date())
        return (0..<dayCount).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(dayCount - 1) + offset, to: today) else {
                return CGFloat(3)
            }
            return moodScore(for: date)
        }
    }

    private func moodScore(for date: Date) -> CGFloat {
        let key = ReflectDateKey(date: date, calendar: calendar)
        let defaults: [MoodLevelState] = [
            .init(label: "stress", value: 0.5),
            .init(label: "laziness", value: 0.5),
            .init(label: "fun", value: 0.5),
            .init(label: "inspired", value: 0.5)
        ]
        guard ReflectMoodLevelStore.hasLevels(for: key) else { return 3 }
        let levels = ReflectMoodLevelStore.loadLevels(for: key, defaults: defaults)

        let stress = levelValue(for: "stress", in: levels)
        let laziness = levelValue(for: "laziness", in: levels)
        let fun = levelValue(for: "fun", in: levels)
        let inspired = levelValue(for: "inspired", in: levels)

        let normalized = (((fun + inspired) - (stress + laziness)) + 2) / 4
        let clamped = min(max(normalized, 0), 1)
        return CGFloat(1 + (4 * (1 - clamped)))
    }

    private func levelValue(for label: String, in levels: [MoodLevelState]) -> Double {
        levels.first(where: { $0.label.caseInsensitiveCompare(label) == .orderedSame })?.value ?? 0.5
    }

    private func driftHours(for date: Date) -> CGFloat {
        let key = ReflectDateKey(date: date, calendar: calendar)
        let defaults: [MoodLevelState] = [
            .init(label: "stress", value: 0.5),
            .init(label: "laziness", value: 0.5),
            .init(label: "fun", value: 0.5),
            .init(label: "inspired", value: 0.5)
        ]
        let levels = ReflectMoodLevelStore.loadLevels(for: key, defaults: defaults)
        return driftHours(from: levels)
    }

    private func driftHours(from levels: [MoodLevelState]) -> CGFloat {
        let stress = CGFloat(levelValue(for: "stress", in: levels))
        let laziness = CGFloat(levelValue(for: "laziness", in: levels))
        let fun = CGFloat(levelValue(for: "fun", in: levels))
        let inspired = CGFloat(levelValue(for: "inspired", in: levels))

        let driftSignal = (0.46 * stress) + (0.32 * laziness) + (0.14 * (1 - fun)) + (0.08 * (1 - inspired))
        let clamped = min(max(driftSignal, 0), 1)
        return 0.5 + (clamped * 4.5)
    }

    private func average(_ values: [CGFloat]) -> CGFloat {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / CGFloat(values.count)
    }

    private func percentageChange(from baseline: CGFloat, to value: CGFloat) -> Int {
        guard abs(baseline) > 0.0001 else { return 0 }
        return Int((((value - baseline) / baseline) * 100).rounded())
    }

    private var suggestionLines: [String] {
        let mood = trendGraphScores
        let drift = past7DayDriftHours
        guard mood.count == 7, drift.count == 7 else {
            return ["Log mood levels daily to unlock personalized suggestions for tense/calm and drift-hour patterns."]
        }

        let moodAvg = average(mood)
        let driftAvg = average(drift)
        let moodDelta = mood.last! - mood.first!
        let driftDelta = drift.last! - drift.first!

        let peakDriftIndex = drift.enumerated().max(by: { $0.element < $1.element })?.offset ?? 6
        let peakDay = weekdayFormatter.string(from: past7DayDates[peakDriftIndex])
        let roundedTarget = Int(max(1, min(4, (driftAvg - 0.5).rounded())))

        var lines: [String] = []

        if moodAvg >= 3.4 && driftAvg >= 2.7 {
            lines.append("Your week leaned tense and drift usage was higher (\(String(format: "%.1f", driftAvg))h/day). Set a soft cap near \(roundedTarget)h and take a short reset break before late-night app use.")
        } else if moodAvg <= 2.4 && driftAvg <= 2.0 {
            lines.append("You stayed mostly calm with controlled drift time. Keep the same rhythm and protect the hours that felt most focused.")
        } else {
            lines.append("Tense/calm levels were mixed this week. A consistent daily drift window can help keep mood swings from compounding.")
        }

        if moodDelta >= 0.6 || driftDelta >= 0.8 {
            lines.append("Stress signals rose toward the end of the week. Try moving drifting sessions earlier and adding a 10-minute wind-down before bed.")
        } else if moodDelta <= -0.6 && driftDelta <= -0.5 {
            lines.append("Your trend improved through the week with lower drift and calmer mood. Repeat what worked on your best day.")
        } else {
            lines.append("Your highest drift day was \(peakDay). Put a small checkpoint before opening drift-heavy apps on that day next week.")
        }

        return Array(lines.prefix(2))
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
            return shortenExcerpt(journal, maxLength: 72)
        }

        let response = entry.promptResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if !response.isEmpty {
            return shortenExcerpt(ReflectJournalPrompt.filledPromptString(entry.prompt, with: response), maxLength: 72)
        }

        return shortenExcerpt(ReflectJournalPrompt.displayPrompt(entry.prompt), maxLength: 72)
    }

    private func hasJournalContent(_ entry: ReflectJournalEntry) -> Bool {
        let journal = entry.journalText.trimmingCharacters(in: .whitespacesAndNewlines)
        let response = entry.promptResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        return !journal.isEmpty || !response.isEmpty
    }

    private func shortenExcerpt(_ text: String, maxLength: Int = 110) -> String {
        let condensed = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard condensed.count > maxLength else { return condensed }
        let cutIndex = condensed.index(condensed.startIndex, offsetBy: maxLength)
        let candidate = String(condensed[..<cutIndex])
        if let lastWhitespace = candidate.lastIndex(where: { $0.isWhitespace }) {
            let wordSafe = String(candidate[..<lastWhitespace]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !wordSafe.isEmpty {
                return wordSafe
            }
        }
        return candidate.trimmingCharacters(in: .whitespacesAndNewlines)
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
                .fill(accentColor.opacity(0.22))
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
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 3)
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
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
    }
}

struct TrendsMoodAnalyticsCard<Content: View>: View {
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
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 3)
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
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 3)

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
    @State private var selectedEntryID: UUID? = nil
    @FocusState private var isEntryFocused: Bool
    private let today = Date()
    private let calendar = Calendar.current
    private let entryHint = "Keep it short"
    private let tabBarColor = ReflectPalette.warmWhite
    private let inkColor = ReflectPalette.brown
    private let accentColor = ReflectPalette.primaryGreen
    private let onPromptChange: (String) -> Void
    private let onPromptResponseSave: (String) -> Void
    private let isEmbeddedInLanding: Bool
    private let externalIsJournalCoverEditing: Binding<Bool>?
    private let externalPastEntriesJumpDate: Binding<Date?>?
    private let externalPastEntriesJumpToken: Binding<UUID?>?
    @Environment(\.dismiss) private var dismiss

    init(
        initialPrompt: String,
        onPromptChange: @escaping (String) -> Void,
        onPromptResponseSave: @escaping (String) -> Void,
        isEmbeddedInLanding: Bool = false,
        externalIsJournalCoverEditing: Binding<Bool>? = nil,
        externalPastEntriesJumpDate: Binding<Date?>? = nil,
        externalPastEntriesJumpToken: Binding<UUID?>? = nil
    ) {
        _prompt = State(initialValue: initialPrompt)
        self.onPromptChange = onPromptChange
        self.onPromptResponseSave = onPromptResponseSave
        self.isEmbeddedInLanding = isEmbeddedInLanding
        self.externalIsJournalCoverEditing = externalIsJournalCoverEditing
        self.externalPastEntriesJumpDate = externalPastEntriesJumpDate
        self.externalPastEntriesJumpToken = externalPastEntriesJumpToken
    }

    var body: some View {
        Group {
            if isEmbeddedInLanding {
                journalPageContent
                    .padding(.horizontal, 0)
                    .padding(.vertical, 4)
            } else {
                ScrollView {
                    journalPageContent
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .nomieTabBarContentPadding()
                }
                .background(ReflectTabBackground())
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
            }
        }
        .onAppear {
            if journalEntries.isEmpty {
                journalEntries = normalizeEntries(ReflectJournalStore.loadEntries())
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
        .onChange(of: prompt) { _ in
            upsertPromptForToday()
        }
        .onDisappear {
            externalIsJournalCoverEditing?.wrappedValue = false
        }
    }

    private var journalPageContent: some View {
        VStack(spacing: 30) {
            if !isEmbeddedInLanding {
                VStack(spacing: 10) {
                    Text("Self-Journal")
                        .font(.custom("SortsMillGoudy-Regular", size: 28))
                        .foregroundStyle(Color.black.opacity(0.92))

                    Text("Today • \(ReflectJournalPrompt.dateLabel(today))")
                        .font(.custom("AvenirNext-Medium", size: 11))
                        .foregroundStyle(inkColor.opacity(0.55))
                }
                .frame(maxWidth: .infinity)
            }

            ReflectGradientCard {
                VStack(spacing: 12) {
                    HStack(alignment: .center, spacing: 10) {
                        Text("Today's prompt:")
                            .font(.custom("SortsMillGoudy-Italic", size: 17))
                            .foregroundStyle(inkColor.opacity(0.86))
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

                    Text(promptPreviewText)
                        .font(.custom("SortsMillGoudy-Regular", size: 18))
                        .foregroundStyle(inkColor.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50, alignment: .center)
                        .padding(.bottom, 2)

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
                    }

                    HStack(spacing: 10) {
                        Spacer()

                        Button {
                            promptResponse = ""
                            isEntryFocused = false
                        } label: {
                            ReflectOutlineActionButton(
                                title: "Clear",
                                fontSize: 14,
                                verticalPadding: 6,
                                horizontalPadding: 18,
                                textColor: ReflectPalette.secondaryGreen.opacity(0.95)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(promptResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(promptResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)

                        Button {
                            guard canSavePromptResponse else { return }
                            let trimmed = promptResponse.trimmingCharacters(in: .whitespacesAndNewlines)
                            upsertEntryForToday(promptResponse: trimmed)
                            onPromptResponseSave(trimmed)
                            promptResponse = ""
                            isEntryFocused = false
                        } label: {
                            ReflectActionButton(
                                title: "Done",
                                fontSize: 14,
                                verticalPadding: 6,
                                horizontalPadding: 18
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSavePromptResponse)
                        .opacity(canSavePromptResponse ? 1 : 0.45)
                    }
                }
            }

            ReflectJournalSurfaceCard {
                VStack(alignment: .center, spacing: 14) {
                    Text("Take time to reflect")
                        .font(.custom("SortsMillGoudy-Italic", size: 18))
                        .foregroundStyle(inkColor.opacity(0.84))
                        .multilineTextAlignment(.center)

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
                selectedEntryID: $selectedEntryID,
                externalOpenDate: externalPastEntriesJumpDate,
                externalOpenToken: externalPastEntriesJumpToken,
                onTodayEditingChange: { isEditing in
                    externalIsJournalCoverEditing?.wrappedValue = isEditing
                }
            )
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

    private var savedPromptResponseForToday: String {
        let todayKey = ReflectDateKey(date: today, calendar: calendar)
        return journalEntries.first(where: { ReflectDateKey(date: $0.date, calendar: calendar) == todayKey })?.promptResponse ?? ""
    }

    private var promptPreviewText: String {
        let saved = savedPromptResponseForToday.trimmingCharacters(in: .whitespacesAndNewlines)
        if !saved.isEmpty {
            return ReflectJournalPrompt.filledPromptString(prompt, with: saved)
        }

        let draft = promptResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if !draft.isEmpty {
            return ReflectJournalPrompt.filledPromptString(prompt, with: draft)
        }

        return ReflectJournalPrompt.displayPrompt(prompt)
    }

    private var canSavePromptResponse: Bool {
        !promptResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 3)
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
        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 3)
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
    @Binding var selectedEntryID: UUID?
    var externalOpenDate: Binding<Date?>? = nil
    var externalOpenToken: Binding<UUID?>? = nil
    var onTodayEditingChange: ((Bool) -> Void)? = nil

    @State private var selectedTab: ReflectJournalCoverTab = .today
    @State private var isOpen = false
    @State private var isWritingToday = false
    @State private var todayPageIndex: Int = 0
    @State private var todayDraftPages: [String] = [""]
    @State private var todayDraftPageIndex: Int = 0
    @State private var pastEntriesJumpDate: Date? = nil
    @State private var pastEntriesAutoOpenToken: UUID? = nil
    @State private var handledExternalOpenToken: UUID? = nil
    @FocusState private var isTodayEditorFocused: Bool

    private let pageCardBackground = ReflectPalette.warmWhite
    private let coverPanelHeight: CGFloat = 520
    private let todayDraftPageCharacterLimit: Int = 470
    private let todayPageBodyHeight: CGFloat = 228
    private var calendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        return cal
    }

    private var externalOpenTokenValue: UUID? {
        externalOpenToken?.wrappedValue ?? nil
    }

    private var externalOpenDateValue: Date? {
        externalOpenDate?.wrappedValue ?? nil
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        if isOpen {
                            finishTodayEditing()
                            selectedTab = .today
                            todayPageIndex = 0
                            isOpen = false
                        } else {
                            selectedTab = .today
                            todayPageIndex = 0
                            isOpen = true
                        }
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

            VStack(spacing: 0) {
                HStack(spacing: 20) {
                    ForEach(ReflectJournalCoverTab.allCases) { tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                if selectedTab == .today && tab != .today {
                                    finishTodayEditing()
                                }
                                if tab == .pastEntries {
                                    pastEntriesAutoOpenToken = nil
                                }
                                selectedTab = tab
                                isOpen = true
                                if tab == .today {
                                    todayPageIndex = 0
                                }
                            }
                        } label: {
                            ReflectLandingTabChip(
                                title: tab.rawValue,
                                isSelected: isOpen && selectedTab == tab
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.top, 2)
                .padding(.bottom, -10)
                .zIndex(0)

                Group {
                    if isOpen {
                        openJournalContent
                    } else {
                        coverImage
                            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    selectedTab = .today
                                    todayPageIndex = 0
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
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 3)
                .zIndex(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: isTodayEditorFocused) { focused in
            if !focused && selectedTab == .today && isWritingToday {
                finishTodayEditing()
            }
        }
        .onChange(of: isWritingToday) { isEditing in
            onTodayEditingChange?(isEditing)
        }
        .onChange(of: externalOpenTokenValue) { _ in
            handleExternalOpenRequest()
        }
        .onChange(of: externalOpenDateValue) { _ in
            handleExternalOpenRequest()
        }
        .onAppear {
            onTodayEditingChange?(false)
            handleExternalOpenRequest()
        }
    }

    private var coverImage: some View {
        ZStack {
            if let cover = UIImage(named: "journal") ?? UIImage(named: "journal.png") {
                Image(uiImage: cover)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
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
        .background(Color.white.opacity(0.94))
        .clipped()
    }

    @ViewBuilder
    private var openJournalContent: some View {
        switch selectedTab {
        case .today:
            ReflectJournalPageCard {
                VStack(alignment: .leading, spacing: 14) {
                    ZStack(alignment: .topTrailing) {
                        Text(todayDisplayDateLabel)
                            .font(.custom("SortsMillGoudy-Italic", size: 18))
                            .foregroundStyle(Color.black.opacity(0.84))
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .center)

                        if todayDisplayedPageCount > 1 {
                            Text("\(todayDisplayedPageIndex + 1)/\(todayDisplayedPageCount)")
                                .font(.custom("AvenirNext-Medium", size: 12))
                                .foregroundStyle(Color.black.opacity(0.56))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isWritingToday {
                            finishTodayEditing()
                        }
                    }

                    todayPromptCard

                    if isWritingToday {
                        TextEditor(text: todayDraftPageTextBinding)
                            .font(.custom("AvenirNext-Regular", size: 14))
                            .foregroundStyle(Color.black.opacity(0.84))
                            .scrollContentBackground(.hidden)
                            .scrollIndicators(.hidden)
                            .scrollDisabled(true)
                            .frame(maxWidth: .infinity, minHeight: todayPageBodyHeight, maxHeight: todayPageBodyHeight, alignment: .topLeading)
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

                        HStack(alignment: .center, spacing: 8) {
                            Button {
                                guard todayDraftPageIndex > 0 else { return }
                                triggerArrowHaptic()
                                moveToDraftPage(todayDraftPageIndex - 1)
                            } label: {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundStyle(Color.black.opacity(todayDraftPageIndex > 0 ? 0.72 : 0.24))
                                    .frame(width: 30, height: 30)
                            }
                            .buttonStyle(.plain)
                            .disabled(todayDraftPageIndex == 0)

                            Spacer(minLength: 10)

                            Button {
                                finishTodayEditing()
                            } label: {
                                ReflectActionButton(
                                    title: "Done",
                                    fontSize: 14,
                                    verticalPadding: 6,
                                    horizontalPadding: 18
                                )
                            }
                            .buttonStyle(.plain)

                            Spacer(minLength: 10)

                            Button {
                                guard todayDraftPageIndex < todayDraftPages.count - 1 else { return }
                                triggerArrowHaptic()
                                moveToDraftPage(todayDraftPageIndex + 1)
                            } label: {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundStyle(Color.black.opacity(todayDraftPageIndex < todayDraftPages.count - 1 ? 0.72 : 0.24))
                                    .frame(width: 30, height: 30)
                            }
                            .buttonStyle(.plain)
                            .disabled(todayDraftPageIndex >= todayDraftPages.count - 1)
                        }
                        .padding(.horizontal, 2)
                    } else {
                        Text(todayCurrentPageText)
                            .font(.custom("AvenirNext-Regular", size: 13))
                            .foregroundStyle(Color.black.opacity(0.82))
                            .lineSpacing(3)
                            .frame(maxWidth: .infinity, minHeight: todayPageBodyHeight, maxHeight: todayPageBodyHeight, alignment: .topLeading)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.88))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                    )
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .onTapGesture {
                                activateWritingMode()
                            }

                        HStack(alignment: .bottom) {
                            Button {
                                guard todayCurrentPageIndex > 0 else { return }
                                triggerArrowHaptic()
                                todayPageIndex = todayCurrentPageIndex - 1
                            } label: {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundStyle(Color.black.opacity(todayCurrentPageIndex > 0 ? 0.72 : 0.24))
                                    .frame(width: 30, height: 30)
                            }
                            .buttonStyle(.plain)
                            .disabled(todayCurrentPageIndex == 0)

                            Spacer()

                            Button {
                                guard todayCurrentPageIndex < todayJournalPages.count - 1 else { return }
                                triggerArrowHaptic()
                                todayPageIndex = todayCurrentPageIndex + 1
                            } label: {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundStyle(Color.black.opacity(todayCurrentPageIndex < todayJournalPages.count - 1 ? 0.72 : 0.24))
                                    .frame(width: 30, height: 30)
                            }
                            .buttonStyle(.plain)
                            .disabled(todayCurrentPageIndex >= todayJournalPages.count - 1)
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }

        case .thisWeek:
            ReflectJournalPageCard {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(last7Dates, id: \.self) { date in
                        let entry = entryForDate(date)
                        let canOpenEntry = entry.map(hasWrittenContent) ?? false

                        HStack(alignment: .center, spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(weekdayFormatter.string(from: date)) (\(fullDayFormatter.string(from: date)))")
                                    .font(.custom("SortsMillGoudy-Italic", size: 15))
                                    .foregroundStyle(Color.black.opacity(0.84))

                                Text(weeklyPromptLine(for: entry))
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundStyle(Color.black.opacity(0.78))
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 4)

                            Button {
                                openPastEntryFromThisWeek(for: date, entry: entry)
                            } label: {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(Color.black.opacity(canOpenEntry ? 0.68 : 0.24))
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.plain)
                            .disabled(!canOpenEntry)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.88))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(red: 0.87, green: 0.9, blue: 0.81), lineWidth: 1)
                                )
                        )
                    }
                }
            }

        case .pastEntries:
            ReflectJournalPastEntriesCalendar(
                entries: $entries,
                selectedEntryID: $selectedEntryID,
                focusedDate: pastEntriesJumpDate,
                autoOpenToken: pastEntriesAutoOpenToken,
                preferredHeight: coverPanelHeight
            )
            .background(pageCardBackground)
        }
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

    private var todayDisplayDateLabel: String {
        todayFullDateFormatter.string(from: Date())
    }

    private var todayPromptHeading: String {
        "\(weekdayFormatter.string(from: Date()))'s Prompt:"
    }

    private var todayPromptText: String {
        guard let entry = entryForDate(Date()) else { return "No prompt yet." }
        let response = entry.promptResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        return ReflectJournalPrompt.filledPromptString(entry.prompt, with: response)
    }

    private var todayPromptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(todayPromptHeading)
                .font(.custom("SortsMillGoudy-Italic", size: 16))
                .foregroundStyle(ReflectPalette.brown.opacity(0.88))

            Text(todayPromptText)
                .font(.custom("SortsMillGoudy-Regular", size: 14))
                .foregroundStyle(ReflectPalette.brown.opacity(0.92))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ReflectPalette.lightGreen, lineWidth: 1)
                )
        )
    }

    private var todayFullDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE (M/d/yyyy)"
        return formatter
    }

    private var todayJournalPages: [String] {
        paginateJournalText(todayJournalBody, maxCharactersPerPage: todayDraftPageCharacterLimit)
    }

    private var todayCurrentPageIndex: Int {
        let lastIndex = max(0, todayJournalPages.count - 1)
        return min(max(todayPageIndex, 0), lastIndex)
    }

    private var todayCurrentPageText: String {
        todayJournalPages[todayCurrentPageIndex]
    }

    private var todayDisplayedPageCount: Int {
        isWritingToday ? todayDraftPages.count : todayJournalPages.count
    }

    private var todayDisplayedPageIndex: Int {
        isWritingToday ? todayDraftPageIndex : todayCurrentPageIndex
    }

    private var last7Dates: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }
    }

    private func entryForDate(_ date: Date) -> ReflectJournalEntry? {
        entries.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func weeklyPromptLine(for entry: ReflectJournalEntry?) -> String {
        guard let entry else { return "No prompt yet." }
        return ReflectJournalPrompt.filledPromptString(entry.prompt, with: entry.promptResponse)
    }

    private var weekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE"
        return formatter
    }

    private var fullDayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "M/d/yyyy"
        return formatter
    }

    private var todayDraftPageTextBinding: Binding<String> {
        Binding(
            get: {
                let safeIndex = min(max(todayDraftPageIndex, 0), max(0, todayDraftPages.count - 1))
                return todayDraftPages[safeIndex]
            },
            set: { newValue in
                updateTodayDraftPageText(newValue)
            }
        )
    }

    private func activateWritingMode() {
        let existingText = entryForDate(Date())?.journalText ?? ""
        let pages = paginateJournalText(existingText, maxCharactersPerPage: todayDraftPageCharacterLimit)
        todayDraftPages = pages.isEmpty ? [""] : pages
        todayDraftPageIndex = max(0, todayDraftPages.count - 1)
        withAnimation(.easeInOut(duration: 0.2)) {
            isOpen = true
            selectedTab = .today
            isWritingToday = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            isTodayEditorFocused = true
        }
    }

    private func finishTodayEditing() {
        guard isWritingToday else { return }
        let mergedText = todayDraftPages
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        upsertTodayJournalText(mergedText)
        isWritingToday = false
        isTodayEditorFocused = false
        todayPageIndex = 0
    }

    private func openPastEntryFromThisWeek(for date: Date, entry: ReflectJournalEntry?) {
        guard let entry, hasWrittenContent(entry) else { return }
        selectedEntryID = entry.id
        pastEntriesJumpDate = date
        pastEntriesAutoOpenToken = UUID()
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = .pastEntries
        }
    }

    private func handleExternalOpenRequest() {
        guard let token = externalOpenTokenValue else { return }
        guard token != handledExternalOpenToken else { return }
        guard let targetDate = externalOpenDateValue else { return }
        handledExternalOpenToken = token

        if isWritingToday {
            finishTodayEditing()
        }
        selectedEntryID = entryForDate(targetDate)?.id
        pastEntriesJumpDate = targetDate
        pastEntriesAutoOpenToken = token
        withAnimation(.easeInOut(duration: 0.2)) {
            isOpen = true
            selectedTab = .pastEntries
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

    private func moveToDraftPage(_ index: Int) {
        let safeIndex = min(max(index, 0), max(0, todayDraftPages.count - 1))
        todayDraftPageIndex = safeIndex
    }

    private func updateTodayDraftPageText(_ newValue: String) {
        guard !todayDraftPages.isEmpty else {
            todayDraftPages = [newValue]
            todayDraftPageIndex = 0
            return
        }

        let safeIndex = min(max(todayDraftPageIndex, 0), todayDraftPages.count - 1)
        var updatedPages = todayDraftPages
        updatedPages[safeIndex] = newValue
        let normalized = normalizeDraftPages(updatedPages)
        let didOverflow = newValue.count > todayDraftPageCharacterLimit && safeIndex < normalized.count - 1

        todayDraftPages = normalized
        if didOverflow {
            moveToDraftPage(safeIndex + 1)
            triggerArrowHaptic()
        } else {
            moveToDraftPage(safeIndex)
        }
    }

    private func normalizeDraftPages(_ pages: [String]) -> [String] {
        var normalized = pages
        var index = 0
        while index < normalized.count {
            let page = normalized[index]
            guard page.count > todayDraftPageCharacterLimit else {
                index += 1
                continue
            }

            let split = splitPage(page, limit: todayDraftPageCharacterLimit)
            normalized[index] = split.current
            if index + 1 < normalized.count {
                let suffix = normalized[index + 1]
                normalized[index + 1] = split.overflow + (suffix.isEmpty ? "" : " " + suffix)
            } else {
                normalized.append(split.overflow)
            }
        }

        while normalized.count > 1 &&
                normalized.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            normalized.removeLast()
        }
        return normalized.isEmpty ? [""] : normalized
    }

    private func splitPage(_ text: String, limit: Int) -> (current: String, overflow: String) {
        guard text.count > limit else { return (text, "") }

        let hardSplit = text.index(text.startIndex, offsetBy: limit)
        let prefixRange = text.startIndex..<hardSplit
        let splitIndex: String.Index

        if let whitespace = text[prefixRange].lastIndex(where: { $0.isWhitespace }) {
            splitIndex = text.index(after: whitespace)
        } else {
            splitIndex = hardSplit
        }

        let current = String(text[..<splitIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        let overflow = String(text[splitIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if current.isEmpty {
            return (
                String(text[..<hardSplit]).trimmingCharacters(in: .whitespacesAndNewlines),
                String(text[hardSplit...]).trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        return (current, overflow)
    }

    private func hasWrittenContent(_ entry: ReflectJournalEntry) -> Bool {
        !entry.promptResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !entry.journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func paginateJournalText(_ text: String, maxCharactersPerPage: Int) -> [String] {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return [""] }

        var pages: [String] = []
        var currentPage = ""
        let words = cleaned.split(whereSeparator: \.isWhitespace)

        for word in words {
            let token = String(word)
            let candidate = currentPage.isEmpty ? token : "\(currentPage) \(token)"
            if candidate.count > maxCharactersPerPage && !currentPage.isEmpty {
                pages.append(currentPage)
                currentPage = token
            } else {
                currentPage = candidate
            }
        }

        if !currentPage.isEmpty {
            pages.append(currentPage)
        }

        return pages.isEmpty ? [cleaned] : pages
    }

    private func triggerArrowHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.85)
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

private struct ReflectJournalPastEntriesCalendar: View {
    @Binding var entries: [ReflectJournalEntry]
    @Binding var selectedEntryID: UUID?
    let focusedDate: Date?
    let autoOpenToken: UUID?
    let preferredHeight: CGFloat

    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var openedEntryDate: Date? = nil
    @State private var openedEntryPageIndex: Int = 0
    @State private var handledAutoOpenToken: UUID? = nil
    private let calendar = Calendar.current
    private let dayOutlineColor = Color(red: 0.82, green: 0.86, blue: 0.71)

    var body: some View {
        ReflectJournalPageCard {
            Group {
                if let openedEntryDate {
                    readOnlyEntryContent(for: openedEntryDate)
                } else {
                    calendarContent
                }
            }
        }
        .frame(height: preferredHeight)
        .onAppear {
            focusOnDate(focusedDate ?? latestEntryDate() ?? Date())
            handleAutoOpenIfNeeded()
        }
        .onChange(of: focusedDate) { date in
            guard let date else { return }
            focusOnDate(date)
            handleAutoOpenIfNeeded()
        }
        .onChange(of: autoOpenToken) { _ in
            handleAutoOpenIfNeeded()
        }
    }

    private var calendarContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                monthArrowButton(systemName: "chevron.left", direction: -1)

                Spacer(minLength: 6)
                Text(monthYearFormatter.string(from: displayedMonth))
                    .font(.custom("SortsMillGoudy-Italic", size: 24))
                    .foregroundStyle(Color(red: 0.18, green: 0.08, blue: 0.08))
                Spacer(minLength: 6)

                monthArrowButton(systemName: "chevron.right", direction: 1)
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

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 7),
                spacing: 12
            ) {
                let calendarCellHeight: CGFloat = 42
                ForEach(Array(monthGridItems(for: displayedMonth).enumerated()), id: \.offset) { _, item in
                    if let day = item.day {
                        let date = dateForDay(day, in: displayedMonth)
                        let entry = date.flatMap(entryForDate)
                        let hasEntry = entry.map(hasWrittenContent) ?? false
                        let isSelected = date.map { calendar.isDate($0, inSameDayAs: selectedDate) } ?? false

                        Button {
                            guard let date else { return }
                            selectedDate = date
                            selectedEntryID = entry?.id
                            if hasEntry {
                                openEntry(for: date)
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(hasEntry ? AnyShapeStyle(entryDayGradient) : AnyShapeStyle(Color.white))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                isSelected ? Color.black.opacity(0.35) : dayOutlineColor,
                                                style: StrokeStyle(
                                                    lineWidth: isSelected ? 1.2 : 1,
                                                    dash: hasEntry ? [] : [4, 4]
                                                )
                                            )
                                    )
                                    .shadow(
                                        color: hasEntry ? Color.black.opacity(0.1) : .clear,
                                        radius: 4,
                                        x: 0,
                                        y: 3
                                    )

                                Text("\(day)")
                                    .font(.custom("Poppins-Regular", size: 16))
                                    .foregroundStyle(Color.black.opacity(0.72))
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, minHeight: calendarCellHeight, maxHeight: calendarCellHeight)
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: 42, maxHeight: 42)
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func readOnlyEntryContent(for date: Date) -> some View {
        let entry = entryForDate(date)
        let pages = pagesForEntry(entry)
        let currentPage = min(max(openedEntryPageIndex, 0), max(0, pages.count - 1))

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 8) {
                Button {
                    triggerArrowHaptic()
                    openedEntryDate = nil
                    openedEntryPageIndex = 0
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.72))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(readOnlyDateFormatter.string(from: date))
                    .font(.custom("SortsMillGoudy-Italic", size: 18))
                    .foregroundStyle(Color.black.opacity(0.84))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                if pages.count > 1 {
                    Text("\(currentPage + 1)/\(pages.count)")
                        .font(.custom("AvenirNext-Medium", size: 12))
                        .foregroundStyle(Color.black.opacity(0.56))
                        .frame(width: 42, alignment: .trailing)
                } else {
                    Color.clear.frame(width: 42, height: 1)
                }
            }

            Text(pages[currentPage])
                .font(.custom("AvenirNext-Regular", size: 13))
                .foregroundStyle(Color.black.opacity(0.82))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, minHeight: 330, maxHeight: 330, alignment: .topLeading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.88))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                )

            HStack(alignment: .bottom) {
                Button {
                    guard currentPage > 0 else { return }
                    triggerArrowHaptic()
                    openedEntryPageIndex = currentPage - 1
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(Color.black.opacity(currentPage > 0 ? 0.72 : 0.24))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .disabled(currentPage == 0)

                Spacer()

                Button {
                    guard currentPage < pages.count - 1 else { return }
                    triggerArrowHaptic()
                    openedEntryPageIndex = currentPage + 1
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(Color.black.opacity(currentPage < pages.count - 1 ? 0.72 : 0.24))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .disabled(currentPage >= pages.count - 1)
            }
            .padding(.horizontal, 2)
        }
    }

    private var entryDayGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.98, green: 0.89, blue: 0.73), location: 0.0),
                .init(color: Color(red: 0.93, green: 0.91, blue: 0.69), location: 0.55),
                .init(color: Color(red: 0.88, green: 0.91, blue: 0.70), location: 1.0)
            ],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
    }

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }

    private var readOnlyDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE (M/d/yyyy)"
        return formatter
    }

    private func monthArrowButton(systemName: String, direction: Int) -> some View {
        Button {
            triggerArrowHaptic()
            guard let updated = calendar.date(byAdding: .month, value: direction, to: displayedMonth) else { return }
            displayedMonth = monthStart(for: updated)
            selectedDate = monthStart(for: updated)
            selectedEntryID = entryForDate(selectedDate)?.id
            openedEntryDate = nil
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.74))
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
    }

    private func monthGridItems(for month: Date) -> [MonthGridDay] {
        guard let firstOfMonth = monthStartDate(for: month),
              let dayRange = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }

        let leadingPlaceholderCount = calendar.component(.weekday, from: firstOfMonth) - 1
        var items = Array(repeating: MonthGridDay(day: nil), count: leadingPlaceholderCount)
        items.append(contentsOf: dayRange.map { MonthGridDay(day: $0) })
        while items.count % 7 != 0 {
            items.append(MonthGridDay(day: nil))
        }
        return items
    }

    private func monthStart(for date: Date) -> Date {
        monthStartDate(for: date) ?? calendar.startOfDay(for: date)
    }

    private func monthStartDate(for date: Date) -> Date? {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))
    }

    private func dateForDay(_ day: Int, in month: Date) -> Date? {
        var components = calendar.dateComponents([.year, .month], from: month)
        components.day = day
        return calendar.date(from: components)
    }

    private func entryForDate(_ date: Date) -> ReflectJournalEntry? {
        entries
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
            .first
    }

    private func latestEntryDate() -> Date? {
        entries
            .filter(hasWrittenContent)
            .map(\.date)
            .sorted(by: >)
            .first
    }

    private func focusOnDate(_ date: Date) {
        selectedDate = date
        displayedMonth = monthStart(for: date)
        selectedEntryID = entryForDate(date)?.id
        openedEntryDate = nil
        openedEntryPageIndex = 0
    }

    private func openEntry(for date: Date) {
        guard let entry = entryForDate(date), hasWrittenContent(entry) else { return }
        triggerArrowHaptic()
        selectedDate = date
        selectedEntryID = entry.id
        openedEntryDate = date
        openedEntryPageIndex = 0
    }

    private func handleAutoOpenIfNeeded() {
        guard let autoOpenToken, autoOpenToken != handledAutoOpenToken else { return }
        handledAutoOpenToken = autoOpenToken
        guard let focusedDate else { return }
        focusOnDate(focusedDate)
        openEntry(for: focusedDate)
    }

    private func hasWrittenContent(_ entry: ReflectJournalEntry) -> Bool {
        !entry.promptResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !entry.journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func journalText(for entry: ReflectJournalEntry) -> String {
        let journalBody = entry.journalText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !journalBody.isEmpty {
            return journalBody
        }

        let response = entry.promptResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if !response.isEmpty {
            return ReflectJournalPrompt.filledPromptString(entry.prompt, with: response)
        }

        return ReflectJournalPrompt.displayPrompt(entry.prompt)
    }

    private func pagesForEntry(_ entry: ReflectJournalEntry?) -> [String] {
        guard let entry else { return ["No journal entry for this day."] }
        let content = journalText(for: entry)
        return paginateJournalText(content, maxCharactersPerPage: 470)
    }

    private func paginateJournalText(_ text: String, maxCharactersPerPage: Int) -> [String] {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return [""] }

        var pages: [String] = []
        var currentPage = ""
        let words = cleaned.split(whereSeparator: \.isWhitespace)

        for word in words {
            let token = String(word)
            let candidate = currentPage.isEmpty ? token : "\(currentPage) \(token)"
            if candidate.count > maxCharactersPerPage && !currentPage.isEmpty {
                pages.append(currentPage)
                currentPage = token
            } else {
                currentPage = candidate
            }
        }

        if !currentPage.isEmpty {
            pages.append(currentPage)
        }

        return pages.isEmpty ? [cleaned] : pages
    }

    private func triggerArrowHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.85)
    }
}

private struct MonthGridDay: Identifiable {
    let id = UUID()
    let day: Int?
}

struct ReflectMoodDayDisplay: Identifiable {
    let id = UUID()
    let dayLabel: String
    let dateLabel: String
    let mood: ReflectMoodOption?
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
        if prompt.range(of: #"_{3,}"#, options: .regularExpression) != nil {
            return prompt
        }
        return prompt
    }

    static func filledPromptString(_ prompt: String, with entry: String) -> String {
        let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return displayPrompt(prompt) }

        if prompt.contains("...") {
            return prompt.replacingOccurrences(of: "...", with: trimmed)
        }

        let replaced = prompt.replacingOccurrences(
            of: #"_{3,}"#,
            with: trimmed,
            options: .regularExpression
        )
        if replaced != prompt {
            return replaced
        }

        return "\(prompt) \(trimmed)"
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

        if let range = prompt.range(of: #"_{3,}"#, options: .regularExpression) {
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
    static let didChangeNotification = Notification.Name("reflect.mood.levels.didChange")

    private static func levelsKey(for dateKey: ReflectDateKey) -> String {
        "reflect.mood.levels.\(dateKey.year)-\(dateKey.month)-\(dateKey.day)"
    }

    static func hasLevels(for dateKey: ReflectDateKey) -> Bool {
        UserDefaults.standard.data(forKey: levelsKey(for: dateKey)) != nil
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
        NotificationCenter.default.post(name: didChangeNotification, object: dateKey)
    }
}

struct ReflectMoodOption: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let assetName: String

    static let moods: [ReflectMoodOption] = [
        .init(name: "Happy", assetName: "happy"),
        .init(name: "Fine", assetName: "fine"),
        .init(name: "Frustrated", assetName: "frustrated"),
        .init(name: "Anxious", assetName: "anxious"),
        .init(name: "Excited", assetName: "excited"),
        .init(name: "Sad", assetName: "sad"),
        .init(name: "Tired", assetName: "tired"),
        .init(name: "Bored", assetName: "bored"),
        .init(name: "Content", assetName: "content")
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

    var body: some View {
        HStack(spacing: 14) {
            Text(level.label.capitalized)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundStyle(Color.black.opacity(0.8))
                .frame(width: 92, alignment: .leading)

            MoodLevelBar(value: $level.value)
                .frame(height: 14)
        }
    }
}

struct MoodLevelBar: View {
    @Binding var value: Double
    @State private var feedbackGenerator = UISelectionFeedbackGenerator()
    @State private var impactGenerator = UIImpactFeedbackGenerator(style: .soft)
    @State private var lastHapticBucket: Int = -1

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let fillWidth = width * CGFloat(value)
            let visibleFillWidth: CGFloat = value > 0 ? max(10, fillWidth) : 0

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(red: 0.84, green: 0.88, blue: 0.74))
                    .overlay(
                        Capsule()
                            .stroke(Color(red: 0.71, green: 0.60, blue: 0.62).opacity(0.42), lineWidth: 1)
                    )

                Capsule()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.92, green: 0.90, blue: 0.56), location: 0.0),
                                .init(color: Color(red: 0.96, green: 0.74, blue: 0.46), location: 0.56),
                                .init(color: Color(red: 0.95, green: 0.88, blue: 0.83), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: min(width, visibleFillWidth))
                    .overlay(
                        Capsule()
                            .stroke(Color(red: 0.67, green: 0.52, blue: 0.55).opacity(0.55), lineWidth: 1.2)
                    )
            }
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 3)
            .contentShape(Rectangle())
            .animation(.easeOut(duration: 0.12), value: value)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let clampedX = min(max(gesture.location.x, 0), width)
                        let rawValue = Double(clampedX / max(width, 1))
                        value = min(max(rawValue, 0), 1)

                        // Fire light haptics as the thumb crosses small value buckets.
                        let bucket = Int((value * 20).rounded())
                        if bucket != lastHapticBucket {
                            feedbackGenerator.selectionChanged()
                            feedbackGenerator.prepare()
                            lastHapticBucket = bucket
                        }
                    }
                    .onEnded { _ in
                        impactGenerator.impactOccurred(intensity: 0.4)
                        impactGenerator.prepare()
                        lastHapticBucket = -1
                    }
            )
            .onAppear {
                feedbackGenerator.prepare()
                impactGenerator.prepare()
            }
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
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 3)
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M.d"
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: "en_US_POSIX")
        weekdayFormatter.dateFormat = "EEE"

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -6 + offset, to: today) else { return nil }
            let key = ReflectDateKey(date: date, calendar: calendar)
            let mood = loggedMoods[key]
            return ReflectMoodDayDisplay(
                dayLabel: weekdayFormatter.string(from: date).uppercased(),
                dateLabel: dateFormatter.string(from: date),
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

        var monthBuckets: [MonthKey: [(ReflectDateKey, ReflectMoodOption)]] = [:]

        for (key, mood) in loggedMoods {
            let monthKey = MonthKey(year: key.year, month: key.month)
            monthBuckets[monthKey, default: []].append((key, mood))
        }

        let sortedMonths = monthBuckets.keys.sorted {
            if $0.year != $1.year { return $0.year > $1.year }
            return $0.month > $1.month
        }

        return sortedMonths.compactMap { monthKey in
            guard let monthEntries = monthBuckets[monthKey],
                  let most = mostFrequentMood(in: monthEntries) else { return nil }
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
        var days = Array(repeating: 0, count: weekdayIndex) + Array(range)
        while days.count < 42 {
            days.append(0)
        }
        return days
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

    private func triggerArrowHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.85)
    }

    private func mostFrequentMood(in entries: [(ReflectDateKey, ReflectMoodOption)]) -> ReflectMoodOption? {
        struct MoodAggregate {
            var count: Int
            var latestDate: ReflectDateKey
        }

        var aggregates: [String: MoodAggregate] = [:]

        for (dateKey, mood) in entries {
            if var aggregate = aggregates[mood.name] {
                aggregate.count += 1
                if isLater(dateKey, than: aggregate.latestDate) {
                    aggregate.latestDate = dateKey
                }
                aggregates[mood.name] = aggregate
            } else {
                aggregates[mood.name] = MoodAggregate(count: 1, latestDate: dateKey)
            }
        }

        let sortedMoodNames = aggregates.keys.sorted { lhs, rhs in
            guard let left = aggregates[lhs], let right = aggregates[rhs] else {
                return lhs < rhs
            }
            if left.count != right.count { return left.count > right.count }
            if left.latestDate != right.latestDate { return isLater(left.latestDate, than: right.latestDate) }
            return lhs < rhs
        }

        guard let selectedMoodName = sortedMoodNames.first else { return nil }
        return ReflectMoodOption.fromName(selectedMoodName)
    }

    private func isLater(_ lhs: ReflectDateKey, than rhs: ReflectDateKey) -> Bool {
        if lhs.year != rhs.year { return lhs.year > rhs.year }
        if lhs.month != rhs.month { return lhs.month > rhs.month }
        return lhs.day > rhs.day
    }
}

struct MonthKey: Hashable {
    let year: Int
    let month: Int
}


#Preview {
    ReflectView()
}
