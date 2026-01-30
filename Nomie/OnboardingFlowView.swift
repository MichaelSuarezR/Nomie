//
//  OnboardingFlowView.swift
//  Nomie
//

import SwiftUI
import Supabase

struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppState
    @State private var pageIndex = 0
    @State private var selectedGoals: Set<String> = []
    @State private var authMode: AuthView.Mode = .signUp
    private let totalPages = 4

    var body: some View {
        let isAuthed = appState.session != nil

        VStack(spacing: 0) {
            OnboardingTopBar(
                canGoBack: pageIndex > 0,
                showsSkip: isAuthed && pageIndex > 1,
                onBack: { pageIndex = max(0, pageIndex - 1) },
                onSkip: completeOnboarding
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Group {
                switch pageIndex {
                case 0:
                    OnboardingWelcomeView(
                        onSignUp: {
                            authMode = .signUp
                            pageIndex = 1
                        },
                        onLogIn: {
                            authMode = .logIn
                            pageIndex = 1
                        }
                    )
                case 1:
                    AuthView(initialMode: authMode)
                        .id(authMode)
                case 2:
                    OnboardingGoalsView(selectedGoals: $selectedGoals)
                default:
                    OnboardingCheckInView()
                }
            }

            if pageIndex > 1 {
                OnboardingPageIndicator(
                    currentIndex: max(0, pageIndex - 2),
                    total: max(1, totalPages - 2)
                )
                .padding(.bottom, 12)
            } else {
                Spacer().frame(height: 18)
            }

            if pageIndex > 1 {
                Button(action: advance) {
                    Text(pageIndex == totalPages - 1 ? "Get Started" : "Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            } else {
                Spacer().frame(height: 44)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onChange(of: pageIndex) { newValue in
            if newValue > 1 && appState.session == nil {
                pageIndex = 1
            }
        }
        .onChange(of: appState.session?.user.id) { _ in
            if appState.session != nil, pageIndex == 1 {
                pageIndex = 2
            }
        }
    }

    private func advance() {
        if pageIndex == 0 && appState.session == nil {
            pageIndex = 1
            return
        }

        if pageIndex == 1 && appState.session == nil {
            return
        }

        if pageIndex < totalPages - 1 {
            pageIndex += 1
        } else {
            saveGoals()
            completeOnboarding()
        }
    }

    private func saveGoals() {
        let goals = Array(selectedGoals)
        UserDefaults.standard.set(goals, forKey: "selectedGoals")
    }

    private func completeOnboarding() {
        saveGoals()
        appState.completeOnboarding()
    }
}

private struct OnboardingTopBar: View {
    let canGoBack: Bool
    let showsSkip: Bool
    let onBack: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(canGoBack ? .black : .clear)
            }
            .disabled(!canGoBack)

            Spacer()

            if showsSkip {
                Button("Skip", action: onSkip)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

private struct OnboardingPageIndicator: View {
    let currentIndex: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? Color.black : Color.gray.opacity(0.3))
                    .frame(width: index == currentIndex ? 28 : 18, height: 6)
            }
        }
    }
}

private struct OnboardingWelcomeView: View {
    let onSignUp: () -> Void
    let onLogIn: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hello")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.black)
                Text("Ready to unlock your digital nutrition?")
                    .font(.title3)
                    .foregroundColor(.black.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, 8)

            MoodCloudView()
                .frame(height: 380)
                .padding(.horizontal, -8)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onSignUp) {
                    Text("Sign Up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }

                Button(action: onLogIn) {
                    Text("Log In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .overlay(
                            Capsule().stroke(Color.black.opacity(0.25), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, -30)
        }
        .padding(.top, 12)
    }
}


private struct MoodCloudView: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let bubbleSize = width * 0.34
            let rowSpacing = width * 0.07
            let edgeBuffer = bubbleSize * 0.9

            VStack(spacing: rowSpacing) {
                MoodRow(
                    images: ["Illustration294 1", "Illustration295 1", "Illustration296 1"],
                    bubbleSize: bubbleSize,
                    direction: -1,
                    horizontalOffset: -width * 0.06,
                    edgeBuffer: edgeBuffer,
                    speed: 18,
                    extraRepeats: 2,
                    rowWidth: width,
                    floatPhase: 0
                )
                MoodRow(
                    images: ["Illustration297 1", "Illustration298 1", "Illustration299 1"],
                    bubbleSize: bubbleSize,
                    direction: 1,
                    horizontalOffset: width * 0.04,
                    edgeBuffer: edgeBuffer,
                    speed: 16,
                    extraRepeats: 2,
                    rowWidth: width,
                    floatPhase: 2.1
                )
                MoodRow(
                    images: ["Illustration300 1", "Illustration301 1", "Illustration302 1"],
                    bubbleSize: bubbleSize,
                    direction: -1,
                    horizontalOffset: -width * 0.06,
                    edgeBuffer: edgeBuffer,
                    speed: 20,
                    extraRepeats: 4,
                    rowWidth: width,
                    floatPhase: 4.2
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

private struct MoodRow: View {
    let images: [String]
    let bubbleSize: CGFloat
    let direction: CGFloat
    let horizontalOffset: CGFloat
    let edgeBuffer: CGFloat
    let speed: CGFloat
    let extraRepeats: Int
    let rowWidth: CGFloat
    let floatPhase: CGFloat

    init(
        images: [String],
        bubbleSize: CGFloat,
        direction: CGFloat,
        horizontalOffset: CGFloat,
        edgeBuffer: CGFloat,
        speed: CGFloat,
        extraRepeats: Int = 0,
        rowWidth: CGFloat,
        floatPhase: CGFloat = 0
    ) {
        self.images = images
        self.bubbleSize = bubbleSize
        self.direction = direction
        self.horizontalOffset = horizontalOffset
        self.edgeBuffer = edgeBuffer
        self.speed = speed
        self.extraRepeats = extraRepeats
        self.rowWidth = rowWidth
        self.floatPhase = floatPhase
    }

    var body: some View {
        TimelineView(.animation) { context in
            let cycle = bubbleSize * CGFloat(images.count)
            let repeats = max(6, Int(ceil((rowWidth + edgeBuffer * 2 + cycle) / cycle))) + 2 + extraRepeats
            let totalWidth = cycle * CGFloat(repeats)
            let t = context.date.timeIntervalSinceReferenceDate
            let raw = CGFloat(t) * speed
            let normalized = (raw.truncatingRemainder(dividingBy: cycle) + cycle)
                .truncatingRemainder(dividingBy: cycle)
            let offset = direction < 0 ? -normalized : normalized
            let floatAmplitude = bubbleSize * 0.06
            let float = sin(CGFloat(t) * 0.45 + floatPhase) * floatAmplitude

            HStack(spacing: 0) {
                ForEach(0..<repeats, id: \.self) { _ in
                    ForEach(Array(images.enumerated()), id: \.offset) { index, name in
                        let phase = floatPhase + CGFloat(index) * 1.4
                        let localFloat = sin(CGFloat(t) * 0.45 + phase) * floatAmplitude

                        Image(name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: bubbleSize, height: bubbleSize)
                            .offset(y: localFloat)
                    }
                }
            }
            .frame(width: totalWidth, alignment: .leading)
            .offset(x: horizontalOffset - edgeBuffer + offset - cycle)
            .frame(width: rowWidth, height: bubbleSize + floatAmplitude * 2, alignment: .leading)
            .clipped()
        }
        .frame(width: rowWidth, height: bubbleSize + bubbleSize * 0.08, alignment: .leading)
    }
}

private struct OnboardingGoalsView: View {
    @Binding var selectedGoals: Set<String>

    private let goals = [
        "Reduce doomscrolling",
        "Stay present",
        "Reflect daily",
        "Build focus"
    ]

    var body: some View {
        VStack(spacing: 28) {
            Text("What are\nyour goals?")
                .font(.system(size: 36, weight: .bold))
                .multilineTextAlignment(.center)

            VStack(spacing: 14) {
                ForEach(goals, id: \.self) { goal in
                    GoalButton(title: goal, isSelected: selectedGoals.contains(goal)) {
                        toggle(goal)
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding(.top, 36)
    }

    private func toggle(_ goal: String) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }
}

private struct GoalButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? Color.black : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .black)
                .clipShape(Capsule())
        }
    }
}

private struct OnboardingCheckInView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Daily check-in")
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)

            Text("Track your mood and screen-time patterns in under a minute.")
                .font(.title3)
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer()
        }
        .padding(.top, 48)
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AppState())
}
