import SwiftData
import SwiftUI

@main
struct AtamannakaApp: App {
    let container: ModelContainer

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        do {
            // -inMemory は動作確認用。端末に保存してあるデータには触れずに、使い捨てのデータで起動する
            container = try SharedStore.makeContainer(inMemory: arguments.contains("-inMemory"))
        } catch {
            fatalError("保存先を開けませんでした: \(error)")
        }
        #if DEBUG
        if arguments.contains("-seedSample") {
            SampleData.insertIfEmpty(into: container.mainContext)
        }
        if arguments.contains("-seedMany") {
            SampleData.insertNumbered(1200, into: container.mainContext)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

enum AppTab: Hashable {
    case chat, tasks
}

/// チャットとタスクを隣り合わせに置く。メモを右へスワイプするとタスクになるので、タスクは右側のタブにしている。
struct RootView: View {
    @State private var tab: AppTab = {
        #if DEBUG
        // スクリーンショット用。起動引数 -openTasks でタスク一覧から始める。
        if ProcessInfo.processInfo.arguments.contains("-openTasks") { return .tasks }
        #endif
        return .chat
    }()

    var body: some View {
        TabView(selection: $tab) {
            Tab("チャット", systemImage: "text.alignleft", value: AppTab.chat) {
                ChatView()
            }
            Tab("タスク", systemImage: "checklist", value: AppTab.tasks) {
                TaskListView()
            }
        }
        .onOpenURL { url in
            switch url {
            case AppLink.tasks: tab = .tasks
            case AppLink.chat: tab = .chat
            default: break
            }
        }
    }
}
