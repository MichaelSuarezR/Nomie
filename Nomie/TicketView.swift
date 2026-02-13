//
//  TicketView.swift
//  Nomie
//

import SwiftUI

struct TicketView: View {
    @State private var storyIndex = 0

    private let storySlides = [
        TicketStoryPage(
            title: "The Late Night Drifter",
            subtitle: "“You chase thoughts when the world sleeps, finding comfort in the glow of midnight scrolls.”",
            goalsSummary: "You tracked 8 categories this week. 6 passed your goals.",
            breakdown: [
                TicketBreakdown(label: "Creativity", value: "4h 32m", progress: 0.7),
                TicketBreakdown(label: "Connection", value: "3h 45m", progress: 0.55)
            ],
            showsMiniTicket: true,
            kind: .insights
        ),
        TicketStoryPage(
            title: "App Spotlight",
            subtitle: "“The apps that shifted your attention this week.”",
            goalsSummary: "",
            breakdown: [],
            showsMiniTicket: false,
            kind: .appSpotlight
        ),
        TicketStoryPage(
            title: "Emotional Landscape",
            subtitle: "“Your mood and your screen time were linked more than usual.”",
            goalsSummary: "",
            breakdown: [],
            showsMiniTicket: false,
            kind: .moodLandscape
        ),
        TicketStoryPage(
            title: "Week-Over-Week Patterns",
            subtitle: "“You shifted more attention toward late evenings.”",
            goalsSummary: "",
            breakdown: [],
            showsMiniTicket: false,
            kind: .weekOverWeek
        ),
        TicketStoryPage(
            title: "The Intentional Pause",
            subtitle: "“You reached less often, and chose quiet more.”",
            goalsSummary: "You tracked 7 categories this week. 5 passed your goals.",
            breakdown: [
                TicketBreakdown(label: "Connection", value: "2h 28m", progress: 0.41),
                TicketBreakdown(label: "Creativity", value: "3h 22m", progress: 0.58)
            ],
            showsMiniTicket: false,
            kind: .stamps
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TicketSegmentedHeader()

                    TicketStoryCard(
                        page: storySlides[storyIndex],
                        pageCount: storySlides.count,
                        currentIndex: storyIndex
                    )
                    .overlay(
                        HStack(spacing: 0) {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        storyIndex = max(0, storyIndex - 1)
                                    }
                                }
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        storyIndex = min(storySlides.count - 1, storyIndex + 1)
                                    }
                                }
                        }
                    )
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .background(Color(red: 0.88, green: 0.88, blue: 0.88))
            .navigationTitle("Ticket")
        }
    }
}

private struct TicketSegmentedHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            TicketChip(title: "Archive", isSelected: true)
            TicketChip(title: "Week Ticket", isSelected: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }
}

private struct TicketStoryCard: View {
    let page: TicketStoryPage
    let pageCount: Int
    let currentIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.62, green: 0.62, blue: 0.62))
                    .frame(height: 190)

                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(red: 0.35, green: 0.35, blue: 0.35))
                        .frame(width: 40, height: 32)
                    Circle()
                        .fill(Color(red: 0.25, green: 0.25, blue: 0.25))
                        .frame(width: 30, height: 30)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(red: 0.45, green: 0.45, blue: 0.45))
                        .frame(width: 60, height: 32)
                }
                .padding(12)
            }

            Text(page.title)
                .font(.custom("AvenirNext-Bold", size: 24))
                .foregroundColor(.white)
                .padding(.horizontal, 12)

            TicketStoryProgress(pageCount: pageCount, currentIndex: currentIndex)
                .padding(.horizontal, 12)

            Text(page.subtitle)
                .font(.custom("AvenirNext-Italic", size: 13))
                .foregroundColor(Color.black.opacity(0.8))
                .padding(.horizontal, 12)

            TicketStoryBody(page: page)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.55, green: 0.55, blue: 0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(red: 0.35, green: 0.35, blue: 0.35), lineWidth: 3)
        )
    }
}

private struct TicketStoryBody: View {
    let page: TicketStoryPage

    var body: some View {
        switch page.kind {
        case .insights:
            TicketInsightsBody(page: page)
        case .appSpotlight:
            TicketAppSpotlightBody()
        case .moodLandscape:
            TicketMoodLandscapeBody()
        case .weekOverWeek:
            TicketWeekOverWeekBody()
        case .stamps:
            TicketStampsBody()
        }
    }
}

private struct TicketInsightsBody: View {
    let page: TicketStoryPage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if page.showsMiniTicket {
                TicketMiniCard()
            }

            TicketSectionLabel(text: "Active Streaks")
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(index < 5 ? Color.black.opacity(0.55) : Color.black.opacity(0.2))
                        .frame(width: 20, height: 20)
                }
            }
            Text("You opened your phone mindfully for 5 days straight.")
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(Color.black.opacity(0.7))

            TicketSectionLabel(text: "Pattern Insights")
            TicketPatternInsightsSection()

            TicketSectionLabel(text: "Goals Progress")
            Text(page.goalsSummary)
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(Color.black.opacity(0.7))

            TicketSectionLabel(text: "Weekly Category Breakdown")
            ForEach(page.breakdown) { item in
                TicketBarRow(label: item.label, value: item.value, progress: item.progress)
            }
        }
    }
}

private struct TicketAppSpotlightBody: View {
    private let cards = [
        TicketSpotlightCard(title: "Most Reduced Time", app: "Instagram", value: "1h 23m"),
        TicketSpotlightCard(title: "Most Used App", app: "Spotify", value: "2h 47m"),
        TicketSpotlightCard(title: "Most Productive App", app: "Notion", value: "1h 12m"),
        TicketSpotlightCard(title: "Most Surprising App", app: "Procreate", value: "Avg 48m"),
        TicketSpotlightCard(title: "Longest Session", app: "Kindle", value: "1h 38m"),
        TicketSpotlightCard(title: "Most Consistent App", app: "White Noise", value: "7 times"),
        TicketSpotlightCard(title: "Highest Pick-up Rate", app: "Messages", value: "89 times"),
        TicketSpotlightCard(title: "First Morning Reach", app: "Weather", value: "5 times"),
        TicketSpotlightCard(title: "Most Sticky App", app: "YouTube", value: "Avg 23m"),
        TicketSpotlightCard(title: "Fastest Abandon", app: "Email", value: "Avg 47s")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TicketSectionLabel(text: "App Spotlight")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(cards) { card in
                    TicketSpotlightCardView(card: card)
                }
            }

            TicketSectionLabel(text: "Reflection Highlights")
            VStack(alignment: .leading, spacing: 6) {
                TicketReflectionRow(left: "Instagram", right: "Spotify", value: "47 times")
                TicketReflectionRow(left: "Messages", right: "Instagram", value: "41 times")
                TicketReflectionRow(left: "Email", right: "Messages", value: "33 times")
            }

            TicketSectionLabel(text: "Attention Timeline")
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

private struct TicketStoryProgress: View {
    let pageCount: Int
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(index == currentIndex ? Color.black.opacity(0.7) : Color.black.opacity(0.2))
                    .frame(height: 5)
            }
        }
    }
}

private struct TicketChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.custom("AvenirNext-DemiBold", size: 12))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.black.opacity(0.15) : Color.black.opacity(0.08))
            )
    }
}

private struct TicketSectionLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .frame(width: 28, height: 12)
            Text(text)
                .font(.custom("AvenirNext-DemiBold", size: 12))
        }
    }
}

private struct TicketBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.black.opacity(0.25))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(Color.black.opacity(0.7))
        }
    }
}

private struct TicketBarRow: View {
    let label: String
    let value: String
    let progress: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.custom("AvenirNext-Medium", size: 12))
                Spacer()
                Text(value)
                    .font(.custom("AvenirNext-Regular", size: 12))
            }
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black.opacity(0.2))
                .frame(height: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.black.opacity(0.6))
                        .frame(width: max(20, 220 * progress), height: 6),
                    alignment: .leading
                )
        }
    }
}

private struct TicketStoryPage {
    let title: String
    let subtitle: String
    let goalsSummary: String
    let breakdown: [TicketBreakdown]
    let showsMiniTicket: Bool
    let kind: TicketStoryKind
}

private struct TicketBreakdown: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let progress: CGFloat
}

private enum TicketStoryKind {
    case insights
    case appSpotlight
    case moodLandscape
    case weekOverWeek
    case stamps
}

private struct TicketSpotlightCard: Identifiable {
    let id = UUID()
    let title: String
    let app: String
    let value: String
}

private struct TicketSpotlightCardView: View {
    let card: TicketSpotlightCard

    var body: some View {
        VStack(spacing: 10) {
            Text(card.title)
                .font(.custom("AvenirNext-DemiBold", size: 11))
                .multilineTextAlignment(.center)
            Text(card.app)
                .font(.custom("AvenirNext-Bold", size: 12))
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.2))
                .frame(width: 60, height: 50)
            HStack {
                Text(card.value)
                    .font(.custom("AvenirNext-DemiBold", size: 11))
                Spacer()
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
    }
}

private struct TicketReflectionRow: View {
    let left: String
    let right: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Text(left)
                .font(.custom("AvenirNext-Medium", size: 12))
            Image(systemName: "arrow.right")
                .font(.system(size: 12))
                .foregroundColor(Color.black.opacity(0.5))
            Text(right)
                .font(.custom("AvenirNext-Medium", size: 12))
            Spacer()
            Text("(\(value))")
                .font(.custom("AvenirNext-Regular", size: 11))
                .foregroundColor(Color.black.opacity(0.6))
        }
    }
}

private struct TicketPatternInsightsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TicketRadarChart()
                .frame(height: 240)

            VStack(alignment: .leading, spacing: 8) {
                TicketBoldBullet(
                    title: "This week, your phone was a companion in the quiet hours",
                    detail: "67% of your attention happened when the world was asleep, suggesting your phone became a tool for processing, reflecting, or unwinding."
                )
                TicketBoldBullet(
                    title: "Attention clustered around late nights and early mornings",
                    detail: "Peak usage between 11 PM and 2 AM. This looks like a week that needed either deeper rest or solitary thinking time."
                )
                TicketBoldBullet(
                    title: "Your rhythm favored depth over distraction",
                    detail: "Longer, focused sessions rather than constant checking. The night gave you permission to drift without interruption."
                )
            }
        }
    }
}

private struct TicketMoodLandscapeBody: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TicketSectionLabel(text: "Emotional Landscape")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                TicketMoodCard(title: "Dominant Mood", subtitle: "Contemplative", days: "4 days")
                TicketMoodCard(title: "Runner-up", subtitle: "Restless", days: "1 days")
                TicketMoodCard(title: "Bright Zone", subtitle: "Hopeful", days: "4 days")
                TicketMoodCard(title: "Challenge Zone", subtitle: "Overwhelmed", days: "1 days")
            }

            TicketSectionLabel(text: "Mood-to-Usage Correlation")
            Text("On days you felt contemplative, screen time was 31% higher and clustered late at night. You were searching, processing, or simply keeping yourself company.")
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(Color.black.opacity(0.75))

            TicketSectionLabel(text: "Reflection Highlights")
            VStack(alignment: .leading, spacing: 6) {
                TicketBullet(text: "“Couldn't sleep, so I read instead” — Wednesday")
                TicketBullet(text: "“Finally made progress on that idea” — Thursday")
                TicketBullet(text: "“Felt more like myself today” — Sunday")
            }
        }
    }
}

private struct TicketMoodCard: View {
    let title: String
    let subtitle: String
    let days: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.custom("AvenirNext-DemiBold", size: 12))
                Spacer()
                Text(days)
                    .font(.custom("AvenirNext-Regular", size: 10))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.15))
                    .cornerRadius(8)
            }
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.25))
                .frame(width: 60, height: 60)
            Text(subtitle)
                .font(.custom("AvenirNext-Medium", size: 12))
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
    }
}

private struct TicketWeekOverWeekBody: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TicketSectionLabel(text: "Week-Over-Week Patterns")

            TicketSectionLabel(text: "Usage Timing Shift")
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LAST WEEK")
                        .font(.custom("AvenirNext-DemiBold", size: 12))
                    TicketTimingRow(label: "Morning")
                    TicketTimingRow(label: "Afternoon")
                    TicketTimingRow(label: "Evening")
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("THIS WEEK")
                        .font(.custom("AvenirNext-DemiBold", size: 12))
                    TicketTimingRow(label: "Morning")
                    TicketTimingRow(label: "Afternoon")
                    TicketTimingRow(label: "Evening")
                }
            }

            Text("You shifted 38% more attention toward late evening and night hours.")
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(Color.black.opacity(0.75))

            TicketSectionLabel(text: "Category Shift")
            TicketShiftRow(label: "Entertainment", value: "1h 12m")
            TicketShiftRow(label: "Social Connection", value: "47m")
            TicketShiftRow(label: "Learning & Growth", value: "34m")

            TicketSectionLabel(text: "New Behaviors Detected")
            TicketBullet(text: "Started reading before bed 5 nights this week (new pattern!)")
            TicketBullet(text: "Music usage increased by 68% — sound became important")
            TicketBullet(text: "First time hitting “Do Not Disturb” consistently after 11 PM")

            TicketSectionLabel(text: "What Stayed Consistent")
            TicketBullet(text: "Morning screen time remains low (well done!)")
        }
    }
}

private struct TicketTimingRow: View {
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.custom("AvenirNext-Regular", size: 12))
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black.opacity(0.5))
                .frame(width: 90, height: 8)
        }
    }
}

private struct TicketShiftRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.custom("AvenirNext-Medium", size: 12))
            Spacer()
            Image(systemName: "arrow.up")
                .font(.system(size: 12))
                .foregroundColor(Color.black.opacity(0.7))
            Text(value)
                .font(.custom("AvenirNext-Regular", size: 12))
        }
    }
}

private struct TicketStampsBody: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TicketSectionLabel(text: "Stamp")
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .frame(height: 140)
                .overlay(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.black.opacity(0.25))
                            .frame(width: 60, height: 60)
                            .offset(x: -110, y: 10)
                        Circle()
                            .fill(Color.black.opacity(0.55))
                            .frame(width: 64, height: 64)
                            .offset(x: -30, y: -4)
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.black.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .offset(x: 20, y: -14)
                        Circle()
                            .fill(Color.black.opacity(0.65))
                            .frame(width: 64, height: 84)
                            .offset(x: 110, y: -2)
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.black.opacity(0.45))
                            .frame(width: 90, height: 60)
                            .offset(x: -30, y: 36)
                        Circle()
                            .fill(Color.black.opacity(0.35))
                            .frame(width: 70, height: 70)
                            .offset(x: 45, y: 32)
                    }
                )
        }
    }
}
private struct TicketBoldBullet: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.black.opacity(0.25))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text("\(title) — \(detail)")
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(Color.black.opacity(0.75))
        }
    }
}

private struct TicketRadarChart: View {
    private let labels = ["drifting", "connection", "creativity", "entertainment", "learning", "productivity"]
    private let seriesA: [CGFloat] = [0.85, 0.45, 0.35, 0.7, 0.25, 0.3]
    private let seriesB: [CGFloat] = [0.45, 0.6, 0.4, 0.25, 0.75, 0.7]

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = size * 0.35

            ZStack {
                TicketRadarGrid(center: center, radius: radius)

                TicketRadarPolygon(values: seriesA, center: center, radius: radius)
                    .stroke(Color.red.opacity(0.7), lineWidth: 1.5)
                    .background(
                        TicketRadarPolygon(values: seriesA, center: center, radius: radius)
                            .fill(Color.red.opacity(0.15))
                    )

                TicketRadarPolygon(values: seriesB, center: center, radius: radius)
                    .stroke(Color.blue.opacity(0.7), lineWidth: 1.5)
                    .background(
                        TicketRadarPolygon(values: seriesB, center: center, radius: radius)
                            .fill(Color.blue.opacity(0.15))
                    )

                ForEach(labels.indices, id: \.self) { index in
                    let angle = angleForIndex(index)
                    let labelPoint = point(center: center, radius: radius * 1.15, angle: angle)
                    Text(labels[index])
                        .font(.custom("AvenirNext-Regular", size: 11))
                        .foregroundColor(Color.black.opacity(0.7))
                        .position(labelPoint)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func angleForIndex(_ index: Int) -> CGFloat {
        CGFloat(-Double.pi / 2) + CGFloat(index) * (CGFloat(Double.pi * 2) / 6)
    }

    private func point(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }
}

private struct TicketRadarGrid: View {
    let center: CGPoint
    let radius: CGFloat

    var body: some View {
        ZStack {
            ForEach(1..<4) { ring in
                TicketRadarPolygon(values: Array(repeating: CGFloat(ring) / 3.0, count: 6), center: center, radius: radius)
                    .stroke(Color.black.opacity(0.25), lineWidth: 1)
            }

            ForEach(0..<6, id: \.self) { index in
                Path { path in
                    let angle = CGFloat(-Double.pi / 2) + CGFloat(index) * (CGFloat(Double.pi * 2) / 6)
                    let end = CGPoint(
                        x: center.x + cos(angle) * radius,
                        y: center.y + sin(angle) * radius
                    )
                    path.move(to: center)
                    path.addLine(to: end)
                }
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
            }
        }
    }
}

private struct TicketRadarPolygon: Shape {
    let values: [CGFloat]
    let center: CGPoint
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count == 6 else { return path }

        for index in 0..<6 {
            let angle = CGFloat(-Double.pi / 2) + CGFloat(index) * (CGFloat(Double.pi * 2) / 6)
            let point = CGPoint(
                x: center.x + cos(angle) * radius * values[index],
                y: center.y + sin(angle) * radius * values[index]
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

private struct TicketMiniCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 90, height: 70)
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Text("The Late Night")
                        .font(.custom("AvenirNext-Bold", size: 14))
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.black.opacity(0.15))
                        .frame(width: 120, height: 10)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.black.opacity(0.12))
                        .frame(width: 90, height: 10)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("CHARACTERISTICS:")
                    .font(.custom("AvenirNext-DemiBold", size: 10))
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Peak activity: 11 PM – 2 AM")
                    Text("• Night owl tendencies detected")
                    Text("• 67% of usage after 10 PM")
                }
                .font(.custom("AvenirNext-Regular", size: 10))
                .foregroundColor(Color.black.opacity(0.75))

                VStack(alignment: .leading, spacing: 6) {
                    TicketDriftRow(label: "DRIFT LEVEL", value: "8/10", filled: 8)
                    TicketDriftRow(label: "DRIFT LEVEL", value: "8/10", filled: 8)
                }
            }
            .padding(10)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
            )
            .cornerRadius(10)

            HStack {
                Text("Valid til Next Sun")
                    .font(.custom("AvenirNext-Regular", size: 10))
                    .foregroundColor(Color.black.opacity(0.6))
                Spacer()
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 60, height: 8)
            }
        }
        .padding(12)
        .background(Color(red: 0.83, green: 0.83, blue: 0.83))
        .cornerRadius(16)
    }
}

private struct TicketDriftRow: View {
    let label: String
    let value: String
    let filled: Int

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.custom("AvenirNext-DemiBold", size: 9))
                .foregroundColor(Color.black.opacity(0.7))
            HStack(spacing: 2) {
                ForEach(0..<10, id: \.self) { index in
                    Rectangle()
                        .fill(index < filled ? Color.black.opacity(0.75) : Color.black.opacity(0.15))
                        .frame(width: 8, height: 8)
                }
            }
            Text(value)
                .font(.custom("AvenirNext-DemiBold", size: 9))
                .foregroundColor(Color.black.opacity(0.7))
        }
    }
}
