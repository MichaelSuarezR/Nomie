//
//  FocusView.swift
//  Nomie
//

import SwiftUI
import Combine
struct FocusView: View {

    @State private var usage: [CategoryUsage] = [
        .init(id: .connection, usage: 4 * 3600 + 32 * 60, maxUsage: 5 * 3600, type: GoalType.Prioritize),
        .init(id: .creativity, usage: 3 * 3600 + 45 * 60, maxUsage: 5 * 3600, type: GoalType.Prioritize),
        .init(id: .drifting, usage: 2 * 3600 + 58 * 60, maxUsage: 5 * 3600, type: GoalType.Limit),
        .init(id: .entertainment, usage: 1 * 3600 + 40 * 60, maxUsage: 5 * 3600, type: GoalType.Limit),
        .init(id: .learning, usage: 52 * 60, maxUsage: 5 * 3600, type: GoalType.Prioritize),
        .init(id: .productivity, usage: 46 * 60, maxUsage: 5 * 3600, type: GoalType.Prioritize)
    ]
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    FocusHeader(name: "Nomie")
                    DashboardWrapper(streakDays: 8, category: "Creativity", timeOfDay: getTimeOfDayText(), usage: $usage)
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Color(FocusColors.tempBackground))
        }
        .navigationTitle("Focus")

    }
}

struct DashboardWrapper: View {
    let streakDays: Int
    let category: String
    let timeOfDay: String
    @Binding var usage: [CategoryUsage]
    var body: some View {
        VStack(spacing: 24) {
            StreaksBar(streakDays: 8)
            DailyInsights(category: "Creativity", timeOfDay: timeOfDay)
            Charts(usage: usage)
            GoalsView(usage: $usage)
        }.padding(.horizontal, 21)
    }
}
struct FocusHeader : View {
    let name: String
    var body: some View {
        GeometryReader {geo in
            VStack {
                VStack(spacing: 2) {
                    Text("hello,")
                        .font(.custom("SortsMillGoudy-Italic", size: 32))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(getTextColor())
                    Text("\(name)")
                        .font(.custom("SortsMillGoudy-Regular", size: 40))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(getTextColor())

                }
            }
                .padding(.top, geo.safeAreaInsets.top + 111)
                .padding(.horizontal, 21)


        }
        .frame(minHeight:272)
    }
}
struct StreaksBar : View {
    let streakDays: Int
    var body: some View {
        HStack {
            Text("Streaks:" )
            .font(.system(size:14, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10.5)
            HStack {
                Text("\(streakDays)")
                    .font(.custom("BricolageGrotesque-96ptExtraBold_Regular", size: 32)
                        .weight(.bold)
                    )
                    .frame(alignment: .trailing)
                    .foregroundStyle(getStreakNumColor())
                Text("days")
                    .font(.system(size:14, weight: .medium))
                    .frame(alignment: .trailing)
                    .padding(.vertical, 10.5)
            }
            
            
        }.padding(.horizontal, 12)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color(red: 0.58, green: 0.63, blue: 0.34).opacity(0.25), radius: 2, x: 0, y: 3)

    }
}
struct BannerItem: Identifiable, Equatable {
    var id = UUID();
    var imageName: String
}



struct DailyInsights: View {
    let category: String
    let timeOfDay: String
    var body: some View {
        VStack {
            Text("Daily Insights")
                .font(.custom("SortsMillGoudy-Regular",size: 20))
                .foregroundStyle(getTextColor())
                .frame(maxWidth: .infinity, alignment: .topLeading)
                
                
            Text("You are heavy on the '\(category)' apps " + timeOfDay + ".")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundStyle(getTextColor())
                .frame(maxWidth:.infinity, alignment:.topLeading)

        }.padding(.horizontal, 12)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
            )
            .shadow(color: Color(red: 0.69, green: 0.76, blue: 0.36).opacity(0.25), radius: 2, x: 0, y: 4)





    }
}
struct Charts: View {
    let usage: [CategoryUsage]
    var totalSeconds: Int {
        usage.reduce(0) { $0 + $1.usage }
    }
    var body: some View {
        VStack(spacing: 20) {
            DashboardRadarChart().frame(height:280)
            BarChartView(usage: usage).padding(.horizontal,12)
            TotalUsage(totalSeconds: totalSeconds).padding(.bottom, 16)

            
        }.background(RoundedRectangle(cornerRadius: 8).fill(Color.white)).shadow(color: Color(red: 0.58, green: 0.63, blue: 0.34).opacity(0.25), radius: 2, x: 0, y: 3)
        
    }
}
struct TotalUsage: View {
    let totalSeconds: Int;

    var body: some View {
        Text("Total Usage: " + formatSeconds(totalSeconds))
            .font(.custom("SortsMillGoudy-Regular", size: 20))
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundStyle(getTextColor())

    }
}
private struct DashboardRadarChart: View {
    private let labels = ["drifting", "connection", "creativity", "entertainment", "learning", "productivity"]
    private let seriesA: [CGFloat] = [0.85, 0.45, 0.35, 0.7, 0.25, 0.3]
    private let seriesB: [CGFloat] = [0.45, 0.6, 0.4, 0.25, 0.75, 0.7]

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = size * 0.35

            ZStack {
                DashboardRadarGrid(center: center, radius: radius)

                DashboardRadarPolygon(values: seriesA, center: center, radius: radius)
                    .stroke(Color.red.opacity(0.7), lineWidth: 1.5)
                    .background(
                        DashboardRadarPolygon(values: seriesA, center: center, radius: radius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.25, blue: 0.4),
                                        Color(red: 0.7, green: 0.56, blue: 0.56)
                                        
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            ).opacity(0.3)
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

private struct DashboardRadarGrid: View {
    let center: CGPoint
    let radius: CGFloat

    var body: some View {
        ZStack {
            ForEach(1..<4) { ring in
                DashboardRadarPolygon(values: Array(repeating: CGFloat(ring) / 3.0, count: 6), center: center, radius: radius)
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

private struct DashboardRadarPolygon: Shape {
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

struct BarChart: View {
    let usage: Int
    let maxUsage: Int
    let height: CGFloat?
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let usageWidth = width * CGFloat(usage) / CGFloat(maxUsage)
            ZStack(alignment: .leading) {
                Capsule().fill(Color(red: 0.89, green: 0.93, blue: 0.78))
                Capsule().fill(FocusColors.barChartFill).stroke(Color(red: 0.7, green: 0.56, blue: 0.56))
                    .frame(width:((usage > maxUsage) ? width : usageWidth))
                
            }
        }.frame(height: height)
    }
}
struct BarChartRow: View {
    let categoryUsage: CategoryUsage
    var body: some View {
        HStack(spacing: 0) {
            Text(categoryUsage.id.title).font(.custom("Poppins", size:12)).frame(maxWidth: 100, alignment: .leading).foregroundStyle(getTextColor())
            BarChart(usage: categoryUsage.usage, maxUsage: categoryUsage.maxUsage, height: nil)
            Text("\(formatSeconds(categoryUsage.usage))").frame(maxWidth: 100, alignment: .trailing).font(.custom("Poppins", size:12)).foregroundStyle(getTextColor())
            
        }.frame(height:11)
    }
}
struct BarChartView: View {
    let usage: [CategoryUsage]
    var body: some View {
        VStack {
            ForEach(usage) {item in
                BarChartRow(categoryUsage:item)
            }
        }
    }
}

struct GoalsView: View {
    @Binding var usage: [CategoryUsage]
    var body: some View {
        VStack {
            Text("Goals").font(.custom("SortsMillGoudy-Regular", size: 20)).frame(maxWidth: .infinity, minHeight: 26, maxHeight: 26, alignment: .topLeading).foregroundStyle(getTextColor())
            Text("You are \(usage.reduce(0) {$0 + $1.usage} <= usage.reduce(0) {$0 + $1.maxUsage} ? "" : "not")on track to meet today's goals!").font(.custom("Poppins", size:14)).multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(getTextColor())
            SetGoalsButton(usage: $usage).padding(.horizontal, 70)
        }.padding(.horizontal, 12)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .top)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color(red: 0.58, green: 0.63, blue: 0.34).opacity(0.25), radius: 2, x: 0, y: 3)
    }
}

struct SetGoalsButton: View {
    @Binding var usage: [CategoryUsage]
    var body: some View {
        NavigationLink {
            MyGoalsView(usage: $usage)
        } label: {
            Text("Set Goals").font(.custom("SortsMillGoudy-Regular", size: 16)).foregroundStyle(getTextColor()).frame(maxWidth: .infinity, alignment:.center).padding(.horizontal, 32)
                .padding(.top, 4).foregroundColor(.black)
        }.background(RoundedRectangle(cornerRadius:4).fill(FocusColors.setGoalsFill))
            .shadow(color: Color(red: 0.4, green: 0.48, blue: 0.03).opacity(0.25), radius: 2, x: 0, y: 2)
            .shadow(color: Color(red: 0.82, green: 0.86, blue: 0.7), radius: 2, x: 0, y: 0)
            .overlay(
            RoundedRectangle(cornerRadius: 4)
            .inset(by: 0.5)
            .stroke(Color(red: 1, green: 1, blue: 0.98), lineWidth: 1)
            )
    }
}

struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button {
            dismiss()
        } label: {
            Text("<").font(.system(size:20, weight:.bold)).frame(minWidth: 32, minHeight: 32).background(FocusColors.background).cornerRadius(16).clipShape(Circle()).foregroundColor(.black)
        }

    }
}
struct MyGoalsView: View {
    @Binding var usage: [CategoryUsage]
    
    var body: some View {
        ScrollView {
            ZStack {
                VStack {
                    VStack{
                        LimitGoals(usage: $usage)
                        PrioritizeGoals(usage: $usage)
                    }
                }
                .safeAreaInset(edge: .top) {
                    MyGoalsHeader()
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .navigationBarBackButtonHidden(true)
            }
        }.overlay(alignment: .bottomTrailing) {
            AddGoalButton(usage: $usage)
        }
    }
}

struct MyGoalsHeader: View {
    var body: some View {
        ZStack {
            BackButton().frame(maxWidth:.infinity, alignment: .leading).padding(.leading, 13)
            HStack {
                Text("My Goals").font(.system(size: 32, weight:.medium)).frame(maxWidth:.infinity, alignment:.center)
            }.frame(maxWidth: .infinity, alignment: .leading).navigationBarBackButtonHidden(true).padding(.leading, 13)
        }

    }
}
struct LimitGoals: View {
    @Binding var usage: [CategoryUsage]
    var body: some View {
        Text("Limit").font(.custom("SortsMillGoudy-Regular", size: 32)).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 13)
        ForEach(usage.filter {$0.type == .Limit}) {item in
            ProgressComponent(categoryUsage: item).padding(.horizontal, 30).padding(.vertical, 8)
        }
    }
}
struct PrioritizeGoals: View {
    @Binding var usage: [CategoryUsage]
    var body: some View {
        Text("Prioritize").font(.custom("SortsMillGoudy-Regular", size: 32)).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 13)
        ForEach(usage.filter {$0.type == .Prioritize}) {item in
            ProgressComponent(categoryUsage: item).padding(.horizontal, 30).padding(.vertical, 8)
        }
    }
}
struct ProgressComponent: View {
    let categoryUsage: CategoryUsage
    var minutesLeft : Int{
        (categoryUsage.maxUsage - categoryUsage.usage) / 60
    }
    var body: some View {
        VStack {
            HStack {
                Text("\(categoryUsage.id)").font(.custom("Poppins", size:14)).frame(maxWidth:.infinity, alignment: .leading).padding(.leading ,13)
                Text("\(minutesLeft) min left").font(.custom("Poppins", size:14)).frame(maxWidth:.infinity, alignment: .trailing).padding(.trailing,13)
            }
            BarChart(usage:categoryUsage.usage, maxUsage: categoryUsage.maxUsage, height: 30).padding(.horizontal,13)
        }.frame(width: 343).frame(height:113).background(
            RoundedRectangle(cornerRadius:16).stroke(Color.black)
        )
    }
}

struct AddGoalButton: View {
    @Binding var usage: [CategoryUsage]
    var body: some View {
        NavigationLink {
            SetGoalView(usage: $usage)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(
                    LinearGradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                Text("+").font(.system(size: 58, weight: .bold)).foregroundColor(.white)
            }.frame(width: 71, height: 71)
        }.buttonStyle(.plain).padding(20)
    }
}
struct SetGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var usage: [CategoryUsage]
    @State private var categorySelection: CategoryID = .drifting
    @State private var goalSelection: GoalType = .Limit
    @State private var selectedTime: Int = 60
    var body: some View {
        ScrollView {
            VStack {
                CategoryDropdown(categorySelection: $categorySelection).padding(.top, 13).padding(.horizontal,13)
                GoalDropdown(goalSelection: $goalSelection).padding(.top, 13).padding(.horizontal,13)
                SetGoalTime(selectedTime: $selectedTime, goalSelection: goalSelection ).padding(.top, 13).padding(.horizontal,13)
                Button {
                    updateCategory()
                } label: {
                    SaveButton().padding(.top, 13).padding(.horizontal, 13)
                }
            }.safeAreaInset(edge: .top) {
                SetGoalHeader()
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).toolbar(.hidden, for:.navigationBar)
        }
    }
    func updateCategory () {
        let newMaxUsage = selectedTime * 60
        guard let index = usage.firstIndex(where: {$0.id == categorySelection }) else { return }
        usage[index].maxUsage = newMaxUsage
        usage[index].type = goalSelection
        dismiss()
    }
}
struct SetGoalHeader: View {
    var body: some View {
        ZStack {
            BackButton().frame(maxWidth:.infinity, alignment: .leading).padding(.leading, 13)
            HStack {
                Text("Set a Goal").font(.system(size: 32, weight:.medium)).frame(maxWidth:.infinity, alignment:.center)
            }.frame(maxWidth: .infinity, alignment: .leading).navigationBarBackButtonHidden(true).padding(.leading, 13)
        }

    }
}
struct DailyWeeklyToggle: View {
    var body: some View {
        EmptyView()
    }
}
struct CategoryDropdown: View {
    @Binding var categorySelection: CategoryID
    var body: some View {
        VStack {
            Text("Select a Category").font(.system(size: 24, weight: .regular)).frame(maxWidth:.infinity, alignment:.leading).padding(.leading, 10)
            Menu {
                ForEach(CategoryID.allCases) {category in
                    Button(category.rawValue) {
                        categorySelection = category
                    }
                }
            } label: {
                HStack {
                    Text(categorySelection.rawValue).font(.system(size:20, weight:.regular)).frame(maxWidth: .infinity, alignment: .leading).padding(.leading,10)
                    Image(systemName: "chevron.down").font(.system(size:18)).frame(maxWidth:.infinity, alignment:.trailing).padding(.trailing, 10)
                }.padding(.leading, 13).frame(height:47).background(Color.white).cornerRadius(15)
            }.buttonStyle(.plain)
        }.padding(.horizontal, 13).frame(height:118).background(
            RoundedRectangle(cornerRadius:20, style: .continuous).fill(FocusColors.background)
        )
    }
}

struct GoalDropdown: View {
    @Binding var goalSelection: GoalType
    var body: some View {
        VStack {
            Text("Goal Type").font(.system(size: 24, weight: .regular)).frame(maxWidth:.infinity, alignment:.leading).padding(.leading, 10)
            Menu {
                ForEach(GoalType.allCases) {goal in
                    Button(goal.rawValue) {
                        goalSelection = goal
                    }
                }
            } label: {
                HStack {
                    Text(goalSelection.rawValue).font(.system(size:20, weight:.regular)).frame(maxWidth: .infinity, alignment: .leading).padding(.leading,10)
                    Image(systemName: "chevron.down").font(.system(size:18)).frame(maxWidth:.infinity, alignment:.trailing).padding(.trailing, 10)
                }.padding(.leading, 13).frame(height:47).background(Color.white).cornerRadius(15)
            }.buttonStyle(.plain)
        }.padding(.horizontal, 13).frame(height:118).background(
            RoundedRectangle(cornerRadius:20, style: .continuous).fill(FocusColors.background)
        )
    }
}
struct SetGoalTime: View {
    @Binding var selectedTime: Int
    let goalSelection: GoalType
    var body: some View {
        VStack {
            Text("Set \(goalSelection == .Limit ? "Limit" : "Target")").font(.system(size: 24, weight: .regular)).frame(maxWidth:.infinity, alignment:.leading).padding(.leading, 10)
            TimeSelectionBar(selectedTime: $selectedTime).padding(.top, 13)
        }.frame(maxWidth:.infinity, alignment: .topLeading).frame(height:164, alignment: .topLeading).padding(.horizontal, 13).padding(.top, 13).background(
            RoundedRectangle(cornerRadius:20, style: .continuous).fill(FocusColors.background)
        )
    }
}
struct TimeSelectionBar: View {
    @Binding var selectedTime: Int
    var minMinutes: Int = 0
    var maxMinutes: Int = 1440
    var step: Int = 1
    
    var delay : Double = 0.35
    var repeatInterval: Double = 0.08
    
    @State private var repeatTimer: Timer?
    
    var body: some View {
        HStack {
            RepeatButton(symbol: "-", onTap: {onTap(delta: -step)}, onStartRepeat: {startRepeating(delta: -step)}, onStopRepeat: {stopRepeating()}, size: 60).frame(maxWidth:.infinity, alignment:.leading).padding(.leading, 13)
            Text("\(selectedTime) min").font(.system(size: 32, weight: .medium)).monospacedDigit().frame(width: 120, alignment: .center)
            RepeatButton(symbol: "+", onTap: {onTap(delta: step)}, onStartRepeat: {startRepeating(delta: step)}, onStopRepeat: {stopRepeating()}, size: 60).frame(maxWidth: .infinity, alignment:.trailing).padding(.trailing, 13)
        }.frame(maxWidth:.infinity)
    }
    private func change(_ delta: Int) {
        let newMinutes = selectedTime + delta
        selectedTime = min(max(newMinutes, minMinutes), maxMinutes)
    }
    
    private func onTap(delta: Int) {
        change(delta)
    }
    private func startRepeating(delta: Int) {
        stopRepeating()
        change(delta)
        

        repeatTimer = Timer.scheduledTimer(
            withTimeInterval: repeatInterval,repeats: true) {
                _ in change(delta)
            }
        RunLoop.main.add(repeatTimer!, forMode: .common)
            
        
        
        
    }
    private func stopRepeating() {
        repeatTimer?.invalidate()
        repeatTimer = nil
    }
}
struct RepeatButton: View {
    let symbol: String
    let onTap: () -> Void
    let onStartRepeat: () -> Void
    let onStopRepeat: () -> Void
    let size: CGFloat
    @State private var isPressed = false
    @State private var didStartRepeat = false
    @State private var startRepeatWork: DispatchWorkItem?
    var body: some View {
        Text(symbol)
            .font(.system(size: 42, weight: .medium))

            .frame(width: size, height: size)
            .background(symbol == "+" ? FocusColors.darkerBackground : Color.white)

            .foregroundColor(symbol == "+" ? Color.white: Color.black)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.9 : 1)
            .opacity(isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.12), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else {return}
                        isPressed = true;
                        didStartRepeat = false;
                        
                        onTap()
                        
                        let work = DispatchWorkItem {
                            guard isPressed else {return}
                            didStartRepeat = true;
                            onStartRepeat()
                        }
                        
                        startRepeatWork = work
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
                    }
                    .onEnded{ _ in
                        startRepeatWork?.cancel()
                        startRepeatWork = nil
                        if didStartRepeat {
                            onStopRepeat()
                            
                        } else {
                            onTap()
                        }
                        isPressed = false
                        didStartRepeat = false
                    }
            )
    }
}

struct SaveButton: View {
    
    var body: some View {
        Text("Save Goal").font(.system(size:24, weight:.regular)).frame(maxWidth:.infinity).frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius:10, style: .continuous).fill(FocusColors.background)
            )
    }
}

enum TextColors {
    static let awakeText = Color(red: 0.26, green: 0.36, blue: 0.2)
    static let restText = Color(red: 0.32, green: 0.23, blue: 0.22)
    static let streakGradientAwake = LinearGradient(
        colors: [
            Color(red: 0.94, green: 0.55, blue: 0.38),
            Color(red: 0.96, green: 0.34, blue: 0.37)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let streakGradientRest = LinearGradient(
        colors: [
            Color(red: 0.91, green: 0.67, blue: 0.47),
            Color(red: 0.78, green: 0.79, blue: 0.61),
            Color(red: 0.61, green: 0.86, blue: 0.87)
            
        ],
        startPoint: UnitPoint(x: 0.2, y: 0.1),
        endPoint: UnitPoint(x: 0.8, y: 0.9)
    )
}
enum FocusColors {
    static let background = Color(
        red: 217.0 / 255.0,
        green: 217.0 / 255.0,
        blue: 217.0 / 255.0
    )

    static let tempBackground = UIColor(red: 1, green: 0.98, blue: 0.84, alpha: 1)
    static let insightBackground = LinearGradient(
        colors: [
            Color(red: 255/255, green: 231/255, blue: 239/255),
            Color(red: 255/255, green: 253/255, blue: 236/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    static let goalsButtonBackground = Color(
        red: 255/255,
        green: 253/255,
        blue: 236/255
    )

    static let barChartFill = LinearGradient(
        colors: [
            Color(red: 0.89, green: 0.86, blue: 0.58),
            Color(red: 0.96, green: 0.77, blue: 0.5),
            Color(red: 0.96, green: 0.89, blue: 0.87)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let setGoalsFill = LinearGradient(
        colors: [
            Color(red: 0.96, green: 0.89, blue: 0.87),
            Color(red: 0.96, green: 0.77, blue: 0.5),
            Color(red: 0.89, green: 0.86, blue: 0.58)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let darkerBackground = Color (
        red: 96.0 / 255.0,
        green: 96.0 / 255.0,
        blue:  96.0 / 255.0
    )
    
    static let tempGreen = Color(
        red: 177.0 / 255.0,
        green: 232.0 / 255.0,
        blue: 175.0 / 255.0
    )
}
enum CategoryID: String, Codable, CaseIterable, Identifiable {
    case creativity, connection, drifting, entertainment, productivity, learning
    var id: String{rawValue}
    var title: String {
        switch self{
        case .creativity: return "Creativity"
        case .connection: return "Connection"
        case .drifting: return "Drifting"
        case .entertainment: return "Entertainment"
        case .productivity: return "Productivity"
        case .learning: return "Learning"
        }
    }
}
enum GoalType: String, Codable, CaseIterable, Identifiable {
    case Limit, Prioritize
    var id: String{rawValue}
    var title: String {
        switch self {
        case .Limit: return "Limit"
        case .Prioritize: return "Prioritize"
        }
    }
}
struct CategoryUsage: Identifiable, Codable {
    var id: CategoryID
    var usage: Int
    var maxUsage: Int
    var type: GoalType
}
func formatSeconds(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let mins = (seconds % 3600) / 60
    return String(hours > 0 ? "\(hours) hr \(mins) min" : "\(mins) min")
}
let mockUsage: [CategoryUsage] = [
    .init(id: .creativity, usage: 3600, maxUsage: 7200, type: .Limit),
    .init(id: .productivity, usage: 1800, maxUsage: 7200, type: .Prioritize)
]
let banner: [BannerItem] = [
    .init(imageName:"Illustration294 1"),
    .init(imageName:"Illustration295 1"),
    .init(imageName:"Illustration296 1"),
    .init(imageName:"Illustration297 1"),
    .init(imageName:"Illustration298 1"),
    .init(imageName:"Illustration299 1"),
    .init(imageName:"Illustration300 1"),
    .init(imageName:"Illustration301 1"),
    .init(imageName:"Illustration302 1")
]
private func getTextColor () -> Color {
    let hour = Calendar.current.component(.hour, from: Date())
    
    if( hour >= 12 && hour <= 24) {
        return TextColors.awakeText;
    } else {
        return TextColors.restText;
    }
}
private func getStreakNumColor () -> LinearGradient {
    let hour = Calendar.current.component(.hour, from: Date())
    
    if( hour >= 12 && hour <= 24) {
        return TextColors.streakGradientAwake;
    } else {
        return TextColors.streakGradientRest;
    }
}
private func getTimeOfDayText() -> String {
    let hour = Calendar.current.component(.hour, from: Date())
    
    if( hour >= 6 && hour <= 11) {
        return "this morning"
    } else if( hour >= 11 && hour <= 17 ) {
        return "this afternoon"
    } else {
        return "tonight"
    }
}
#Preview {
    FocusView()

}
