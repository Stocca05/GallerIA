import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) { completion(SimpleEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        completion(Timeline(entries: [SimpleEntry(date: .now)], policy: .never))
    }
}

struct SimpleEntry: TimelineEntry { let date: Date }

struct GallerIAWidgetEntryView: View {
    var entry: SimpleEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("GallerIA", systemImage: "square.stack.3d.up").font(.headline)
            Spacer()
            Text("Fai spazio a ciò che ami.").font(.title3.weight(.medium))
            Label("Apri la tua libreria", systemImage: "arrow.up.right").font(.caption)
        }
        .foregroundStyle(Color(red: 0.79, green: 0.93, blue: 0.63))
        .containerBackground(Color(red: 0.055, green: 0.067, blue: 0.063), for: .widget)
    }
}

struct GallerIAWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GallerIAWidget", provider: Provider()) { GallerIAWidgetEntryView(entry: $0) }
            .configurationDisplayName("La tua libreria")
            .description("Un invito a riscoprire i tuoi ricordi. Tocca per aprire GallerIA.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}
