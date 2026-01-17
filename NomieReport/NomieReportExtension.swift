import DeviceActivity
import SwiftUI

private enum NomieReportContext {
    static let daily = DeviceActivityReport.Context("daily")
    static let weekly = DeviceActivityReport.Context("weekly")
}

@main
struct NomieReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        NomieReportScene(context: NomieReportContext.daily, title: "Today's Screen Time")
        NomieReportScene(context: NomieReportContext.weekly, title: "Weekly Screen Time")
    }
}

struct NomieReportScene: DeviceActivityReportScene {
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> DeviceActivityResults<DeviceActivityData> {
        data
    }
    
    let context: DeviceActivityReport.Context
    let title: String

    let content: (DeviceActivityResults<DeviceActivityData>) -> NomieReportView

    init(context: DeviceActivityReport.Context, title: String) {
        self.context = context
        self.title = title
        self.content = { data in
            NomieReportView(title: title, data: data)
        }
    }
}

struct NomieReportView: View {
    let title: String
    let data: DeviceActivityResults<DeviceActivityData>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(formattedDuration)
                .font(.title2.bold())
            Text("Total usage across your selected apps.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            totalDuration = await loadTotalDuration()
        }
    }

    private var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = totalDuration >= 3600 ? [.hour, .minute] : [.minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: totalDuration) ?? "0m"
    }

    @State private var totalDuration: TimeInterval = 0

    private func loadTotalDuration() async -> TimeInterval {
        var total: TimeInterval = 0
        for await day in data {
            for await segment in day.activitySegments {
                total += segment.totalActivityDuration
            }
        }
        return total
    }
}
