//
//  ReflectView.swift
//  Nomie
//

import SwiftUI
import UIKit

private let reflectLandingMoodCardHeight: CGFloat = 228

private struct ReflectTabBackground: View {
    var body: some View {
        Image("sunset")
            .resizable()
            .ignoresSafeArea()
            .aspectRatio(contentMode: .fill)
            .offset(x: 300)
            .scaleEffect(x: -1, y: 1)
    }
}

enum ReflectLandingSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case dailyMood = "Daily Mood"
    case journal = "Journal"
    case patternsTrends = "Patterns & Trends"

    var id: String { rawValue }
}

struct ReflectView: View {
    @State private var loggedMoods: [ReflectDateKey: ReflectMoodOption] = [:]
    @State private var journalPrompt = ReflectJournalPrompt.randomPrompt()
    @State private var journalPromptResponse = ""
    @State private var selectedLandingSection: ReflectLandingSection = .overview
    @State private var moodLevelsRefreshTick: Int = 0
    private let topScrollID = "reflect.top.scroll.id"
    private let calendar = Calendar.current
    private let tabBarColor = Color(red: 0.97, green: 0.97, blue: 0.97)
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

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    Color.clear
                        .frame(height: 0)
                        .id(topScrollID)

                    VStack(spacing: 18) {
                        ReflectHeader()

                        VStack(spacing: 0) {
                            ReflectLandingTabs(selectedSection: selectedLandingSection) { section in
                                selectedLandingSection = section
                            }
                            .padding(.horizontal, 0)
                            .padding(.bottom, -10)
                            .zIndex(1)

                            landingPanelContent
                            .padding(.horizontal, 12)
                            .padding(.top, 22)
                            .padding(.bottom, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.96))
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(red: 0.9, green: 0.89, blue: 0.8), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 24)
                    .padding(.top, 8)
                    .nomieTabBarContentPadding()
                }
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
        VStack(spacing: 20) {
            dailyMoodOverviewSection
            journalOverviewSection
            patternsOverviewSection
        }
    }

    private var dailyMoodOverviewSection: some View {
        VStack(spacing: 20) {
            ReflectSectionTitle(text: "Daily Mood", leadingAssetName: "planet2")
            HStack(alignment: .top, spacing: 14) {
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
        }
    }

    private var dailyMoodTabContent: some View {
        DailyMoodView(
            loggedMoods: $loggedMoods,
            isEmbeddedInLanding: true
        )
    }

    private var journalOverviewSection: some View {
        VStack(spacing: 20) {
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
                            .frame(maxWidth: .infinity, alignment: .center)
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
            isEmbeddedInLanding: true
        )
    }

    private var patternsOverviewSection: some View {
        VStack(spacing: 20) {
            ReflectSectionTitle(text: "Patterns & Trends", leadingAssetName: "planet2")
            VStack(spacing: 14) {
                ReflectPatternsPreviewChart(scores: past7DayMoodScores)
                    .frame(height: 250)

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
        HStack(spacing: 6) {
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
            .font(.custom("Poppins-Regular", size: 11))
            .foregroundStyle(Color.black.opacity(0.84))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.vertical, 9)
            .padding(.horizontal, 8)
            .frame(minHeight: 42)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isSelected
                        ? AnyShapeStyle(Color.white)
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
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.75), lineWidth: 1)
            )
    }
}

private struct ReflectActionButton: View {
    let title: String
    var fillHorizontally: Bool = false

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
        HStack(spacing: 8) {
            Image("pencil")
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
            Text(title)
                .font(.custom("SortsMillGoudy-Regular", size: 16))
                .foregroundStyle(Color(red: 0.15, green: 0.23, blue: 0.16).opacity(0.95))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
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
                .shadow(color: Color.black.opacity(0.12), radius: 5, x: 0, y: 3)
        )
    }
}

private struct ReflectOutlineActionButton: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image("pencil")
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
            Text(title)
                .font(.custom("SortsMillGoudy-Regular", size: 16))
                .foregroundStyle(Color.black.opacity(0.86))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(red: 0.86, green: 0.88, blue: 0.79), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        )
    }
}

private struct ReflectPatternsPreviewChart: View {
    let scores: [CGFloat]
    private let weekdayAxis = ["Su", "M", "Tu", "W", "Th", "F", "S"]

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .trailing) {
                Text("Tense")
                Spacer()
                Text("Calm")
            }
            .font(.custom("AvenirNext-Regular", size: 12))
            .foregroundStyle(Color.black.opacity(0.78))
            .frame(height: 170)
            .padding(.top, 2)

            VStack(spacing: 9) {
                GeometryReader { proxy in
                    let size = proxy.size
                    let points = chartPoints(in: size)

                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.94, blue: 0.82),
                                        Color(red: 0.83, green: 0.94, blue: 0.92)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        areaPath(from: points, in: size)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.97, green: 0.84, blue: 0.63).opacity(0.74),
                                        Color(red: 0.96, green: 0.66, blue: 0.45).opacity(0.82)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        areaPath(from: points, in: size)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.94, green: 0.62, blue: 0.4).opacity(0.72),
                                        Color.clear
                                    ],
                                    center: UnitPoint(x: 0.63, y: 0.54),
                                    startRadius: 10,
                                    endRadius: max(size.width, size.height) * 0.62
                                )
                            )

                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: 0, y: size.height))
                        }
                        .stroke(Color.black.opacity(0.14), lineWidth: 1)

                        Path { path in
                            guard let first = points.first else { return }
                            path.move(to: first)
                            for point in points.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                        .stroke(Color(red: 0.93, green: 0.63, blue: 0.38).opacity(0.55), lineWidth: 1.8)

                        ForEach(points.indices, id: \.self) { idx in
                            Circle()
                                .fill(Color(red: 0.95, green: 0.62, blue: 0.33))
                                .frame(width: 6, height: 6)
                                .position(points[idx])
                        }
                    }
                    .clipShape(Rectangle())
                }
                .frame(height: 170)

                HStack(spacing: 0) {
                    ForEach(xAxisLabels.indices, id: \.self) { index in
                        Text(xAxisLabels[index])
                            .font(.custom("AvenirNext-Regular", size: 12))
                            .foregroundStyle(Color.black.opacity(0.75))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading) {
                Text("Drift Hours")
                    .font(.custom("AvenirNext-Regular", size: 10))
                    .foregroundStyle(Color.black.opacity(0.62))
                Text("5h")
                Spacer()
                Text("2.5h")
                Spacer()
                Text("0h")
            }
            .font(.custom("AvenirNext-Regular", size: 12))
            .foregroundStyle(Color.black.opacity(0.66))
            .frame(height: 170)
            .padding(.top, 2)
        }
    }

    private var chartValues: [CGFloat] {
        let cleaned = scores.map { min(max($0, 1), 5) }
        return cleaned.isEmpty ? [3, 3, 3, 3, 3, 3, 3] : cleaned
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
        let xStep = size.width / CGFloat(chartValues.count - 1)
        return chartValues.enumerated().map { index, value in
            CGPoint(
                x: xStep * CGFloat(index),
                y: yPosition(for: value, in: size.height)
            )
        }
    }

    private func yPosition(for value: CGFloat, in height: CGFloat) -> CGFloat {
        let clamped = min(max(value, 1), 5)
        let normalized = (clamped - 1) / 4
        return height * (1 - normalized)
    }

    private func areaPath(from points: [CGPoint], in size: CGSize) -> Path {
        var path = Path()
        guard let first = points.first, let last = points.last else { return path }

        path.move(to: CGPoint(x: first.x, y: size.height))
        path.addLine(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.addLine(to: CGPoint(x: last.x, y: size.height))
        path.closeSubpath()
        return path
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

            ReflectActionButton(title: "Log Mood", fillHorizontally: true)
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
                .fill(Color.white.opacity(0.92))
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
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
                    .frame(width: 22, height: 24)

                Text("Streak")
                    .font(.custom("SortsMillGoudy-Regular", size: 32))
                    .foregroundStyle(Color.black.opacity(0.9))
            }

            Text("\(days)")
                .font(.custom("BricolageGrotesque-96ptExtraBold_Regular", size: 68))
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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.92))
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
                    .fill(Color.white.opacity(0.92))
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 5)
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
    var isEmbeddedInLanding: Bool = false
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
                VStack(spacing: 20) {
                    dailyMoodCoreContent
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 20) {
                            dailyMoodCoreContent
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 22)
                        .padding(.bottom, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.96))
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
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
        }
        .onChange(of: moodLevels) { _ in
            ReflectMoodLevelStore.saveLevels(moodLevels, for: todayKey)
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
                    Text("Most experienced moods")
                        .font(.custom("SortsMillGoudy-Regular", size: sectionTitleFontSize))
                        .foregroundStyle(Color.black.opacity(0.86))
                        .fixedSize(horizontal: true, vertical: false)
                        .layoutPriority(1)

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
    @Binding var isDragging: Bool
    let onSelect: (Int) -> Void
    @State private var feedbackGenerator = UISelectionFeedbackGenerator()

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
                        selectMood(at: idx)
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
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                        }
                        guard let nearestIndex = nearestMoodIndex(
                            to: gesture.location,
                            center: center,
                            positions: positions
                        ) else { return }
                        selectMood(at: nearestIndex)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .onAppear {
                feedbackGenerator.prepare()
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
    }
}



struct PatternsTrendsView: View {
    private let inkColor = Color(red: 0.13, green: 0.13, blue: 0.13)
    private let accentColor = Color(red: 0.16, green: 0.3, blue: 0.22)
    private let calendar = Calendar.current
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRange: TrendsRange = .past7Days
    @State private var journalEntries: [ReflectJournalEntry] = []
    @State private var moodLevelsRefreshTick: Int = 0
    var isEmbeddedInLanding: Bool = false

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
        Group {
            if isEmbeddedInLanding {
                patternsPageContent
                    .padding(.horizontal, 4)
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
        VStack(alignment: .leading, spacing: 22) {
            if !isEmbeddedInLanding {
                VStack(spacing: 10) {
                    Text("Patterns & Trends")
                        .font(.custom("SortsMillGoudy-Regular", size: 28))
                        .foregroundStyle(Color.black.opacity(0.92))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }

            TrendsMoodAnalyticsCard {
                VStack(alignment: .leading, spacing: 16) {
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

                    ReflectPatternsPreviewChart(scores: trendGraphScores)
                        .frame(height: 250)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
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
                    Text("Suggestions")
                        .font(.custom("SortsMillGoudy-Regular", size: 20))
                        .foregroundStyle(inkColor.opacity(0.95))

                    Text("Attempt to take intermittent breaks from\nDrifting apps in order to increase productivity\non a daily basis!")
                        .font(.custom("AvenirNext-Medium", size: 14))
                        .foregroundStyle(inkColor.opacity(0.88))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.vertical, 2)
            }
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

    private var trendGraphScores: [CGFloat] {
        _ = moodLevelsRefreshTick
        return moodTrendScores(for: selectedRange)
    }

    private func moodTrendScores(for range: TrendsRange) -> [CGFloat] {
        switch range {
        case .today:
            let todayScore = moodScore(for: Date())
            return Array(repeating: todayScore, count: 7)
        case .past7Days:
            return scoresForPastDays(7)
        case .past30Days:
            let raw = scoresForPastDays(30)
            guard !raw.isEmpty else { return Array(repeating: 3, count: 7) }

            let bucketCount = 7
            return (0..<bucketCount).map { bucket in
                let start = Int((Double(bucket) * Double(raw.count) / Double(bucketCount)).rounded(.down))
                let end = Int((Double(bucket + 1) * Double(raw.count) / Double(bucketCount)).rounded(.down))
                let safeEnd = max(end, start + 1)
                let slice = raw[start..<min(safeEnd, raw.count)]
                let average = slice.reduce(0, +) / CGFloat(max(slice.count, 1))
                return average
            }
        }
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
    @State private var selectedEntryID: UUID? = nil
    @FocusState private var isEntryFocused: Bool
    private let today = Date()
    private let calendar = Calendar.current
    private let entryHint = "Keep it short"
    private let tabBarColor = Color(red: 0.97, green: 0.97, blue: 0.97)
    private let inkColor = Color(red: 0.14, green: 0.14, blue: 0.14)
    private let accentColor = Color(red: 0.16, green: 0.3, blue: 0.22)
    private let onPromptChange: (String) -> Void
    private let onPromptResponseSave: (String) -> Void
    private let isEmbeddedInLanding: Bool
    @Environment(\.dismiss) private var dismiss

    init(
        initialPrompt: String,
        onPromptChange: @escaping (String) -> Void,
        onPromptResponseSave: @escaping (String) -> Void,
        isEmbeddedInLanding: Bool = false
    ) {
        _prompt = State(initialValue: initialPrompt)
        self.onPromptChange = onPromptChange
        self.onPromptResponseSave = onPromptResponseSave
        self.isEmbeddedInLanding = isEmbeddedInLanding
    }

    private var wordCount: Int {
        promptResponse.split { $0 == " " || $0 == "\n" || $0 == "\t" }.count
    }

    var body: some View {
        Group {
            if isEmbeddedInLanding {
                journalPageContent
                    .padding(.horizontal, 4)
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

    private var journalPageContent: some View {
        VStack(spacing: 24) {
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
                selectedEntryID: $selectedEntryID
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
                                .fill(Color.white.opacity(0.94))
                                .frame(width: 52, height: 52)
                                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)

                            Image("pencil")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
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

            Color.black.opacity(0.1)
        }
    }

    @ViewBuilder
    private var openJournalContent: some View {
        switch selectedTab {
        case .today:
            ReflectJournalPageCard {
                VStack(alignment: .leading, spacing: 14) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.92))
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
            ReflectJournalPastEntriesCalendar(
                entries: $entries,
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

private struct ReflectJournalPastEntriesCalendar: View {
    @Binding var entries: [ReflectJournalEntry]
    @Binding var selectedEntryID: UUID?
    let preferredHeight: CGFloat

    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    private let calendar = Calendar.current
    private let dayOutlineColor = Color(red: 0.82, green: 0.86, blue: 0.71)

    var body: some View {
        ReflectJournalPageCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    monthArrowButton(systemName: "chevron.left", direction: -1)
                    Spacer()
                    Text(monthFormatter.string(from: displayedMonth))
                        .font(.custom("SortsMillGoudy-Italic", size: 30))
                        .foregroundStyle(Color.black.opacity(0.78))
                    Spacer()
                    monthArrowButton(systemName: "chevron.right", direction: 1)
                }
                .padding(.horizontal, 2)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7),
                    spacing: 10
                ) {
                    ForEach(monthGridItems(for: displayedMonth)) { item in
                        if let day = item.day {
                            let date = dateForDay(day, in: displayedMonth)
                            let entry = date.flatMap(entryForDate)
                            let hasEntry = entry.map(hasWrittenContent) ?? false
                            let isSelected = date.map { calendar.isDate($0, inSameDayAs: selectedDate) } ?? false

                            Button {
                                guard let date else { return }
                                selectedDate = date
                                selectedEntryID = entry?.id
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(hasEntry ? AnyShapeStyle(entryDayGradient) : AnyShapeStyle(Color.white))
                                        .frame(width: 40, height: 40)
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
                                            radius: 5,
                                            x: 0,
                                            y: 3
                                        )

                                    Text("\(day)")
                                        .font(.custom("AvenirNext-DemiBold", size: 18))
                                        .foregroundStyle(Color.black.opacity(0.72))
                                }
                                .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                        } else {
                            Circle()
                                .stroke(dayOutlineColor, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .frame(width: 40, height: 40)
                                .opacity(0.7)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(entryDateFormatter.string(from: selectedDate))
                        .font(.custom("AvenirNext-Medium", size: 12))
                        .foregroundStyle(Color.black.opacity(0.56))

                    if let entry = entryForDate(selectedDate) {
                        Text(journalText(for: entry))
                            .font(.custom("AvenirNext-Regular", size: 14))
                            .foregroundStyle(Color.black.opacity(0.84))
                            .lineSpacing(2)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("No journal entry for this day.")
                            .font(.custom("AvenirNext-Regular", size: 14))
                            .foregroundStyle(Color.black.opacity(0.52))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )

                Spacer(minLength: 0)
            }
        }
        .frame(height: preferredHeight)
        .onAppear {
            let initialDate = latestEntryDate() ?? Date()
            selectedDate = initialDate
            displayedMonth = monthStart(for: initialDate)
            selectedEntryID = entryForDate(initialDate)?.id
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

    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL"
        return formatter
    }

    private var entryDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }

    private func monthArrowButton(systemName: String, direction: Int) -> some View {
        Button {
            guard let updated = calendar.date(byAdding: .month, value: direction, to: displayedMonth) else { return }
            displayedMonth = monthStart(for: updated)
            selectedDate = monthStart(for: updated)
            selectedEntryID = entryForDate(selectedDate)?.id
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.74))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                )
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
            return filledPromptString(entry.prompt, with: response)
        }

        return ReflectJournalPrompt.displayPrompt(entry.prompt)
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
            .shadow(color: Color.black.opacity(0.1), radius: 1.5, x: 0, y: 1)
            .contentShape(Rectangle())
            .animation(.easeOut(duration: 0.12), value: value)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let clampedX = min(max(gesture.location.x, 0), width)
                        let rawValue = Double(clampedX / max(width, 1))
                        value = min(max(rawValue, 0), 1)
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
