//
//  ReflectView.swift
//  Nomie
//

import SwiftUI

struct ReflectView: View {
    @State private var loggedMoods: [ReflectDateKey: ReflectMoodOption] = [:]
    private let calendar = Calendar.current

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
                VStack(spacing: 22) {
                    ReflectHeader(title: "Reflect")

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
                        SelfJournalView()
                    } label: {
                        ReflectCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("Today's prompt")
                                        .font(.custom("AvenirNext-Medium", size: 13))
                                        .foregroundStyle(Color.black.opacity(0.6))
                                    Spacer()
                                    Text(journalDateLabel)
                                        .font(.custom("AvenirNext-Medium", size: 12))
                                        .foregroundStyle(Color.black.opacity(0.45))
                                }

                                Text("I enjoyed _____.")
                                    .font(.custom("Georgia", size: 22))
                                    .foregroundStyle(Color.black.opacity(0.88))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 6)

                                HStack(spacing: 8) {
                                    Image(systemName: "pencil.and.outline")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Log journal")
                                        .font(.custom("AvenirNext-Medium", size: 13))
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 16)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.black.opacity(0.1),
                                                    Color.black.opacity(0.18)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.85), lineWidth: 1)
                                        .blendMode(.softLight)
                                )
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 5)
                                .frame(maxWidth: .infinity, alignment: .center)
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
                                ReflectMiniChart()
                                    .frame(height: 120)
                                HStack {
                                    Spacer()
                                    Text("See more")
                                        .font(.custom("AvenirNext-Medium", size: 13))
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 20)
                                        .background(
                                            Capsule()
                                                .fill(Color.black.opacity(0.15))
                                        )
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color(red: 0.97, green: 0.97, blue: 0.97))
        }
    }
}

struct ReflectHeader: View {
    let title: String

    var body: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.7))
            Spacer()
            Text(title)
                .font(.custom("Georgia", size: 36))
                .foregroundStyle(Color.black.opacity(0.85))
            Spacer()
            Color.clear.frame(width: 18, height: 18)
        }
        .padding(.top, 6)
    }
}

struct ReflectSectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom("Georgia", size: 22))
            .foregroundStyle(Color.black.opacity(0.82))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReflectCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.18), lineWidth: 1)
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
                    .fill(Color.black.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                            .blendMode(.softLight)
                    )
                    .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 6)
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

struct ReflectMiniChart: View {
    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let width = proxy.size.width
            ZStack(alignment: .bottomLeading) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height * 0.1))
                    path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.3))
                }
                .stroke(Color.black.opacity(0.7), lineWidth: 1.5)

                Path { path in
                    path.move(to: CGPoint(x: 0, y: height * 0.9))
                    path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.2))
                }
                .stroke(Color.black.opacity(0.9), lineWidth: 2)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .medium))
                    .position(x: width * 0.9, y: height * 0.2)
            }
        }
    }
}

struct DailyMoodView: View {
    @Binding var loggedMoods: [ReflectDateKey: ReflectMoodOption]
    @State private var selectedMoodIndex = 0
    @State private var moodLevels: [MoodLevelState] = [
        .init(label: "stress", value: 0.5),
        .init(label: "fun", value: 0.5),
        .init(label: "laziness", value: 0.25),
        .init(label: "inspired", value: 0.75)
    ]
    @State private var currentMonth = Date()
    private let calendar = Calendar.current
    @Environment(\.dismiss) private var dismiss

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
                            ForEach($moodLevels) { $level in
                                MoodLevelRow(
                                    level: $level,
                                    mood: ReflectMoodOption.moods[selectedMoodIndex]
                                )
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
                            }
                            Spacer()
                            Text(monthTitle(currentMonth))
                                .font(.custom("Georgia", size: 22))
                            Spacer()
                            Button {
                                currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                            } label: {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.75))

                        HStack {
                            ForEach(["SU", "M", "TU", "W", "TH", "F", "S"], id: \.self) { day in
                                Text(day)
                                    .font(.custom("AvenirNext-DemiBold", size: 12))
                                    .frame(maxWidth: .infinity)
                            }
                        }

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
    @Binding var selectedMoodIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let positions = moodPositions(in: size, count: ReflectMoodOption.moods.count)
            let selectedMood = ReflectMoodOption.moods[selectedMoodIndex]

            ZStack {
                VStack(spacing: 8) {
                    MoodAssetImage(assetName: selectedMood.assetName, intensity: 0.85)
                        .frame(width: 130, height: 130)
                    Text(selectedMood.name)
                        .font(.custom("AvenirNext-Medium", size: 14))
                        .foregroundStyle(Color.black.opacity(0.8))
                }
                .position(x: center.x, y: center.y)

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

struct MonthlyMoodView: View {
    private let weekdays = ["SU", "M", "TU", "W", "TH", "F", "S"]
    private let days: [ReflectCalendarDay] = [
        .init(day: 1, color: .yellow),
        .init(day: 2, color: .gray),
        .init(day: 3, color: .green),
        .init(day: 4, color: .blue),
        .init(day: 5, color: .yellow),
        .init(day: 6, color: .yellow),
        .init(day: 7, color: .orange),
        .init(day: 8, color: .green),
        .init(day: 9, color: .orange),
        .init(day: 10, color: .yellow),
        .init(day: 11, color: .gray),
        .init(day: 12, color: .blue),
        .init(day: 13, color: .green),
        .init(day: 14, color: .pink),
        .init(day: 15, color: .orange),
        .init(day: 16, color: .gray),
        .init(day: 17, color: .gray),
        .init(day: 18, color: .pink),
        .init(day: 19, color: .yellow),
        .init(day: 20, color: .yellow),
        .init(day: 21, color: .orange),
        .init(day: 22, color: .gray),
        .init(day: 23, color: .yellow),
        .init(day: 24, color: .gray),
        .init(day: 25, color: .gray),
        .init(day: 26, color: .green),
        .init(day: 27, color: .blue),
        .init(day: 28, color: .gray)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ReflectCard {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Spacer()
                            Text("January 2026")
                                .font(.custom("Georgia", size: 22))
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 16, weight: .medium))

                        HStack {
                            ForEach(weekdays, id: \.self) { day in
                                Text(day)
                                    .font(.custom("AvenirNext-DemiBold", size: 12))
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                            ForEach(days) { day in
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(day.color.opacity(0.6))
                                        .frame(width: 26, height: 26)
                                    Text("\(day.day)")
                                        .font(.custom("AvenirNext-Regular", size: 11))
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 16) {
                    MonthPreviewCard(title: "Dec 2025")
                    MonthPreviewCard(title: "Nov 2025")
                }
                HStack(spacing: 16) {
                    MonthPreviewCard(title: "Oct 2025")
                    MonthPreviewCard(title: "Sept 2025")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }
}

struct MonthPreviewCard: View {
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.custom("AvenirNext-Medium", size: 14))
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.12))
                .frame(height: 90)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.6), lineWidth: 1)
        )
    }
}

struct PatternsTrendsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Patterns &\nTrends")
                    .font(.custom("Georgia", size: 32))

                Text("Mood vs. app usage")
                    .font(.custom("AvenirNext-Medium", size: 14))
                    .foregroundStyle(Color.black.opacity(0.7))

                ReflectCard {
                    ReflectMiniChart()
                        .frame(height: 160)
                }

                Text("Insights")
                    .font(.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundStyle(Color.black.opacity(0.7))

                ReflectCard {
                    Text("On days when Escape apps were over 2 hours, your stress levels were higher.")
                        .font(.custom("AvenirNext-Regular", size: 14))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }
}

struct SelfJournalView: View {
    @State private var entry = ""
    @State private var prompt = ReflectJournalPrompt.randomPrompt()
    @State private var journalEntries: [ReflectJournalEntry] = []
    @State private var placedStamps: [ReflectPlacedStamp] = []
    @State private var earnedStamps: [ReflectStampDefinition] = []
    @FocusState private var isEntryFocused: Bool
    private let today = Date()
    private let entryHint = "Keep it short — one to three sentences."

    private var wordCount: Int {
        entry.split { $0 == " " || $0 == "\n" || $0 == "\t" }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Self-Journal")
                    .font(.custom("Georgia", size: 32))
                    .foregroundStyle(Color.black.opacity(0.85))

                ReflectCard {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Today • \(ReflectJournalPrompt.dateLabel(today))")
                                .font(.custom("AvenirNext-Medium", size: 12))
                                .foregroundStyle(Color.black.opacity(0.55))
                            Spacer()
                            Button {
                                prompt = ReflectJournalPrompt.randomPrompt()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("New prompt")
                                        .font(.custom("AvenirNext-Medium", size: 11))
                                }
                                .foregroundStyle(Color.black.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }

                        Text("\"\(prompt)\"")
                            .font(.custom("Georgia", size: 22))
                            .foregroundStyle(Color.black.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 10) {
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $entry)
                                    .font(.custom("AvenirNext-Regular", size: 14))
                                    .foregroundStyle(Color.black.opacity(0.82))
                                    .padding(.horizontal, 6)
                                    .padding(.top, 8)
                                    .frame(minHeight: 120, maxHeight: 160)
                                    .scrollContentBackground(.hidden)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.white)
                                            .overlay(
                                                ReflectLinedPaper()
                                                    .padding(.horizontal, 12)
                                                    .padding(.top, 10)
                                                    .opacity(0.55)
                                            )
                                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)
                                    )
                                    .focused($isEntryFocused)

                                if entry.isEmpty {
                                    Text("Start writing...")
                                        .font(.custom("AvenirNext-Regular", size: 14))
                                        .foregroundStyle(Color.black.opacity(0.35))
                                        .padding(.horizontal, 14)
                                        .padding(.top, 16)
                                }
                            }

                            HStack {
                                Text(entryHint)
                                    .font(.custom("AvenirNext-Regular", size: 12))
                                    .foregroundStyle(Color.black.opacity(0.5))
                                Spacer()
                                Text("\(wordCount) words")
                                    .font(.custom("AvenirNext-Medium", size: 11))
                                    .foregroundStyle(Color.black.opacity(0.5))
                            }
                        }

                        HStack(spacing: 12) {
                            Button {
                                entry = ""
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("Clear")
                                        .font(.custom("AvenirNext-Medium", size: 12))
                                }
                                .foregroundStyle(Color.black.opacity(0.6))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 18)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.08))
                                )
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button {
                                let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                journalEntries.insert(
                                    ReflectJournalEntry(date: Date(), prompt: prompt, text: trimmed),
                                    at: 0
                                )
                                entry = ""
                                prompt = ReflectJournalPrompt.randomPrompt()
                                isEntryFocused = false
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Save entry")
                                        .font(.custom("AvenirNext-Medium", size: 13))
                                }
                                .foregroundStyle(Color.black.opacity(0.8))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 22)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.black.opacity(0.08),
                                                    Color.black.opacity(0.2)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                                        .blendMode(.softLight)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 6)
                                .shadow(color: Color.white.opacity(0.6), radius: 6, x: -2, y: -2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Achievements & Stamps")
                        .font(.custom("Georgia", size: 22))
                        .foregroundStyle(Color.black.opacity(0.85))
                    ReflectCard {
                        if earnedStamps.isEmpty {
                            Text("Unlock achievements and stamps to put on your journal.")
                                .font(.custom("AvenirNext-Regular", size: 13))
                                .foregroundStyle(Color.black.opacity(0.6))
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
                                                .foregroundStyle(Color.black.opacity(0.6))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Decorate your journal")
                        .font(.custom("AvenirNext-Medium", size: 13))
                        .foregroundStyle(Color.black.opacity(0.6))
                    if earnedStamps.isEmpty {
                        Text("Unlock achievements and stamps to put on your journal.")
                            .font(.custom("AvenirNext-Regular", size: 12))
                            .foregroundStyle(Color.black.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 6)
                    } else {
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
                    entries: journalEntries,
                    placedStamps: $placedStamps
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(Color(red: 0.97, green: 0.97, blue: 0.97))
        .onAppear {
            if journalEntries.isEmpty {
                journalEntries = ReflectJournalStore.loadEntries()
            }
        }
        .onChange(of: journalEntries) { _ in
            ReflectJournalStore.saveEntries(journalEntries)
        }
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

struct ReflectSegment: View {
    let text: String
    let isSelected: Bool

    var body: some View {
        Text(text)
            .font(.custom("AvenirNext-Medium", size: 13))
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(
                Capsule()
                    .fill(isSelected ? Color.black.opacity(0.2) : Color.black.opacity(0.1))
            )
    }
}

struct ReflectNotebookView: View {
    let entries: [ReflectJournalEntry]
    @Binding var placedStamps: [ReflectPlacedStamp]
    private let headerHeight: CGFloat = 44

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
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
                            Text("Start with today's prompt to fill your journal.")
                                .font(.custom("AvenirNext-Regular", size: 11))
                                .foregroundStyle(Color.black.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 34)
                    } else {
                        TabView {
                            ForEach(entries) { entry in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(ReflectJournalPrompt.dateLabel(entry.date))
                                        .font(.custom("AvenirNext-Medium", size: 12))
                                        .foregroundStyle(Color.black.opacity(0.6))
                                    Text("\"\(entry.prompt)\"")
                                        .font(.custom("Georgia", size: 18))
                                        .foregroundStyle(Color.black.opacity(0.85))
                                    Text(entry.text)
                                        .font(.custom("AvenirNext-Regular", size: 14))
                                        .foregroundStyle(Color.black.opacity(0.75))
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .padding(.top, 18)
                                .padding(.horizontal, 44)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

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
    }
}

struct ReflectMoodDayDisplay: Identifiable {
    let id = UUID()
    let dayLabel: String
    let dateLabel: String
    let mood: ReflectMoodOption?
}

struct ReflectJournalEntry: Identifiable, Codable, Equatable {
    let id = UUID()
    let date: Date
    let prompt: String
    let text: String
}

struct ReflectJournalPrompt {
    static let prompts: [String] = [
        "I enjoyed ...",
        "One small win today was ...",
        "I felt calm when ...",
        "Something that made me laugh ...",
        "I’m grateful for ...",
        "I learned that ..."
    ]

    static func randomPrompt() -> String {
        prompts.randomElement() ?? "I enjoyed ..."
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
}

struct MoodLevelState: Identifiable {
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
        let nowComponents = calendar.dateComponents([.year, .month], from: Date())
        let currentYear = nowComponents.year ?? 0
        let currentMonth = nowComponents.month ?? 0
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"

        var monthBuckets: [MonthKey: [ReflectMoodOption]] = [:]
        var monthDaySets: [MonthKey: Set<Int>] = [:]

        for (key, mood) in loggedMoods {
            let isPastMonth = (key.year < currentYear) || (key.year == currentYear && key.month < currentMonth)
            guard isPastMonth else { continue }
            let monthKey = MonthKey(year: key.year, month: key.month)
            monthBuckets[monthKey, default: []].append(mood)
            monthDaySets[monthKey, default: []].insert(key.day)
        }

        let sortedMonths = monthBuckets.keys.sorted {
            if $0.year != $1.year { return $0.year > $1.year }
            return $0.month > $1.month
        }

        let completedMonths = sortedMonths.filter { monthKey in
            guard let days = monthDaySets[monthKey] else { return false }
            var components = DateComponents()
            components.year = monthKey.year
            components.month = monthKey.month
            components.day = 1
            guard let date = calendar.date(from: components),
                  let range = calendar.range(of: .day, in: .month, for: date)
            else { return false }
            return days.count == range.count
        }

        return completedMonths.prefix(4).compactMap { monthKey in
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

struct ReflectCalendarDay: Identifiable {
    let id = UUID()
    let day: Int
    let color: Color
}

#Preview {
    ReflectView()
}
