//
//  TicketView.swift
//  Nomie
//

import SwiftUI
import Combine

struct TicketView: View {
    @State private var showRecap = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    TicketHeader()
                    Button {
                        showRecap = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "play.circle.fill")
                            Text("Weekly Nomie Recap")
                                .font(.custom("AvenirNext-Bold", size: 16))
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(red: 0.18, green: 0.31, blue: 0.43))
                        )
                    }
                    TicketCard()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.89, green: 0.90, blue: 0.93), Color(red: 0.95, green: 0.96, blue: 0.98)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Ticket")
            .fullScreenCover(isPresented: $showRecap) {
                TicketStoryOverlay(isPresented: $showRecap)
            }
        }
    }
}

struct TicketHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your weekly phone diary, printed as a story.")
                .font(.custom("AvenirNext-Medium", size: 18))
                .foregroundStyle(Color.black.opacity(0.7))
            HStack(spacing: 10) {
                TicketPill(text: "Week 03 · Jan 20–26")
                TicketPill(text: "Archive")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }
}

struct TicketCard: View {
    private let accent = Color(red: 0.18, green: 0.31, blue: 0.43)

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            TicketBanner(accent: accent)
            TicketPersona(accent: accent)
            TicketSectionTitle(text: "Weekly attention story")
            TicketStory()
            TicketSectionTitle(text: "Weekly stats")
            TicketStats()
            TicketSectionTitle(text: "Top apps")
            TicketTopApps()
            TicketSectionTitle(text: "Stamps")
            TicketStamps()
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(red: 0.99, green: 0.99, blue: 1.0))
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                    .foregroundStyle(Color.black.opacity(0.08))
                TicketNotches()
            }
        )
        .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 8)
    }
}

struct TicketBanner: View {
    let accent: Color

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent, Color(red: 0.35, green: 0.44, blue: 0.60)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 160)
            VStack(alignment: .leading, spacing: 8) {
                Text("LATE-NIGHT DRIFTER")
                    .font(.custom("AvenirNext-Bold", size: 22))
                    .foregroundStyle(.white)
                Text("You chase thoughts when the world sleeps, finding comfort in the glow of midnight scrolls.")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: 210, alignment: .leading)
            }
            .padding(.leading, 16)
        }
    }
}

struct TicketPersona: View {
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Persona")
                .font(.custom("AvenirNext-DemiBold", size: 14))
                .foregroundStyle(Color.black.opacity(0.55))
            Text("This week your phone was mostly a window — connection and learning, less looping.")
                .font(.custom("AvenirNext-Regular", size: 15))
            TicketDivider()
        }
    }
}

struct TicketStory: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TicketBullet(label: "Most active days", value: "Tue · Thu · Sat")
            TicketBullet(label: "Peak window", value: "11:30 PM – 1:10 AM")
            TicketBullet(label: "Attention rhythm", value: "Late-night clusters, lighter mornings")
        }
    }
}

struct TicketStats: View {
    var body: some View {
        VStack(spacing: 10) {
            TicketStatRow(title: "Total time", value: "21h 16m")
            TicketStatRow(title: "Daily avg", value: "3h 02m")
            TicketStatRow(title: "Pickups", value: "106")
        }
    }
}

struct TicketTopApps: View {
    var body: some View {
        VStack(spacing: 10) {
            TicketStatRow(title: "Spotify", value: "4h 12m")
            TicketStatRow(title: "Instagram", value: "2h 30m")
            TicketStatRow(title: "Flora", value: "1h 52m")
        }
    }
}

struct TicketStamps: View {
    private let stamps = ["Hibernator", "Inspired", "Gardener", "Anti-Scroller"]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(stamps, id: \.self) { stamp in
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .frame(height: 60)
                        .overlay(
                            Text("★")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.black.opacity(0.35))
                        )
                    Text(stamp)
                        .font(.custom("AvenirNext-Medium", size: 12))
                        .foregroundStyle(Color.black.opacity(0.6))
                }
            }
        }
    }
}

struct TicketSectionTitle: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.custom("AvenirNext-DemiBold", size: 12))
            .foregroundStyle(Color.black.opacity(0.5))
    }
}

struct TicketBullet: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.black.opacity(0.15))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .foregroundStyle(Color.black.opacity(0.55))
                Text(value)
                    .font(.custom("AvenirNext-Regular", size: 15))
            }
        }
    }
}

struct TicketStatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.custom("AvenirNext-Regular", size: 14))
            Spacer()
            Text(value)
                .font(.custom("AvenirNext-DemiBold", size: 14))
        }
        .padding(.vertical, 6)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

struct TicketPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom("AvenirNext-DemiBold", size: 12))
            .foregroundStyle(Color.black.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
    }
}

struct TicketDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.08))
            .frame(height: 1)
            .padding(.top, 8)
    }
}

struct TicketNotches: View {
    var body: some View {
        GeometryReader { proxy in
            let y = proxy.size.height * 0.18
            let radius: CGFloat = 12
            HStack {
                Circle()
                    .fill(Color(red: 0.89, green: 0.90, blue: 0.93))
                    .frame(width: radius * 2, height: radius * 2)
                    .offset(x: -radius)
                Spacer()
                Circle()
                    .fill(Color(red: 0.89, green: 0.90, blue: 0.93))
                    .frame(width: radius * 2, height: radius * 2)
                    .offset(x: radius)
            }
            .position(x: proxy.size.width / 2, y: y)
        }
    }
}

struct TicketStorySlide: View {
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.custom("AvenirNext-Bold", size: 18))
                Text(subtitle)
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
            .foregroundStyle(.white)
            .padding(18)
        }
        .padding(.vertical, 4)
    }
}

struct TicketStoryOverlay: View {
    @Binding var isPresented: Bool
    @State private var index = 0
    @State private var progress: Double = 0
    @State private var isPaused = false

    private let slides: [StorySlide] = [
        .attentionSplit,
        .comparison,
        .breakdown,
        .achievements,
        .persona,
        .ticketSummary
    ]

    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            StorySlideView(slide: slides[index])
                .ignoresSafeArea()

            VStack {
                HStack(spacing: 6) {
                    ForEach(slides.indices, id: \.self) { idx in
                        StoryProgressSegment(
                            progress: idx == index ? progress : (idx < index ? 1 : 0)
                        )
                        .frame(height: 3)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                Spacer()
            }

            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isPaused = true
                        if index > 0 {
                            index -= 1
                            resetProgress()
                        } else {
                            resetProgress()
                        }
                        isPaused = false
                    }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isPaused = true
                        if index < slides.count - 1 {
                            index += 1
                            resetProgress()
                        } else {
                            isPresented = false
                        }
                        isPaused = false
                    }
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Circle().fill(Color.black.opacity(0.35)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                Spacer()
            }
        }
        .onAppear {
            resetProgress()
        }
        .onReceive(timer) { _ in
            guard !isPaused else { return }
            let step = 0.05 / 8.0
            progress = min(progress + step, 1.0)
            if progress >= 1.0 {
                advance()
            }
        }
        .onChange(of: index) { _, _ in
            resetProgress()
        }
    }

    private func resetProgress() {
        progress = 0
    }

    private func advance() {
        if index < slides.count - 1 {
            index += 1
            resetProgress()
        } else {
            isPresented = false
        }
    }
}

struct StoryProgressSegment: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.15))
                Capsule()
                    .fill(Color.black.opacity(0.55))
                    .frame(width: proxy.size.width * CGFloat(progress))
            }
        }
    }
}

enum StorySlide {
    case attentionSplit
    case comparison
    case breakdown
    case achievements
    case persona
    case ticketSummary
}

struct StorySlideView: View {
    let slide: StorySlide

    var body: some View {
        switch slide {
        case .attentionSplit:
            StoryAttentionSplit()
        case .comparison:
            StoryComparison()
        case .breakdown:
            StoryBreakdown()
        case .achievements:
            StoryAchievements()
        case .persona:
            StoryPersona()
        case .ticketSummary:
            StoryTicketSummary()
        }
    }
}

struct StoryBasePage<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            Text(title)
                .font(.custom("AvenirNext-Medium", size: 22))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            content
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .foregroundStyle(Color.black.opacity(0.85))
    }
}

struct StoryAttentionSplit: View {
    var body: some View {
        StoryBasePage(title: "here’s how your\nattention was split this\nweek...") {
            RadarChartView(primary: [0.5, 0.7, 0.35, 0.4, 0.65, 0.55], secondary: nil)
                .frame(width: 240, height: 240)
        }
    }
}

struct StoryComparison: View {
    var body: some View {
        StoryBasePage(title: "compared to last\nweek...") {
            RadarChartView(primary: [0.4, 0.6, 0.3, 0.55, 0.7, 0.5], secondary: [0.6, 0.45, 0.25, 0.35, 0.5, 0.65])
                .frame(width: 240, height: 240)
            VStack(alignment: .leading, spacing: 8) {
                StoryBullet(text: "50% increase in productivity")
                StoryBullet(text: "32% reduction to drifting")
            }
            .padding(.top, 8)
        }
    }
}

struct StoryBreakdown: View {
    var body: some View {
        StoryBasePage(title: "here’s a breakdown:") {
            VStack(spacing: 14) {
                BreakdownRow(rank: "1.", minutes: "4h 12min", uses: "18 uses", highlight: false)
                BreakdownRow(rank: "2.", minutes: "2h 30min", uses: "12 uses", highlight: false)
                BreakdownRow(rank: "3.", minutes: "1h 52min", uses: "10 uses", highlight: true)
                BreakdownRow(rank: "4.", minutes: "1h 3min", uses: "8 uses", highlight: false)
                BreakdownRow(rank: "5.", minutes: "30 min", uses: "12 uses", highlight: false)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

struct StoryAchievements: View {
    var body: some View {
        StoryBasePage(title: "you also earned some\nachievements!") {
            VStack(spacing: 20) {
                AchievementRow(title: "HIBERNATOR", subtitle: "refrain from using your\ndevice for over 24 hrs", color: Color(red: 0.62, green: 0.24, blue: 0.25))
                AchievementRow(title: "INSPIRED", subtitle: "spend 3+ hours on\ncreativity apps", color: Color(red: 0.28, green: 0.36, blue: 0.56))
                AchievementRow(title: "GARDENER", subtitle: "spend 1+ hr daily on\nproductivity", color: Color(red: 0.16, green: 0.39, blue: 0.28))
                AchievementRow(title: "ANTI-SCROLLER", subtitle: "avoid spending over 30\nminutes at a time on\ndrifting", color: Color(red: 0.47, green: 0.23, blue: 0.45))
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

struct StoryPersona: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.24, green: 0.39, blue: 0.48), Color(red: 0.34, green: 0.34, blue: 0.56)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            PersonaClouds()
            VStack(spacing: 20) {
                Text("your activity persona is:")
                    .font(.custom("AvenirNext-Regular", size: 18))
                    .foregroundStyle(.white.opacity(0.85))
                Text("LATE-NIGHT\nDRIFTER")
                    .font(.custom("AvenirNext-BoldItalic", size: 34))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                Text("You chase thoughts when the\nworld sleeps, finding comfort in\nthe glow of midnight scrolls.")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 30)
        }
    }
}

struct StoryTicketSummary: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.20, green: 0.35, blue: 0.45), Color(red: 0.36, green: 0.37, blue: 0.58)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            VStack(spacing: 18) {
                TicketMiniCard()
                HStack(spacing: 12) {
                    CircleButton(systemName: "arrow.down")
                    CircleButton(systemName: "square.and.arrow.up")
                }
                .padding(.bottom, 18)
            }
            .padding(.horizontal, 20)
        }
    }
}

struct RadarChartView: View {
    let primary: [Double]
    let secondary: [Double]?
    private let labels = ["drifting", "connection", "creativity", "entertainment", "learning", "productivity"]

    var body: some View {
        ZStack {
            RadarGrid()
                .stroke(Color.black.opacity(0.25), lineWidth: 1)
            RadarPolygon(values: primary)
                .fill(Color(red: 0.35, green: 0.45, blue: 0.85).opacity(0.35))
                .overlay(
                    RadarPolygon(values: primary)
                        .stroke(Color(red: 0.35, green: 0.45, blue: 0.85), lineWidth: 1)
                )
            if let secondary {
                RadarPolygon(values: secondary)
                    .fill(Color.red.opacity(0.25))
                    .overlay(
                        RadarPolygon(values: secondary)
                            .stroke(Color.red.opacity(0.7), lineWidth: 1)
                    )
            }
            RadarLabels(labels: labels)
        }
    }
}

struct RadarGrid: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for level in 1...4 {
            let r = radius * CGFloat(level) / 4
            path.addPath(polygonPath(center: center, radius: r))
        }
        for i in 0..<6 {
            let angle = CGFloat(Double(i) * (Double.pi * 2 / 6) - Double.pi / 2)
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            path.move(to: center)
            path.addLine(to: point)
        }
        return path
    }

    private func polygonPath(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        for i in 0..<6 {
            let angle = CGFloat(Double(i) * (Double.pi * 2 / 6) - Double.pi / 2)
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct RadarPolygon: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for i in 0..<6 {
            let value = max(min(values[i], 1.0), 0.0)
            let angle = CGFloat(Double(i) * (Double.pi * 2 / 6) - Double.pi / 2)
            let point = CGPoint(
                x: center.x + cos(angle) * radius * CGFloat(value),
                y: center.y + sin(angle) * radius * CGFloat(value)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct RadarLabels: View {
    let labels: [String]

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = min(proxy.size.width, proxy.size.height) / 2 + 14
            ForEach(labels.indices, id: \.self) { idx in
                let angle = CGFloat(Double(idx) * (Double.pi * 2 / 6) - Double.pi / 2)
                let point = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
                Text(labels[idx])
                    .font(.custom("AvenirNext-Regular", size: 10))
                    .foregroundStyle(Color.black.opacity(0.55))
                    .position(point)
            }
        }
    }
}

struct BreakdownRow: View {
    let rank: String
    let minutes: String
    let uses: String
    let highlight: Bool

    var body: some View {
        HStack(spacing: 16) {
            Text(rank)
                .font(.custom("AvenirNext-Medium", size: 16))
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 48, height: 48)
                .overlay(
                    Rectangle()
                        .stroke(highlight ? Color.blue : Color.black.opacity(0.4), lineWidth: highlight ? 2 : 1)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(minutes)
                Text(uses)
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(Color.black.opacity(0.6))
            }
            .font(.custom("AvenirNext-Regular", size: 14))
        }
    }
}

struct AchievementRow: View {
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color, lineWidth: 2)
                .frame(width: 60, height: 60)
                .overlay(
                    Text("★")
                        .font(.system(size: 18))
                        .foregroundStyle(color)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("AvenirNext-DemiBold", size: 14))
                Text(subtitle)
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(Color.black.opacity(0.6))
            }
        }
    }
}

struct StoryBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.black.opacity(0.2))
                .frame(width: 5, height: 5)
                .padding(.top, 6)
            Text(text)
                .font(.custom("AvenirNext-Regular", size: 13))
        }
        .foregroundStyle(Color.black.opacity(0.7))
    }
}

struct PersonaClouds: View {
    var body: some View {
        ZStack {
            CloudShape()
                .fill(Color.white.opacity(0.25))
                .frame(width: 140, height: 70)
                .offset(x: -110, y: -220)
            CloudShape()
                .fill(Color.white.opacity(0.18))
                .frame(width: 180, height: 90)
                .offset(x: 80, y: 120)
            ForEach(0..<8, id: \.self) { idx in
                StarShape()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 18, height: 18)
                    .offset(x: CGFloat((idx % 4) * 60 - 90), y: CGFloat((idx / 4) * 90 - 80))
            }
        }
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let height = rect.height
        path.addRoundedRect(in: CGRect(x: 0, y: height * 0.35, width: rect.width, height: height * 0.45), cornerSize: CGSize(width: height * 0.2, height: height * 0.2))
        path.addEllipse(in: CGRect(x: rect.width * 0.05, y: 0, width: rect.width * 0.35, height: rect.height * 0.7))
        path.addEllipse(in: CGRect(x: rect.width * 0.35, y: 0, width: rect.width * 0.4, height: rect.height * 0.8))
        path.addEllipse(in: CGRect(x: rect.width * 0.6, y: height * 0.1, width: rect.width * 0.35, height: rect.height * 0.7))
        return path
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let points = 5
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.45
        for i in 0..<(points * 2) {
            let angle = Double(i) * Double.pi / Double(points) - Double.pi / 2
            let r = i.isMultiple(of: 2) ? radius : innerRadius
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * r, y: center.y + CGFloat(sin(angle)) * r)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct TicketMiniCard: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                VStack(alignment: .leading, spacing: 8) {
                    Text("LATE-NIGHT\nDRIFTER")
                        .font(.custom("AvenirNext-BoldItalic", size: 22))
                    Text("01.18.26 — 01.24.26")
                        .font(.custom("AvenirNext-Regular", size: 12))
                        .foregroundStyle(Color.black.opacity(0.6))
                    Divider()
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("WEEKLY STATS")
                                .font(.custom("AvenirNext-DemiBold", size: 10))
                            Text("My hour: 2:00 AM")
                            Text("Total time: 21h 16m")
                            Text("Daily avg: 3h 04m")
                            Text("Pickups: 106")
                        }
                        .font(.custom("AvenirNext-Regular", size: 10))
                        Spacer()
                        RadarChartView(primary: [0.5, 0.7, 0.35, 0.4, 0.65, 0.55], secondary: nil)
                            .frame(width: 70, height: 70)
                    }
                }
                .padding(14)
            }
            .frame(height: 240)
        }
    }
}

struct CircleButton: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.25))
            .frame(width: 44, height: 44)
            .background(Circle().fill(Color.white))
    }
}
