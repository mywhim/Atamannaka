import SwiftData
import SwiftUI
import WidgetKit

@main
struct AtamannakaWidgetBundle: WidgetBundle {
    var body: some Widget {
        TaskWidget()
    }
}

/// 未完了のタスクを一覧の順に上から最大6件表示する。完了操作は置かず、タップでタスク一覧を開く。
/// 文字だけが並ぶと読み飛ばしてしまうので、1行だけ色を敷いて、その行は読んでもらえるようにする。
struct TaskWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TaskWidget", provider: TaskProvider()) { entry in
            TaskWidgetView(entry: entry)
        }
        .configurationDisplayName("タスク")
        .description("未完了のタスクを表示します。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let titles: [String]
    /// 色を敷く行の番号。タスクがないときは nil。
    let highlight: Int?
    /// App Group の領域を読めたか。読めないときは空の一覧と区別して知らせる。
    let canReadAppData: Bool
}

struct TaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: .now, titles: ["ゼミの発表スライドを作る", "歯医者の予約を取る", "牛乳と卵を買う"], highlight: 1, canReadAppData: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        guard !context.isPreview, let titles = loadTitles() else {
            completion(context.isPreview ? placeholder(in: context) : unreadable)
            return
        }
        var generator = SystemRandomNumberGenerator()
        let highlight = WidgetHighlight.indices(rowCount: titles.count, length: 1, using: &generator)[0]
        completion(TaskEntry(date: .now, titles: titles, highlight: highlight, canReadAppData: true))
    }

    /// 色を敷く行を変えた表示を、先の時刻の分までまとめて作る。使い切ったら次を作る。
    /// タスクが変わったときは、アプリが作り直しを頼む。
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        guard let titles = loadTitles() else {
            completion(Timeline(entries: [unreadable], policy: .never))
            return
        }
        var generator = SystemRandomNumberGenerator()
        let indices = WidgetHighlight.indices(rowCount: titles.count, length: WidgetHighlight.entryCount, using: &generator)
        let start = Date.now
        let entries = indices.enumerated().map { step, highlight in
            TaskEntry(
                date: start.addingTimeInterval(Double(step) * WidgetHighlight.interval),
                titles: titles,
                highlight: highlight,
                canReadAppData: true
            )
        }
        completion(Timeline(entries: entries, policy: titles.count > 1 ? .atEnd : .never))
    }

    private var unreadable: TaskEntry {
        TaskEntry(date: .now, titles: [], highlight: nil, canReadAppData: false)
    }

    private func loadTitles() -> [String]? {
        guard SharedStore.isShared, let container = try? SharedStore.makeContainer() else { return nil }
        var descriptor = TaskItem.openTasks
        descriptor.fetchLimit = WidgetHighlight.maxRows
        let tasks = (try? ModelContext(container).fetch(descriptor)) ?? []
        return tasks.map { $0.title.replacingOccurrences(of: "\n", with: " ") }
    }
}

struct TaskWidgetView: View {
    let entry: TaskEntry

    var body: some View {
        Group {
            if !entry.canReadAppData {
                message("アプリのデータを読めません")
            } else if entry.titles.isEmpty {
                message("タスクはありません")
            } else {
                // 入りきらないときは、残りの件数を出さずに入るところまでだけ並べる
                ViewThatFits(in: .vertical) {
                    ForEach((1...entry.titles.count).reversed(), id: \.self) { count in
                        rows(count)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.background, for: .widget)
        .widgetURL(AppLink.tasks)
    }

    private func rows(_ count: Int) -> some View {
        // 入りきらず行を減らしたときも、色を敷く行が消えないようにする
        let highlight = entry.highlight.map { $0 % count }
        return VStack(alignment: .leading, spacing: 2) {
            ForEach(0..<count, id: \.self) { index in
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Image(systemName: "circle")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                    Text(entry.titles[index])
                        .font(.footnote)
                        .lineLimit(1)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(index == highlight ? Color.marker : .clear, in: .rect(cornerRadius: 4))
            }
        }
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

#Preview(as: .systemSmall) {
    TaskWidget()
} timeline: {
    TaskEntry(
        date: .now,
        titles: ["ゼミの発表スライドを作る", "歯医者の予約を取る", "牛乳と卵を買う", "ES を見直す", "図書館に本を返す", "レポートの参考文献を探す"],
        highlight: 2,
        canReadAppData: true
    )
    TaskEntry(date: .now, titles: [], highlight: nil, canReadAppData: true)
}
