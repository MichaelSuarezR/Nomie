//
//  ReflectView.swift
//  Nomie
//

import SwiftUI
import UIKit

struct ReflectView: View {
    @State private var loggedMoods: [ReflectDateKey: ReflectMoodOption] = [:]
    @State private var journalPrompt = ReflectJournalPrompt.randomPrompt()
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

    private var journalDateLabel: String {
        ReflectJournalPrompt.dateLabel(Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ReflectHeader(title: "Reflect")

                    ReflectHero(
                        title: "Daily check-in",
                        subtitle: "How are you feeling lately?",
                        accentColor: accentColor
                    )

                    ReflectSectionTitle(text: "Daily Mood")
                    HStack(spacing: 16) {
                        NavigationLink {
                            DailyMoodView(loggedMoods: $loggedMoods)
                        } label: {
                            ReflectSoftCard {
                                ReflectMoodCard(title: "Today's mood:", mood: todayMood, isActionable: true)
                            }
                        }
                        .buttonStyle(.plain)

                        ReflectSoftCard {
                            ReflectMoodCard(title: "Yesterday's mood:", mood: yesterdayMood, isActionable: false)
                        }
                    }

                    ReflectSectionTitle(text: "Self-Journal")
                    NavigationLink {
                        SelfJournalView(
                            initialPrompt: journalPrompt,
                            onPromptChange: { journalPrompt = $0 },
                            loggedMoods: $loggedMoods
                        )
                    } label: {
                        ReflectCard {
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

                                Text(ReflectJournalPrompt.displayPrompt(journalPrompt))
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
                        ReflectCard {
                            VStack(alignment: .leading, spacing: 14) {
                                TrendsScatterPlot(accentColor: accentColor, inkColor: inkColor)
                                    .frame(height: 150)
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
            }
            .background(
                LinearGradient(
                    colors: [
                        surfaceColor,
                        Color(red: 0.98, green: 0.98, blue: 0.965),
                        tabBarColor
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
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
            }
        }
        .onChange(of: loggedMoods) { _ in
            ReflectMoodStore.saveMoods(loggedMoods)
        }
    }
}

struct ReflectHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Color.clear.frame(width: 36, height: 36)
            Spacer()
            Text(title)
                .font(.custom("Georgia", size: 34))
                .foregroundStyle(Color.black.opacity(0.86))
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.top, 8)
    }
}

struct ReflectSectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom("Georgia", size: 22))
            .foregroundStyle(Color.black.opacity(0.82))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
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

struct ReflectSoftCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
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
    @Environment(\.dismiss) private var dismiss
    private var todayKey: ReflectDateKey {
        ReflectDateKey(date: Date(), calendar: calendar)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Daily Mood")
                    .font(.custom("Georgia", size: 32))
                    .foregroundStyle(Color.black.opacity(0.85))
                Text("How was your overall mood today?")
                    .font(.custom("AvenirNext-Regular", size: 15))
                    .foregroundStyle(Color.black.opacity(0.6))

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

                VStack(alignment: .leading, spacing: 12) {
                    Text("Mood Levels")
                        .font(.custom("Georgia", size: 22))
                        .foregroundStyle(Color.black.opacity(0.8))
                    ReflectCard {
                        VStack(spacing: 16) {
                            Text("How much did you experience each of these moods today?")
                                .font(.custom("AvenirNext-Medium", size: 13))
                                .foregroundStyle(Color.black.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 6)
                            if let selectedMoodIndex, ReflectMoodOption.moods.indices.contains(selectedMoodIndex) {
                                ForEach($moodLevels) { $level in
                                    MoodLevelRow(
                                        level: $level,
                                        mood: ReflectMoodOption.moods[selectedMoodIndex]
                                    )
                                }
                            } else {
                                Text("Select a mood to personalize your levels.")
                                    .font(.custom("AvenirNext-Regular", size: 13))
                                    .foregroundStyle(Color.black.opacity(0.55))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 12)
                            }
                        }
                    }
                }

                ReflectCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Past 7 days")
                            .font(.custom("AvenirNext-Medium", size: 14))
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
                                        .font(.custom("AvenirNext-Medium", size: 11))
                                    Text(day.dateLabel)
                                        .font(.custom("AvenirNext-Regular", size: 11))
                                        .foregroundStyle(Color.black.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }

                ReflectCard {
                    VStack(spacing: 12) {
                        HStack {
                            Button {
                                currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            Spacer()
                            Text(monthTitle(currentMonth))
                                .font(.custom("Georgia", size: 22))
                            Spacer()
                            Button {
                                currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.75))

                        HStack {
                            ForEach(["Su", "M", "Tu", "W", "Th", "F", "S"], id: \.self) { day in
                                Text(day)
                                    .font(.custom("AvenirNext-Bold", size: 11))
                                    .foregroundStyle(Color.black.opacity(0.85))
                                    .tracking(0.6)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.bottom, 2)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                            ForEach(monthGridDays(for: currentMonth), id: \.self) { day in
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
                                            .font(.custom("AvenirNext-Regular", size: 11))
                                            .foregroundStyle(Color.black.opacity(moodForDay(day, in: currentMonth) == nil ? 0.3 : 0.75))
                                    }
                                }
                            }
                        }
                    }
                }

                if !mostExperiencedMoods.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Most experienced moods")
                            .font(.custom("AvenirNext-Medium", size: 14))
                            .foregroundStyle(Color.black.opacity(0.7))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2), spacing: 14) {
                            ForEach(mostExperiencedMoods) { item in
                                MostExperiencedMoodCard(item: item)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
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
                            .font(.custom("AvenirNext-Medium", size: 14))
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
                            .font(.custom("AvenirNext-Medium", size: 13))
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
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRange: TrendsRange = .past7Days

    private enum TrendsRange: String, CaseIterable, Identifiable {
        case today = "Today"
        case past7Days = "Past 7 days"
        case past30Days = "Past 30 days"

        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Color.clear.frame(width: 36, height: 36)
                    Spacer()

                    Text("Patterns &\nTrends")
                        .font(.custom("Georgia", size: 30))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(inkColor.opacity(0.9))

                    Spacer()

                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.top, 4)

                TrendsHeroPill(
                    title: "Your week at a glance",
                    subtitle: "Mood vs. app usage",
                    accentColor: accentColor
                )

                TrendsSectionTitle(text: "Mood vs. app usage")
                TrendsSurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Inspiration vs. productivity")
                                .font(.custom("AvenirNext-Medium", size: 12))
                                .foregroundStyle(inkColor.opacity(0.55))
                            Spacer()
                            Button {
                                selectedRange = nextRange(after: selectedRange)
                            } label: {
                                Text(selectedRange.rawValue)
                                    .font(.custom("AvenirNext-Regular", size: 11))
                                    .foregroundStyle(inkColor.opacity(0.6))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 10)
                                    .background(
                                        Capsule()
                                            .fill(accentColor.opacity(0.14))
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        TrendsScatterPlot(accentColor: accentColor, inkColor: inkColor)
                            .frame(height: 190)

                        HStack {
                            TrendsMetricBadge(label: "Avg. inspiration", value: "↑ 12%", accentColor: accentColor)
                            Spacer()
                            TrendsMetricBadge(label: "App usage", value: "1h 42m", accentColor: accentColor)
                        }
                    }
                }

                TrendsSectionTitle(text: "Insights")
                TrendsSurfaceCard {
                    VStack(alignment: .leading, spacing: 10) {
                        TrendsInsightRow(
                            title: "Escape apps correlate with higher stress",
                            subtitle: "Over 2h of Escape apps usually preceded a tougher day.",
                            systemImage: "exclamationmark.triangle",
                            accentColor: accentColor,
                            inkColor: inkColor
                        )
                        Divider().opacity(0.3)
                        TrendsInsightRow(
                            title: "Productivity time boosts inspiration",
                            subtitle: "More focus time often aligns with higher inspiration.",
                            systemImage: "sparkles",
                            accentColor: accentColor,
                            inkColor: inkColor
                        )
                    }
                }

                TrendsSectionTitle(text: "Suggestions")
                TrendsSurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Attempt to take intermittent breaks from drifting apps in order to preserve productivity daily.")
                            .font(.custom("AvenirNext-Regular", size: 14))
                            .foregroundStyle(inkColor.opacity(0.8))
                        HStack(spacing: 10) {
                            Label("Try a 10‑minute reset", systemImage: "timer")
                                .font(.custom("AvenirNext-Medium", size: 12))
                                .foregroundStyle(inkColor.opacity(0.7))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(accentColor.opacity(0.16))
                                )
                            Label("Batch notifications", systemImage: "bell.badge")
                                .font(.custom("AvenirNext-Medium", size: 12))
                                .foregroundStyle(inkColor.opacity(0.7))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.06))
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
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
                }
                .buttonStyle(.plain)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private func nextRange(after range: TrendsRange) -> TrendsRange {
        let all = TrendsRange.allCases
        guard let index = all.firstIndex(of: range) else { return .past7Days }
        let nextIndex = all.index(after: index)
        return nextIndex == all.endIndex ? all[all.startIndex] : all[nextIndex]
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

struct TrendsScatterPlot: View {
    let accentColor: Color
    let inkColor: Color

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
    @FocusState private var isEntryFocused: Bool
    private let today = Date()
    private let calendar = Calendar.current
    private let entryHint = "Keep it short — one to three sentences."
    private let tabBarColor = Color(red: 0.97, green: 0.97, blue: 0.97)
    private let surfaceColor = Color(red: 0.985, green: 0.975, blue: 0.95)
    private let paperColor = Color(red: 1, green: 0.995, blue: 0.975)
    private let inkColor = Color(red: 0.14, green: 0.14, blue: 0.14)
    private let accentColor = Color(red: 0.16, green: 0.3, blue: 0.22)
    private let onPromptChange: (String) -> Void
    @Binding private var loggedMoods: [ReflectDateKey: ReflectMoodOption]
    @Environment(\.dismiss) private var dismiss

    init(initialPrompt: String, onPromptChange: @escaping (String) -> Void, loggedMoods: Binding<[ReflectDateKey: ReflectMoodOption]>) {
        _prompt = State(initialValue: initialPrompt)
        self.onPromptChange = onPromptChange
        _loggedMoods = loggedMoods
    }

    private var wordCount: Int {
        promptResponse.split { $0 == " " || $0 == "\n" || $0 == "\t" }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Self-Journal")
                        .font(.custom("Georgia", size: 32))
                        .foregroundStyle(inkColor.opacity(0.9))
                    Text("Today • \(ReflectJournalPrompt.dateLabel(today))")
                        .font(.custom("AvenirNext-Medium", size: 12))
                        .foregroundStyle(inkColor.opacity(0.55))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ReflectJournalSurfaceCard {
                    VStack(spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Today's prompt", systemImage: "sparkles")
                                    .font(.custom("AvenirNext-Medium", size: 12))
                                    .foregroundStyle(inkColor.opacity(0.55))
                                Text(ReflectJournalPrompt.displayPrompt(prompt))
                                    .font(.custom("Georgia", size: ReflectJournalPrompt.promptFontSize(for: prompt)))
                                    .foregroundStyle(inkColor.opacity(0.9))
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            Button {
                                let newPrompt = ReflectJournalPrompt.randomPrompt()
                                prompt = newPrompt
                                onPromptChange(newPrompt)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("New prompt")
                                        .font(.custom("AvenirNext-Medium", size: 11))
                                }
                                .foregroundStyle(inkColor.opacity(0.7))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(accentColor.opacity(0.18))
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $promptResponse)
                                    .font(.custom("AvenirNext-Regular", size: 14))
                                    .foregroundStyle(inkColor.opacity(0.86))
                                    .padding(.horizontal, 10)
                                    .padding(.top, 12)
                                    .frame(minHeight: 140, maxHeight: 180)
                                    .scrollContentBackground(.hidden)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(paperColor)
                                            .overlay(
                                                ReflectLinedPaper()
                                                    .padding(.horizontal, 14)
                                                    .padding(.top, 12)
                                                    .opacity(0.4)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                            )
                                            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 8)
                                    )
                                    .focused($isEntryFocused)

                                if promptResponse.isEmpty {
                                    Text("Start writing...")
                                        .font(.custom("AvenirNext-Regular", size: 14))
                                        .foregroundStyle(inkColor.opacity(0.35))
                                        .padding(.horizontal, 16)
                                        .padding(.top, 18)
                                }
                            }

                            HStack {
                                Text(entryHint)
                                    .font(.custom("AvenirNext-Regular", size: 12))
                                    .foregroundStyle(inkColor.opacity(0.5))
                                Spacer()
                                Text("\(wordCount) words")
                                    .font(.custom("AvenirNext-Medium", size: 11))
                                    .foregroundStyle(inkColor.opacity(0.45))
                            }
                        }

                        if let todayEntryID = todayEntryID {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Tags")
                                    .font(.custom("AvenirNext-Medium", size: 12))
                                    .foregroundStyle(inkColor.opacity(0.6))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(JournalTag.allCases) { tag in
                                            let isSelected = entryTags[todayEntryID, default: []].contains(tag)
                                            Button {
                                                toggleTag(tag, for: todayEntryID)
                                            } label: {
                                                Text(tag.title)
                                                    .font(.custom("AvenirNext-Medium", size: 12))
                                                    .foregroundStyle(isSelected ? Color.black.opacity(0.9) : Color.black.opacity(0.65))
                                                    .padding(.vertical, 6)
                                                    .padding(.horizontal, 12)
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

                        HStack(spacing: 12) {
                            Button {
                                promptResponse = ""
                            } label: {
                                ReflectJournalActionButton(title: "Clear", systemImage: "xmark", fill: Color.black.opacity(0.06), textColor: inkColor.opacity(0.7))
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button {
                                let trimmed = promptResponse.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                upsertEntryForToday(promptResponse: trimmed)
                                promptResponse = ""
                                isEntryFocused = false
                            } label: {
                                ReflectJournalActionButton(
                                    title: "Save entry",
                                    systemImage: "checkmark",
                                    fill: LinearGradient(
                                        colors: [accentColor.opacity(0.18), accentColor.opacity(0.35)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    textColor: inkColor.opacity(0.9)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Consistency")
                        .font(.custom("Georgia", size: 22))
                        .foregroundStyle(inkColor.opacity(0.85))
                    ReflectJournalSurfaceCard {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Current streak")
                                    .font(.custom("AvenirNext-Medium", size: 12))
                                    .foregroundStyle(inkColor.opacity(0.6))
                                Text("\(currentStreak) days")
                                    .font(.custom("Georgia", size: 22))
                                    .foregroundStyle(inkColor.opacity(0.9))
                            }
                            Spacer()
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Longest streak")
                                    .font(.custom("AvenirNext-Medium", size: 12))
                                    .foregroundStyle(inkColor.opacity(0.6))
                                Text("\(longestStreak) days")
                                    .font(.custom("Georgia", size: 22))
                                    .foregroundStyle(inkColor.opacity(0.9))
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Achievements & Stamps")
                        .font(.custom("Georgia", size: 22))
                        .foregroundStyle(inkColor.opacity(0.85))
                    ReflectJournalSurfaceCard {
                        if earnedStamps.isEmpty {
                            Text("No stamps yet.")
                                .font(.custom("AvenirNext-Regular", size: 13))
                                .foregroundStyle(inkColor.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 10)
                        } else {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(earnedStamps) { stamp in
                                    HStack(spacing: 12) {
                                        ReflectStampBadge(stamp: stamp)
                                            .frame(width: 52, height: 52)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(stamp.title.uppercased())
                                                .font(.custom("AvenirNext-DemiBold", size: 12))
                                            Text(stamp.subtitle)
                                                .font(.custom("AvenirNext-Regular", size: 11))
                                                .foregroundStyle(inkColor.opacity(0.6))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                if !earnedStamps.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Stamps")
                            .font(.custom("AvenirNext-Medium", size: 13))
                            .foregroundStyle(inkColor.opacity(0.6))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(earnedStamps) { stamp in
                                    let isUsed = placedStamps.contains(where: { $0.stamp.id == stamp.id })
                                    Button {
                                        guard !isUsed else { return }
                                        placedStamps.append(
                                            ReflectPlacedStamp(
                                                stamp: stamp,
                                                position: CGPoint(x: 180, y: 36)
                                            )
                                        )
                                    } label: {
                                        ReflectStampBadge(stamp: stamp)
                                            .frame(width: 56, height: 56)
                                            .opacity(isUsed ? 0.35 : 1)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isUsed)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }

                ReflectNotebookView(
                    entries: $journalEntries,
                    placedStamps: $placedStamps,
                    loggedMoods: $loggedMoods,
                    entryTags: $entryTags
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
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
            let todayKey = ReflectDateKey(date: today, calendar: calendar)
            if let todayEntry = journalEntries.first(where: { ReflectDateKey(date: $0.date, calendar: calendar) == todayKey }) {
                promptResponse = todayEntry.promptResponse
                prompt = todayEntry.prompt
                onPromptChange(todayEntry.prompt)
            } else {
                let newEntry = ReflectJournalEntry(
                    date: today,
                    prompt: prompt,
                    promptResponse: "",
                    journalText: ""
                )
                journalEntries.insert(newEntry, at: 0)
            }
        }
        .onChange(of: journalEntries) { _ in
            ReflectJournalStore.saveEntries(journalEntries)
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


struct ReflectNotebookView: View {
    @Binding var entries: [ReflectJournalEntry]
    @Binding var placedStamps: [ReflectPlacedStamp]
    @Binding var loggedMoods: [ReflectDateKey: ReflectMoodOption]
    @Binding var entryTags: [UUID: Set<JournalTag>]
    private let headerHeight: CGFloat = 44
    @State private var selectedEntryID: UUID? = nil
    @FocusState private var focusedEntryID: UUID?
    private let calendar = Calendar.current
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let sortedEntryIndexes = entries.indices.sorted { entries[$0].date < entries[$1].date }
            let selectedEntry = entries.first { $0.id == selectedEntryID }
            let selectedMood: ReflectMoodOption? = {
                guard let date = selectedEntry?.date else { return nil }
                let key = ReflectDateKey(date: date, calendar: calendar)
                return loggedMoods[key]
            }()
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(red: 0.98, green: 0.97, blue: 0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.black.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 8)

                ReflectLinedPaper()
                    .padding(.leading, 28)
                    .padding(.trailing, 24)
                    .padding(.top, headerHeight + 20)
                    .opacity(entries.isEmpty ? 0.16 : 0.3)

                HStack(spacing: 12) {
                    VStack(spacing: 8) {
                        ForEach(0..<12, id: \.self) { _ in
                            Capsule()
                                .fill(Color.black.opacity(0.25))
                                .frame(width: 28, height: 5)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.leading, 12)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("My Journal")
                            .font(.custom("Georgia", size: 20))
                            .foregroundStyle(Color.black.opacity(0.8))
                        Spacer()
                        Text("\(entries.count) entries")
                            .font(.custom("AvenirNext-Medium", size: 11))
                            .foregroundStyle(Color.black.opacity(0.45))
                    }
                    .padding(.top, 18)
                    .padding(.horizontal, 28)

                    HStack {
                        Spacer()
                        Button {
                            guard let selectedEntry else { return }
                            let tagTitles = entryTags[selectedEntry.id, default: []]
                                .sorted(by: { $0.title < $1.title })
                                .map(\.title)
                            let shareCard = ShareableJournalCard(entry: selectedEntry, tagTitles: tagTitles)
                            let renderer = ImageRenderer(content: shareCard)
                            renderer.scale = UIScreen.main.scale
                            if let image = renderer.uiImage {
                                shareItems = [image]
                                showShareSheet = true
                            }
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.custom("AvenirNext-Medium", size: 12))
                                .foregroundStyle(Color.black.opacity(0.75))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 6)
                    .padding(.horizontal, 28)

                    Rectangle()
                        .fill(Color.black.opacity(0.08))
                        .frame(height: 1)
                        .padding(.horizontal, 28)

                    if entries.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.black.opacity(0.35))
                            Text("No entries yet")
                                .font(.custom("AvenirNext-Regular", size: 13))
                                .foregroundStyle(Color.black.opacity(0.55))
                            Text("Start with today's prompt above, then write freely here.")
                                .font(.custom("AvenirNext-Regular", size: 11))
                                .foregroundStyle(Color.black.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 34)
                    } else {
                        TabView(selection: $selectedEntryID) {
                            ForEach(sortedEntryIndexes, id: \.self) { index in
                                let entry = entries[index]
                                let promptLine = ReflectJournalPrompt.filledPrompt(
                                    entry.prompt,
                                    with: entry.promptResponse
                                )
                                let tags = entryTags[entry.id, default: []]
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(ReflectJournalPrompt.dateLabel(entry.date))
                                        .font(.custom("AvenirNext-Medium", size: 12))
                                        .foregroundStyle(Color.black.opacity(0.6))
                                    if entry.promptResponse.isEmpty {
                                        Text(ReflectJournalPrompt.displayPrompt(entry.prompt))
                                            .font(.custom("Georgia", size: 18))
                                            .foregroundStyle(Color.black.opacity(0.85))
                                    } else {
                                        promptLine
                                            .font(.custom("Georgia", size: 18))
                                            .foregroundStyle(Color.black.opacity(0.85))
                                    }
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
                                        TextEditor(text: $entries[index].journalText)
                                            .font(.custom("AvenirNext-Regular", size: 14))
                                            .foregroundStyle(Color.black.opacity(0.8))
                                            .scrollContentBackground(.hidden)
                                            .frame(minHeight: 120)
                                            .focused($focusedEntryID, equals: entry.id)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .fill(Color.white.opacity(0.7))
                                                    .overlay(
                                                        ReflectLinedPaper()
                                                            .padding(.horizontal, 10)
                                                            .padding(.top, 8)
                                                            .opacity(0.4)
                                                    )
                                                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 4)
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
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .padding(.top, 6)
                                .padding(.horizontal, 44)
                                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                                .tag(entry.id)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        .onAppear {
                            if selectedEntryID == nil {
                                selectedEntryID = sortedEntryIndexes.last.map { entries[$0].id }
                            }
                        }
                        .onChange(of: entries) { _ in
                            if let selectedEntryID,
                               sortedEntryIndexes.contains(where: { entries[$0].id == selectedEntryID }) {
                                return
                            }
                            selectedEntryID = sortedEntryIndexes.last.map { entries[$0].id }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                if let selectedMood {
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
        .frame(height: 380)
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: shareItems)
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

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ShareableJournalCard: View {
    let entry: ReflectJournalEntry
    let tagTitles: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Journal")
                .font(.custom("Georgia", size: 22))
                .foregroundStyle(Color.black.opacity(0.85))
            Text(ReflectJournalPrompt.dateLabel(entry.date))
                .font(.custom("AvenirNext-Medium", size: 12))
                .foregroundStyle(Color.black.opacity(0.6))
            if entry.promptResponse.isEmpty {
                Text(ReflectJournalPrompt.displayPrompt(entry.prompt))
                    .font(.custom("Georgia", size: 18))
                    .foregroundStyle(Color.black.opacity(0.85))
            } else {
                ReflectJournalPrompt.filledPrompt(entry.prompt, with: entry.promptResponse)
                    .font(.custom("Georgia", size: 18))
                    .foregroundStyle(Color.black.opacity(0.85))
            }
            if !tagTitles.isEmpty {
                HStack(spacing: 6) {
                    ForEach(tagTitles, id: \.self) { title in
                        Text(title)
                            .font(.custom("AvenirNext-Medium", size: 10))
                            .foregroundStyle(Color.black.opacity(0.7))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.12))
                            )
                    }
                }
            }
            if !entry.journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(entry.journalText)
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundStyle(Color.black.opacity(0.8))
            }
        }
        .padding(16)
        .frame(width: 300, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
        )
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
}

struct MoodLevelState: Identifiable, Codable, Equatable {
    let id = UUID()
    let label: String
    var value: Double
}

struct MoodLevelRow: View {
    @Binding var level: MoodLevelState
    let mood: ReflectMoodOption
    private let segmentValues: [Double] = [0, 0.25, 0.5, 0.75, 1]

    var body: some View {
        HStack(spacing: 14) {
            MoodAssetImage(assetName: mood.assetName, intensity: level.value)
                .frame(width: 28, height: 28)

            Text(level.label.capitalized)
                .font(.custom("AvenirNext-Regular", size: 14))
                .foregroundStyle(Color.black.opacity(0.8))
                .frame(width: 86, alignment: .leading)

            MoodLevelBar(value: $level.value, segmentValues: segmentValues)
                .frame(height: 26)
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
            let segmentCount = max(segmentValues.count - 1, 1)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)

                Rectangle()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: max(0, fillWidth))

                ForEach(1..<segmentCount, id: \.self) { idx in
                    Rectangle()
                        .fill(Color.black.opacity(0.08))
                        .frame(width: 1)
                        .position(
                            x: (width * CGFloat(idx)) / CGFloat(segmentCount),
                            y: proxy.size.height / 2
                        )
                }
            }
            .contentShape(Rectangle())
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
        VStack(spacing: 8) {
            Text(item.monthLabel)
                .font(.custom("AvenirNext-Medium", size: 12))
                .foregroundStyle(Color.black.opacity(0.75))
            MoodAssetImage(assetName: item.mood.assetName, intensity: 0.75)
                .frame(width: 64, height: 64)
            Text(item.mood.name)
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundStyle(Color.black.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.12))
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)
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
