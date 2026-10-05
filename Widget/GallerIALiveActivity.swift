import ActivityKit
import WidgetKit
import SwiftUI

public struct GalleryScanAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var progress: Int
        var total: Int
        var isFinished: Bool
    }

    var scanName: String
}

@main
struct GallerIAWidgetBundle: WidgetBundle {
    var body: some Widget {
        GallerIAWidget()
        GallerIALiveActivity()
    }
}

struct GallerIALiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GalleryScanAttributes.self) { context in
            // Lock screen / banner view
            VStack {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.cyan)
                    Text("GallerIA Pro Scansione")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    if context.state.isFinished {
                        Text("Completato!")
                            .bold()
                            .foregroundColor(.green)
                    } else {
                        Text("\(context.state.progress)/\(context.state.total)")
                            .monospacedDigit()
                            .foregroundColor(.gray)
                    }
                }

                ProgressView(value: Double(context.state.progress), total: Double(context.state.total))
                    .tint(.cyan)
            }
            .padding()
            .background(Color.black.opacity(0.8))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "sparkles.tv")
                        .foregroundColor(.cyan)
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.progress)/\(context.state.total)")
                        .monospacedDigit()
                        .bold()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: Double(context.state.progress), total: Double(context.state.total))
                        .tint(.cyan)
                        .padding(.horizontal)
                }
            } compactLeading: {
                Image(systemName: "sparkles")
                    .foregroundColor(.cyan)
            } compactTrailing: {
                Text("\(Int((Double(context.state.progress) / Double(max(1, context.state.total))) * 100))%")
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "sparkles")
                    .foregroundColor(.cyan)
            }
        }
    }
}
