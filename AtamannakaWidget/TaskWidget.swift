import SwiftData
import SwiftUI
import WidgetKit

@main
struct AtamannakaWidgetBundle: WidgetBundle {
    var body: some Widget {
        TaskWidget()
    }
}

/// 未完了のタスクを数件と残りの件数だけ表示する。完了操作は置かず、タップでタスク一覧を開く。
struct TaskWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TaskWidget", provider: TaskProvider()) { entry in
            TaskWidgetView(entry: entry)
        }
        .configurationDisplayName("タスク")
        .description("未完了のタスクを表示します。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let titles: [String]
    let total: Int
    /// App Group の領域を読めたか。読めないときは空の一覧と区別して知らせる。
    let canReadAppData: Bool
}

struct TaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: .now, titles: ["ゼミの発表スライドを作る", "歯医者の予約を取る", "牛乳と卵を買う"], total: 5, canReadAppData: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : load())
    }

    /// 変化はアプリ側から知らせるので、ウィジェット自身では定期更新しない。
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        completion(Timeline(entries: [load()], policy: .never))
    }

    private func load() -> TaskEntry {
        guard SharedStore.isShared, let container = try? SharedStore.makeContainer() else {
            return TaskEntry(date: .now, titles: [], total: 0, canReadAppData: false)
        }
        let tasks = (try? ModelContext(container).fetch(TaskItem.openTasks)) ?? []
        return TaskEntry(date: .now, titles: tasks.prefix(8).map(\.title), total: tasks.count, canReadAppData: true)
    }
}

struct TaskWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TaskEntry

    private var limit: Int { family == .systemLarge ? 8 : 3 }
    private var shown: [String] { Array(entry.titles.prefix(limit)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !entry.canReadAppData {
                Text("アプリのデータを読めません")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if entry.total == 0 {
                Text("タスクはありません")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(shown.enumerated()), id: \.offset) { _, title in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "circle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(title.replacingOccurrences(of: "\n", with: " "))
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }
                if entry.total > shown.count {
                    Text("ほか \(entry.total - shown.count) 件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.background, for: .widget)
        .widgetURL(AppLink.tasks)
    }
}

#Preview(as: .systemSmall) {
    TaskWidget()
} timeline: {
    TaskEntry(date: .now, titles: ["ゼミの発表スライドを作る", "歯医者の予約を取る", "牛乳と卵を買う", "ES を見直す"], total: 6, canReadAppData: true)
    TaskEntry(date: .now, titles: [], total: 0, canReadAppData: true)
}
