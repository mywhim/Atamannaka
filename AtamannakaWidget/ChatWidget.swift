import SwiftUI
import WidgetKit

/// ひとりチャットを開くためだけのウィジェット。思いついたときに、ホーム画面やロック画面からすぐ書き始められるようにする。
/// 表示する内容は変わらないので、一度作った表示をずっと使う。
struct ChatWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ChatWidget", provider: ChatProvider()) { _ in
            ChatWidgetView()
        }
        .configurationDisplayName("ひとりチャット")
        .description("タップすると、ひとりチャットを開きます。")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

struct ChatEntry: TimelineEntry {
    let date: Date
}

struct ChatProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChatEntry { ChatEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (ChatEntry) -> Void) {
        completion(ChatEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChatEntry>) -> Void) {
        completion(Timeline(entries: [ChatEntry(date: .now)], policy: .never))
    }
}

struct ChatWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if family == .accessoryCircular {
                // ロック画面では単色で描かれるので、形だけで分かる印にする
                ZStack {
                    AccessoryWidgetBackground()
                    mark
                        .font(.system(size: 22, weight: .medium))
                }
            } else {
                VStack(spacing: 10) {
                    mark
                        .font(.system(size: 48, weight: .regular))
                        .foregroundStyle(Color.taskBar)
                    Text("ひとりチャット")
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(AppLink.chat)
        .accessibilityLabel("ひとりチャットを開く")
    }

    /// アプリのアイコンが決まるまでの仮の印。決まったら、アイコンの画像に差し替える。
    private var mark: some View {
        Image(systemName: "text.bubble")
    }
}

#Preview(as: .systemSmall) {
    ChatWidget()
} timeline: {
    ChatEntry(date: .now)
}
