//
//  FocusView.swift
//  Nomie
//

import SwiftUI

struct FocusView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    FocusHeader(name: "Name", streakDays: 8)
                    DailyInsights(category: "Creativity", timeOfDay: "Morning")
                    Charts()
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

                        Text("\(streakDays)")
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
    @State private var usage: [CategoryUsage] = [
        .init(id: .connection, usage: 4 * 3600 + 32 * 60, maxUsage: 5 * 3600),
        .init(id: .creativity, usage: 3 * 3600 + 45 * 60, maxUsage: 5 * 3600),
        .init(id: .drifting, usage: 2 * 3600 + 58 * 60, maxUsage: 5 * 3600),
        .init(id: .entertainment, usage: 1 * 3600 + 40 * 60, maxUsage: 5 * 3600),
        .init(id: .learning, usage: 52 * 60, maxUsage: 5 * 3600),
        .init(id: .productivity, usage: 46 * 60, maxUsage: 5 * 3600)
    ]
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
            .font(.system(size: 32, weight: .medium ))
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
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let usageWidth = width * CGFloat(usage) / CGFloat(maxUsage)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.2))
                Capsule().fill(Color.black.opacity(0.5))
                    .frame(width:usageWidth)
            }
        }
    }
}
struct BarChartRow: View {
    let categoryUsage: CategoryUsage
    var body: some View {
        HStack(spacing: 16) {
            Text(categoryUsage.id.title).font(.system(size:10)).frame(width: 60, alignment: .leading).padding(.leading, 13)
            BarChart(usage: categoryUsage.usage, maxUsage: categoryUsage.maxUsage)
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
    var body: some View {
        EmptyView()
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
enum CategoryID: String, Codable, CaseIterable {
    case creativity, connection, drifting, entertainment, productivity, learning
    
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
}
func formatSeconds(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let mins = (seconds % 3600) / 60
    return String(hours > 0 ? "\(hours) hr \(mins) min" : "\(mins) min")
}
#Preview {
    FocusView()
}
