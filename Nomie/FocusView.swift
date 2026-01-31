//
//  FocusView.swift
//  Nomie
//

import SwiftUI

struct FocusView: View {
    @State private var usage: [CategoryUsage] = [
        .init(id: .connection, usage: 4 * 3600 + 32 * 60, maxUsage: 5 * 3600, type: "Prioritize"),
        .init(id: .creativity, usage: 3 * 3600 + 45 * 60, maxUsage: 5 * 3600, type: "Prioritize"),
        .init(id: .drifting, usage: 2 * 3600 + 58 * 60, maxUsage: 5 * 3600, type: "Limit"),
        .init(id: .entertainment, usage: 1 * 3600 + 40 * 60, maxUsage: 5 * 3600, type: "Limit"),
        .init(id: .learning, usage: 52 * 60, maxUsage: 5 * 3600, type: "Prioritize"),
        .init(id: .productivity, usage: 46 * 60, maxUsage: 5 * 3600, type: "Prioritize")
    ]
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    FocusHeader(name: "Name", streakDays: 8)
                    DailyInsights(category: "Creativity", timeOfDay: "Morning")
                    Charts(usage: usage)
                    GoalsView(usage: usage)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationTitle("Focus")
    }
}

struct FocusHeader : View {
    let name: String
    let streakDays: Int
    var body: some View {
        GeometryReader {geo in
            VStack {
                Text("Hello, " + name)
                    .font(.system(size: 40, weight: .medium))
                    .kerning(0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
                    .padding(.top, geo.safeAreaInsets.top + 50)
                HStack {
                        Text("Streaks:" )
                        .font(.system(size:20, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("\(streakDays) days")
                            .font(.system(size:20, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 55)
                }.padding(.leading, 68)
                    .padding(.top, 10)
                StreakList()
            }
            .frame(maxWidth: .infinity,minHeight: 272,  alignment: .topLeading)
            .background(FocusColors.background)
        }
        .frame(height:272)


        

    }
}
struct tempStreakIcon: View {
    let color: Color
    var body : some View {
        ZStack {
            Circle()
                .fill(FocusColors.tempGreen.opacity(1))
                .blur(radius:3)
                .frame(width: 90, height: 90)
        }
    }
}
struct StreakList: View {
    var body: some View {
        HStack {
            tempStreakIcon(color: FocusColors.tempGreen)
            tempStreakIcon(color: FocusColors.tempGreen)
            tempStreakIcon(color: FocusColors.tempGreen)
        }
    }
}

struct DailyInsights: View {
    let category: String
    let timeOfDay: String
    var body: some View {
        VStack {
            Text("Daily Insights")
                .font(.system(size: 32, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 13)
            Text("You are heavy on the " + category + " apps this " + timeOfDay + ".")
                .font(.system(size: 20, weight: .medium))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius:30).fill(FocusColors.background)
                        .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 4)
                        
                )

        }
    }
}
struct Charts: View {
    let usage: [CategoryUsage]
    var totalSeconds: Int {
        usage.reduce(0) { $0 + $1.usage }
    }
    var body: some View {
        VStack {
            ChartHeader(totalSeconds: totalSeconds)
            RadarChart()
            BarChartView(usage: usage)
            
        }
        
    }
}
struct ChartHeader: View {
    let totalSeconds: Int;

    var body: some View {
        Text("Total Usage: " + formatSeconds(totalSeconds))
            .font(.system(size: 32, weight: .medium, ))
            .italic()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 13)
    }
}
struct RadarChart: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.gray.opacity(0.5))
            .frame(width: 377, height:377)
            .overlay{
                Text("PlaceHolder")
            }
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
                Capsule().fill(Color.black.opacity(0.2))
                Capsule().fill(Color.black.opacity(0.5))
                    .frame(width:usageWidth)
            }
        }.frame(height: height)
    }
}
struct BarChartRow: View {
    let categoryUsage: CategoryUsage
    var body: some View {
        HStack(spacing: 16) {
            Text(categoryUsage.id.title).font(.system(size:10)).frame(width: 60, alignment: .leading).padding(.leading, 13)
            BarChart(usage: categoryUsage.usage, maxUsage: categoryUsage.maxUsage, height: nil)
            Text("\(formatSeconds(categoryUsage.usage))").frame(width: 60, alignment: .trailing).font(.system(size:10)).padding(.trailing, 13)
            
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
    let usage: [CategoryUsage]
    var body: some View {
        VStack {
            Text("Goals").font(.system(size:32, weight:.medium)).frame(maxWidth: .infinity, alignment: .leading)
            GoalsPill(usage:usage).background(FocusColors.background).cornerRadius(30)
        }.padding(13)
    }
}

struct GoalsPill: View {
    let usage: [CategoryUsage]
    var body: some View {
        VStack {
            Text("You are \(usage.reduce(0) {$0 + $1.usage} <= usage.reduce(0) {$0 + $1.maxUsage} ? "" : "not")on track to meet today's goals!").font(.system(size:20, weight:.regular)).multilineTextAlignment(.leading).padding(16).frame(maxWidth: .infinity, alignment: .leading)
            NavigationLink {
                MyGoalsView(usage: usage)
            } label: {
                Text("View & Set Goals").font(.system(size: 20, weight:.medium)).frame(maxWidth: .infinity, alignment:.leading).padding(16).foregroundColor(.black)
            }
        }
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
    let usage: [CategoryUsage]
    
    var body: some View {
        ScrollView {
            ZStack {
                VStack {
                    VStack{
                        LimitGoals(usage: usage)
                        PrioritizeGoals(usage: usage)
                    }
                }
                .safeAreaInset(edge: .top) {
                    MyGoalsHeader()
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .navigationBarBackButtonHidden(true)
            }
        }.overlay(alignment: .bottomTrailing) {
            AddGoalButton()
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
    let usage: [CategoryUsage]
    var body: some View {
        Text("Limit").font(.system(size:32, weight:.medium)).frame(maxWidth: .infinity, alignment:.leading).padding(.leading, 13)
        ForEach(usage.filter {$0.type == "Limit"}) {item in
            ProgressComponent(categoryUsage: item).padding(.horizontal, 30).padding(.vertical, 8)
        }
    }
}
struct PrioritizeGoals: View {
    let usage: [CategoryUsage]
    var body: some View {
        Text("Prioritize").font(.system(size:32, weight:.medium)).frame(maxWidth: .infinity, alignment:.leading).padding(.leading, 13)
        ForEach(usage.filter {$0.type == "Prioritize"}) {item in
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
                Text("\(categoryUsage.id)").font(.system(size:24, weight: .regular)).frame(maxWidth:.infinity, alignment: .leading).padding(.leading ,13)
                Text("\(minutesLeft) min left").font(.system(size:24, weight: .regular)).frame(maxWidth:.infinity, alignment: .trailing).padding(.trailing,13)
            }
            BarChart(usage:categoryUsage.usage, maxUsage: categoryUsage.maxUsage, height: 30).padding(.horizontal,13)
        }.frame(width: 343).frame(height:113).background(FocusColors.background).cornerRadius(20)
    }
}

struct AddGoalButton: View {
    var body: some View {
        NavigationLink {
            SetGoalView()
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
    var body: some View {
        ScrollView {
            VStack {
                CategoryDropdown().padding(.top, 20)
            }.safeAreaInset(edge: .top) {
                SetGoalHeader()
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).toolbar(.hidden, for:.navigationBar)
        }
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
        
    }
}
struct CategoryDropdown: View {
    @State private var selected: CategoryID = .drifting
    var body: some View {
        VStack {
            Text("Select a Category").font(.system(size: 24, weight: .regular)).frame(maxWidth:.infinity, alignment:.leading).padding(.leading, 10)
            Menu {
                ForEach(CategoryID.allCases) {category in
                    Button(category.rawValue) {
                        selected = category
                    }
                }
            } label: {
                HStack {
                    Text(selected.rawValue).font(.system(size:20, weight:.regular)).frame(maxWidth: .infinity, alignment: .leading).padding(.leading,10)
                    Image(systemName: "chevron.down").font(.system(size:18)).frame(maxWidth:.infinity, alignment:.trailing).padding(.trailing, 10)
                }.padding(.leading, 13).frame(height:47).background(Color.white).cornerRadius(15)
            }.buttonStyle(.plain)
        }.padding(.horizontal, 13).background(
            RoundedRectangle(cornerRadius:20, style: .continuous).fill(FocusColors.background).frame(height:118)
        )
    }
}

enum FocusColors {
    static let background = Color(
        red: 217.0 / 255.0,
        green: 217.0 / 255.0,
        blue: 217.0 / 255.0
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
struct CategoryUsage: Identifiable, Codable {
    var id: CategoryID
    var usage: Int
    var maxUsage: Int
    var type: String
}
func formatSeconds(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let mins = (seconds % 3600) / 60
    return String(hours > 0 ? "\(hours) hr \(mins) min" : "\(mins) min")
}
let mockUsage: [CategoryUsage] = [
    .init(id: .creativity, usage: 3600, maxUsage: 7200, type: "Limit"),
    .init(id: .productivity, usage: 1800, maxUsage: 7200, type: "Prioritize")
]
#Preview {
    FocusView()

}
