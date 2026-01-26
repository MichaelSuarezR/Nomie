//
//  ReflectView.swift
//  Nomie
//

import SwiftUI

struct ReflectView: View {
    private let moodDays: [ReflectMoodDay] = [
        .init(day: "SU", date: "1.18", mood: "Happy"),
        .init(day: "M", date: "1.19", mood: "Fine"),
        .init(day: "TU", date: "1.20", mood: "Frustrated"),
        .init(day: "W", date: "1.21", mood: "Anxious"),
        .init(day: "TH", date: "1.22", mood: "Excited"),
        .init(day: "F", date: "1.23", mood: "Sad"),
        .init(day: "S", date: "1.24", mood: "Tired")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    ReflectHeader(title: "Reflect")

                    ReflectSectionTitle(text: "Daily Mood")
                    NavigationLink {
                        DailyMoodView()
                    } label: {
                        ReflectCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Past 7 days")
                                    .font(.custom("AvenirNext-Medium", size: 14))
                                    .foregroundStyle(Color.black.opacity(0.6))
                                HStack(spacing: 12) {
                                    ForEach(moodDays) { day in
                                        VStack(spacing: 6) {
                                            Circle()
                                                .fill(Color.black.opacity(0.15))
                                                .frame(width: 32, height: 32)
                                            Text(day.day)
                                                .font(.custom("AvenirNext-Medium", size: 12))
                                            Text(day.date)
                                                .font(.custom("AvenirNext-Regular", size: 11))
                                                .foregroundStyle(Color.black.opacity(0.6))
                                            Text(day.mood)
                                                .font(.custom("AvenirNext-Regular", size: 10))
                                                .foregroundStyle(Color.black.opacity(0.6))
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.15))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "plus")
                                            .foregroundStyle(Color.black.opacity(0.7))
                                    }
                                    Text("Log Mood")
                                        .font(.custom("AvenirNext-Medium", size: 13))
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    ReflectSectionTitle(text: "Self-Journal")
                    NavigationLink {
                        SelfJournalView()
                    } label: {
                        ReflectCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Today's prompt:")
                                    .font(.custom("AvenirNext-Medium", size: 13))
                                    .foregroundStyle(Color.black.opacity(0.6))
                                Text("I enjoyed _____.")
                                    .font(.custom("Georgia", size: 22))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                Text("Log journal")
                                    .font(.custom("AvenirNext-Medium", size: 13))
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 24)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.15))
                                    )
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
                    .stroke(Color.black.opacity(0.6), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )
            )
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
    @State private var selectedMoodIndex = 1
    @State private var moodLevels: [MoodLevelState] = [
        .init(label: "stress", value: 0.5),
        .init(label: "fun", value: 0.5),
        .init(label: "laziness", value: 0.25),
        .init(label: "inspired", value: 0.75)
    ]
    @State private var currentMonth = Date()
    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Daily Mood")
                    .font(.custom("Georgia", size: 32))
                Text("How was your mood today?")
                    .font(.custom("AvenirNext-Regular", size: 15))
                    .foregroundStyle(Color.black.opacity(0.7))

                VStack(spacing: 8) {
                    Text("Scroll to choose a mood")
                        .font(.custom("AvenirNext-Regular", size: 12))
                        .foregroundStyle(Color.black.opacity(0.55))

                    HStack(spacing: 10) {
                        Button {
                            selectedMoodIndex = max(0, selectedMoodIndex - 1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.black.opacity(0.6))
                        }

                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 18) {
                                    ForEach(ReflectMoodOption.moods.indices, id: \.self) { idx in
                                        let mood = ReflectMoodOption.moods[idx]
                                        Button {
                                            selectedMoodIndex = idx
                                        } label: {
                                            MoodSelectorPreview(
                                                mood: mood,
                                                size: idx == selectedMoodIndex ? 86 : 66,
                                                isSelected: idx == selectedMoodIndex
                                            )
                                            .id(idx)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                            }
                            .onChange(of: selectedMoodIndex) { _, newValue in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    proxy.scrollTo(newValue, anchor: .center)
                                }
                            }
                            .onAppear {
                                proxy.scrollTo(selectedMoodIndex, anchor: .center)
                            }
                        }

                        Button {
                            selectedMoodIndex = min(ReflectMoodOption.moods.count - 1, selectedMoodIndex + 1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.black.opacity(0.6))
                        }
                    }
                }
                .padding(.vertical, 6)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Mood levels (0% to 100%)")
                        .font(.custom("Georgia", size: 22))
                    Text("How much did you experience each of these moods today?")
                        .font(.custom("AvenirNext-Regular", size: 13))
                        .foregroundStyle(Color.black.opacity(0.6))
                    ReflectCard {
                        VStack(spacing: 14) {
                            ForEach($moodLevels) { $level in
                                HStack(spacing: 12) {
                                    MoodAssetImage(
                                        assetName: ReflectMoodOption.moods[selectedMoodIndex].assetName,
                                        intensity: level.value
                                    )
                                    .frame(width: 32, height: 32)
                                    Text(level.label)
                                        .font(.custom("AvenirNext-Regular", size: 14))
                                        .foregroundStyle(Color.black.opacity(0.8))
                                        .frame(width: 80, alignment: .leading)
                                    Slider(value: $level.value, in: 0...1, step: 0.25)
                                        .accentColor(Color.black.opacity(0.7))
                                    Text("\(Int(level.value * 100))%")
                                        .font(.custom("AvenirNext-Medium", size: 12))
                                        .foregroundStyle(Color.black.opacity(0.7))
                                }
                            }
                        }
                    }
                    Text("Tap or drag sliders in 25% steps.")
                        .font(.custom("AvenirNext-Regular", size: 12))
                        .foregroundStyle(Color.black.opacity(0.45))
                    Text("0% = not at all, 100% = very much.")
                        .font(.custom("AvenirNext-Regular", size: 12))
                        .foregroundStyle(Color.black.opacity(0.45))
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
                        .foregroundStyle(Color.black.opacity(0.8))

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
                                        MoodAssetImage(
                                            assetName: moodForDay(day).assetName,
                                            intensity: 0.7
                                        )
                                        .frame(width: 26, height: 26)
                                        Text("\(day)")
                                            .font(.custom("AvenirNext-Regular", size: 11))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }
}

struct MoodAssetImage: View {
    let assetName: String
    let intensity: Double

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .saturation(0.6 + (0.4 * intensity))
            .opacity(0.4 + (0.6 * intensity))
            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 4)
    }
}

struct MoodSelectorPreview: View {
    let mood: ReflectMoodOption
    let size: CGFloat
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            MoodAssetImage(assetName: mood.assetName, intensity: 0.7)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.black.opacity(0.6) : Color.clear, lineWidth: 1)
                )
            Text(mood.name)
                .font(.custom("AvenirNext-Regular", size: isSelected ? 13 : 11))
                .foregroundStyle(.primary)
                .opacity(isSelected ? 0.9 : 0.7)
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
    @State private var filter = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Self-Journal")
                    .font(.custom("Georgia", size: 32))

                ReflectCard {
                    VStack(spacing: 12) {
                        Text("Today (1/22)'s prompt:")
                            .font(.custom("AvenirNext-Medium", size: 14))
                            .foregroundStyle(Color.black.opacity(0.7))
                        Text("\"I enjoyed ...\"")
                            .font(.custom("Georgia", size: 22))
                        TextField("type here", text: $entry)
                            .font(.custom("AvenirNext-Regular", size: 14))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.12))
                            )
                    }
                }

                HStack(spacing: 10) {
                    ReflectSegment(text: "Today", isSelected: filter == 0)
                        .onTapGesture { filter = 0 }
                    ReflectSegment(text: "This week", isSelected: filter == 1)
                        .onTapGesture { filter = 1 }
                    ReflectSegment(text: "Last week", isSelected: filter == 2)
                        .onTapGesture { filter = 2 }
                }

                ReflectNotebookView()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
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
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.6), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white)
                )
                .frame(height: 360)

            HStack(spacing: 12) {
                VStack(spacing: 8) {
                    ForEach(0..<12, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Color.black.opacity(0.25))
                            .frame(width: 26, height: 6)
                    }
                }
                .padding(.leading, 12)

                Spacer()
            }

            Button(action: {}) {
                Text("My Journal")
                    .font(.custom("AvenirNext-Medium", size: 14))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 22)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.15))
                    )
            }
        }
    }
}

struct ReflectMoodDay: Identifiable {
    let id = UUID()
    let day: String
    let date: String
    let mood: String
}

struct ReflectMoodOption: Identifiable, Equatable {
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

extension DailyMoodView {
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

    private func moodForDay(_ day: Int) -> ReflectMoodOption {
        let moods = ReflectMoodOption.moods
        return moods[day % moods.count]
    }
}

struct ReflectCalendarDay: Identifiable {
    let id = UUID()
    let day: Int
    let color: Color
}

#Preview {
    ReflectView()
}
