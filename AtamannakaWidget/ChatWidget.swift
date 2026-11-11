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
                // ロック画面では単色で描かれるので、アイコンから取り出した「あ!」の形だけを使う。
                // ウィジェットで使える画像の大きさには上限があり、超えると何も描かれない。
                // そのため画像は、表示する大きさ(3倍の解像度)に合わせて小さくしてある
                ZStack {
                    AccessoryWidgetBackground()
                    Image("ChatMark")
                        .resizable()
                        .scaledToFit()
                        .padding(11)
                }
            } else {
                VStack(spacing: 10) {
                    Image("ChatIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 76, height: 76)
                        .clipShape(.rect(cornerRadius: 17, style: .continuous))
                        // アイコンの白い背景がウィジェットの背景に溶けないよう、薄い枠で形を見せる
                        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Color(.systemGray4), lineWidth: 1))
                    Text("ひとりチャット")
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(AppLink.chat)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ひとりチャットを開く")
    }
}

#Preview(as: .systemSmall) {
    ChatWidget()
} timeline: {
    ChatEntry(date: .now)
}
