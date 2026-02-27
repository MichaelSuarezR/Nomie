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
            heroImageName: "LND",
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
            heroImageName: "LND",
            breakdown: [],
            showsMiniTicket: false,
            kind: .appSpotlight
        ),
        TicketStoryPage(
            title: "Emotional Landscape",
            subtitle: "“Your mood and your screen time were linked more than usual.”",
            goalsSummary: "",
            heroImageName: "LND",
            breakdown: [],
            showsMiniTicket: false,
            kind: .moodLandscape
        ),
        TicketStoryPage(
            title: "Week-Over-Week Patterns",
            subtitle: "“You shifted more attention toward late evenings.”",
            goalsSummary: "",
            heroImageName: "LND",
            breakdown: [],
            showsMiniTicket: false,
            kind: .weekOverWeek
        ),
        TicketStoryPage(
            title: "The Intentional Pause",
            subtitle: "“You reached less often, and chose quiet more.”",
            goalsSummary: "You tracked 7 categories this week. 5 passed your goals.",
            heroImageName: "LND",
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
            ZStack {
                TicketBackgroundView()

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
                    .nomieTabBarContentPadding()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    TicketView()
}

private struct TicketSegmentedHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            TicketChip(title: "Archive", isSelected: false)
                .frame(maxWidth: .infinity, alignment: .center)
            TicketChip(title: "Week Ticket", isSelected: true)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 8)
    }
}

private struct TicketBackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.97, green: 0.86, blue: 0.70),
                Color(red: 0.96, green: 0.78, blue: 0.64),
                Color(red: 0.95, green: 0.70, blue: 0.62)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.35),
                    Color.clear,
                    Color.white.opacity(0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea()
    }
}

private struct TicketHeroImage: View {
    let title: String
    let imageName: String?

    var body: some View {
        ZStack {
            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(1.03)
                    .scaleEffect(x: -1, y: 1)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.32, blue: 0.62),
                        Color(red: 0.04, green: 0.25, blue: 0.48),
                        Color(red: 0.02, green: 0.18, blue: 0.38)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                Text(displayTitle)
                    .font(.custom("SortsMillGoudy-Regular", size: 32))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .shadow(color: Color.black.opacity(0.95), radius: 16, x: 0, y: 8)
                    .shadow(color: Color.black.opacity(0.85), radius: 28, x: 0, y: 14)
                    .shadow(color: Color.black.opacity(0.6), radius: 40, x: 0, y: 20)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }

    private var displayTitle: String {
        if title == "The Late Night Drifter" {
            return "The Late\nNight Drifter"
        }
        return title
    }
}

private struct TicketStoryCard: View {
    let page: TicketStoryPage
    let pageCount: Int
    let currentIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TicketHeroImage(title: page.title, imageName: page.heroImageName)
                .frame(height: 290)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 0)

            TicketStoryProgress(pageCount: pageCount, currentIndex: currentIndex)
                .padding(.horizontal, 12)

            Text(page.subtitle)
                .font(.custom("SortsMillGoudy-Italic", size: 16))
                .foregroundColor(Color(red: 0.32, green: 0.41, blue: 0.28))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.top, 2)

            TicketStoryBody(page: page)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.98, green: 0.97, blue: 0.93))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 8)
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
                GeometryReader { proxy in
                    Image("LNDT")
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width * 1.12)
                        .offset(x: -5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: 300)
            }

            HStack(spacing: 8) {
                TicketSectionLabel(text: "Active Streaks:")
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .overlay(
                            Image("Streak")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                        )
                    Text("12")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(Color(red: 0.32, green: 0.41, blue: 0.28))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
            }

            HStack(spacing: 10) {
                ForEach(0..<7, id: \.self) { index in
                    Circle()
                        .fill(index < 5 ? Color.black.opacity(0.6) : Color.black.opacity(0.25))
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.vertical, 6)

            Text("You opened your phone mindfully for 5 days\nstraight.")
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(Color(red: 0.32, green: 0.41, blue: 0.28))

            TicketSectionLabel(text: "Pattern Insights:")
            TicketPatternInsightsSection()

            HStack(spacing: 6) {
                Image("target")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 23, height: 23)
                    .clipShape(Circle())
                    .offset(y: -2)
                Text("Goals Progress")
                    .font(.custom("SortsMillGoudy-Regular", size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.32, green: 0.41, blue: 0.28))
            }
            Text(page.goalsSummary)
                .font(.custom("Poppins-Regular", size: 11))
                .foregroundColor(Color.black.opacity(0.65))

            TicketSectionLabel(text: "Weekly Category Breakdown")
            ForEach(fullBreakdown) { item in
                TicketBarRow(label: item.label, value: item.value, progress: item.progress)
            }
        }
    }
}

private let fullBreakdown: [TicketBreakdown] = [
    TicketBreakdown(label: "Creativity", value: "4h 32m", progress: 0.72),
    TicketBreakdown(label: "Connection", value: "3h 45m", progress: 0.62),
    TicketBreakdown(label: "Drifting", value: "2h 58m", progress: 0.52),
    TicketBreakdown(label: "Entertainment", value: "1h 40m", progress: 0.38),
    TicketBreakdown(label: "Learning", value: "52m", progress: 0.22),
    TicketBreakdown(label: "Productivity", value: "46m", progress: 0.20)
]

private struct TicketAppSpotlightBody: View {
    private let cards = [
        TicketSpotlightCard(title: "Most Reduced Time", app: "Instagram", value: "1h 23m", detail: "You reclaimed nearly 90 minutes. That's a whole movie worth of attention.", icon: "camera"),
        TicketSpotlightCard(title: "Most Used App", app: "Spotify", value: "2h 5m", detail: "Your midnight soundtrack. Music was your anchor this week.", icon: "music.note"),
        TicketSpotlightCard(title: "Most Productive App", app: "Notion", value: "1h 12m", detail: "Late-night planning and journaling helped you organize thoughts.", icon: "note.text"),
        TicketSpotlightCard(title: "Most Surprising App", app: "Procreate", value: "1h 23m", detail: "You spent a lot of time unleashing creativity in late nights.", icon: "paintbrush"),
        TicketSpotlightCard(title: "Longest Session", app: "Kindle", value: "2h 8m", detail: "You dove deep on Thursday night. What were you reading?", icon: "book"),
        TicketSpotlightCard(title: "Most Consistent App", app: "White Noise", value: "7 times", detail: "You opened every night at 11:47 PM avg. Your sleep ritual is forming.", icon: "waveform")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TicketSectionLabel(text: "App Spotlight")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(cards) { card in
                    TicketSpotlightCardView(card: card)
                }
            }

            HStack {
                Spacer()
                Text("Load more")
                    .font(.custom("SortsMillGoudy-Regular", size: 14))
                    .foregroundColor(Color(red: 0.32, green: 0.41, blue: 0.28))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )
                Spacer()
            }
        }
    }
}

private struct TicketStoryProgress: View {
    let pageCount: Int
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<pageCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        index == currentIndex
                        ? LinearGradient(
                            colors: [
                                Color(red: 0.96, green: 0.79, blue: 0.62),
                                Color(red: 0.90, green: 0.70, blue: 0.52)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [
                                Color(red: 0.86, green: 0.90, blue: 0.70),
                                Color(red: 0.86, green: 0.90, blue: 0.70)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
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
            .font(.custom("SortsMillGoudy-Regular", size: 18))
            .foregroundColor(Color(red: 0.24, green: 0.32, blue: 0.20))
            .padding(.horizontal, 26)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(red: 0.83, green: 0.88, blue: 0.70), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

private struct TicketSectionLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image("sunset")
                .resizable()
                .scaledToFill()
                .frame(width: 23, height: 23)
                .clipShape(Circle())
                .offset(y: -2)
            Text(text)
                .font(.custom("SortsMillGoudy-Regular", size: 20))
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.32, green: 0.41, blue: 0.28))
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
        HStack(spacing: 12) {
            Text(label)
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(Color(red: 0.32, green: 0.41, blue: 0.28))
                .frame(width: 110, alignment: .leading)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.89, green: 0.93, blue: 0.76))
                .frame(height: 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.78, blue: 0.58),
                                    Color(red: 0.92, green: 0.70, blue: 0.62)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(24, 200 * progress), height: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color(red: 0.64, green: 0.49, blue: 0.45), lineWidth: 1)
                        )
                        .padding(.leading, 2),
                    alignment: .leading
                )

            Text(value)
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(Color(red: 0.32, green: 0.41, blue: 0.28))
                .frame(width: 60, alignment: .trailing)
        }
    }
}

private struct TicketStoryPage {
    let title: String
    let subtitle: String
    let goalsSummary: String
    let heroImageName: String?
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
    let detail: String
    let icon: String
}

private struct TicketSpotlightCardView: View {
    let card: TicketSpotlightCard

    var body: some View {
        let appImage = appAssetName(for: card.app)
        VStack(alignment: .leading, spacing: 8) {
            Text(card.title)
                .font(.custom("Poppins-Regular", size: 10))
                .foregroundColor(Color(red: 0.32, green: 0.41, blue: 0.28))
            Text(card.app)
                .font(.custom("SortsMillGoudy-Regular", size: 14))
                .foregroundColor(Color(red: 0.32, green: 0.41, blue: 0.28))
            Group {
                if let appImage {
                    Image(appImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    Image(systemName: card.icon)
                        .font(.system(size: 28))
                        .foregroundColor(Color(red: 0.18, green: 0.27, blue: 0.40))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.9))
                        )
                }
            }
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            .padding(.vertical, 2)
            Text(card.detail)
                .font(.custom("Poppins-Regular", size: 10))
                .foregroundColor(Color(red: 0.32, green: 0.41, blue: 0.28))
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Text(card.value)
                    .font(.custom("SortsMillGoudy-Regular", size: 12))
                    .foregroundColor(Color(red: 0.32, green: 0.41, blue: 0.28))
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.85))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.12), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

private func appAssetName(for app: String) -> String? {
    let key = app.lowercased().replacingOccurrences(of: " ", with: "")
    return key.isEmpty ? nil : key
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

            TicketSummaryCard()
        }
    }
}

private struct TicketSummaryCard: View {
    var body: some View {
        ZStack {
            Image("ticket")
                .resizable()
                .scaledToFit()
                .frame(height: 520)

            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    Image("LND")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 350, height: 230)
                        .scaleEffect(x: -1, y: 1)
                        .clipped()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, -240)

                    OutlinedTitle(text: "The Late\nNight Drifter", size: 42, stroke: 2)
                        .padding(.leading, 34)
                        .padding(.bottom, 20)
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TOP APPS")
                                .font(.custom("AvenirNext-Bold", size: 12))
                                .foregroundColor(Color.black.opacity(0.7))
                            SummaryAppRow(rank: "1.", name: "Spotify", time: "4h 12m", imageName: "spotify")
                            SummaryAppRow(rank: "2.", name: "Instagram", time: "2h 30m", imageName: "instagram")
                            SummaryAppRow(rank: "3.", name: "Flora", time: "1h 52m", imageName: "flora")
                        }

                        Spacer()

                        TicketRadarChart()
                            .frame(width: 120, height: 120)
                    }

                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.black.opacity(0.1))
                            .frame(height: 54)
                            .frame(maxWidth: .infinity)
                    }
                }

                    Rectangle()
                        .fill(Color.black.opacity(0.18))
                        .frame(height: 1)

                    HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("01.18.26")
                            .font(.custom("AvenirNext-Regular", size: 12))
                            .foregroundColor(Color.black.opacity(0.6))
                        Image("NOMIE")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 36)
                    }

                        Spacer()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("DAILY AVG: 3h 4m")
                            Text("MY HOUR: 12:00 AM")
                            Text("STREAK: 7 days")
                            Text("PICKUPS: 106")
                        }
                        .font(.custom("AvenirNext-Regular", size: 11))
                        .foregroundColor(Color.black.opacity(0.6))
                    }
                }
                .padding(18)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 6)
    }
}

private struct OutlinedTitle: View {
    let text: String
    let size: CGFloat
    let stroke: CGFloat

    init(text: String, size: CGFloat = 30, stroke: CGFloat = 1) {
        self.text = text
        self.size = size
        self.stroke = stroke
    }

    var body: some View {
        ZStack {
            Text(text)
                .font(.custom("SortsMillGoudy-Regular", size: size))
                .foregroundColor(Color(red: 0.10, green: 0.25, blue: 0.55))
                .offset(x: stroke, y: 0)
            Text(text)
                .font(.custom("SortsMillGoudy-Regular", size: size))
                .foregroundColor(Color(red: 0.10, green: 0.25, blue: 0.55))
                .offset(x: -stroke, y: 0)
            Text(text)
                .font(.custom("SortsMillGoudy-Regular", size: size))
                .foregroundColor(Color(red: 0.10, green: 0.25, blue: 0.55))
                .offset(x: 0, y: stroke)
            Text(text)
                .font(.custom("SortsMillGoudy-Regular", size: size))
                .foregroundColor(Color(red: 0.10, green: 0.25, blue: 0.55))
                .offset(x: 0, y: -stroke)
            Text(text)
                .font(.custom("SortsMillGoudy-Regular", size: size))
                .foregroundColor(.white)
        }
        .multilineTextAlignment(.leading)
    }
}

private struct TicketPunches: View {
    let holeColor: Color

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let count = 7
            let spacing = width / CGFloat(count)
            let diameter: CGFloat = 18

            VStack {
                HStack(spacing: spacing - diameter) {
                    ForEach(0..<count, id: \.self) { _ in
                        Circle()
                            .fill(holeColor)
                            .frame(width: diameter, height: diameter)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, -diameter / 2)

                Spacer()

                HStack(spacing: spacing - diameter) {
                    ForEach(0..<count, id: \.self) { _ in
                        Circle()
                            .fill(holeColor)
                            .frame(width: diameter, height: diameter)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, -diameter / 2)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct SummaryAppRow: View {
    let rank: String
    let name: String
    let time: String
    let imageName: String

    var body: some View {
        HStack(spacing: 6) {
            Text(rank)
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(Color.black.opacity(0.6))
                .frame(width: 18, alignment: .leading)
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .foregroundColor(Color.black.opacity(0.75))
                Text(time)
                    .font(.custom("AvenirNext-Regular", size: 11))
                    .foregroundColor(Color.black.opacity(0.6))
            }
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

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = size * 0.35

            ZStack {
                TicketRadarGrid(center: center, radius: radius)

                TicketRadarPolygon(values: seriesA, center: center, radius: radius)
                    .stroke(Color.red.opacity(0.75), lineWidth: 1.5)
                    .background(
                        TicketRadarPolygon(values: seriesA, center: center, radius: radius)
                            .fill(Color.red.opacity(0.18))
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.24, green: 0.44, blue: 0.66),
                                    Color(red: 0.10, green: 0.28, blue: 0.48)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 56, height: 56)
                        .offset(x: -8, y: -6)
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.8))
                        .offset(x: -22, y: -20)
                    ForEach(0..<12, id: \.self) { index in
                        Circle()
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 3, height: 3)
                            .offset(x: CGFloat(-20 + (index * 6 % 40)), y: CGFloat(18 + (index * 4 % 24)))
                    }
                }
                .frame(width: 90, height: 70)

                VStack(alignment: .leading, spacing: 6) {
                    Text("The Late Night Drifter")
                        .font(.custom("SortsMillGoudy-Regular", size: 16))
                        .foregroundColor(.white)
                    Text("ISSUED: 2026/2/2  –  2026/2/9")
                        .font(.custom("Poppins-Regular", size: 9))
                        .foregroundColor(Color.white.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("CHARACTERISTICS:")
                        .font(.custom("Poppins-Regular", size: 10))
                        .foregroundColor(.white)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("• Peak activity: 12PM–2AM")
                    Text("• Night owl tendencies detected")
                    Text("• 67% of usage after 10PM")
                    Text("• Screen time spikes during night")
                }
                .font(.custom("Poppins-Regular", size: 9))
                .foregroundColor(Color.white.opacity(0.85))
            }
            .padding(10)
            .background(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            )
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 6) {
                TicketDriftRow(label: "DRIFT LEVEL", value: "8/10", filled: 8)
                TicketDriftRow(label: "FOCUS LEVEL", value: "3/10", filled: 3)
                TicketDriftRow(label: "ENERGY LEVEL", value: "2/10", filled: 2)
            }

            HStack {
                Text("Finding clarity in chaos, one might scroll at a time.")
                    .font(.custom("SortsMillGoudy-Italic", size: 10))
                    .foregroundColor(Color.white.opacity(0.85))
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("VALID TIL NEXT SUN")
                        .font(.custom("Poppins-Regular", size: 8))
                        .foregroundColor(Color.white.opacity(0.8))
                    HStack(spacing: 2) {
                        ForEach(0..<14, id: \.self) { index in
                            Rectangle()
                                .fill(Color.white.opacity(index.isMultiple(of: 3) ? 0.8 : 0.6))
                                .frame(width: 3, height: 18)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.25, blue: 0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 0.05, green: 0.20, blue: 0.38), lineWidth: 2)
        )
    }
}

private struct TicketDriftRow: View {
    let label: String
    let value: String
    let filled: Int

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.custom("Poppins-Regular", size: 9))
                .foregroundColor(Color.white.opacity(0.85))
            HStack(spacing: 2) {
                ForEach(0..<10, id: \.self) { index in
                    Rectangle()
                        .fill(index < filled ? Color.white.opacity(0.95) : Color.white.opacity(0.25))
                        .frame(width: 8, height: 8)
                        .cornerRadius(2)
                }
            }
            Text(value)
                .font(.custom("Poppins-Regular", size: 9))
                .foregroundColor(Color.white.opacity(0.85))
        }
    }
}
