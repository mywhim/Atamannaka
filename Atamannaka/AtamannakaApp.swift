import SwiftData
import SwiftUI

@main
struct AtamannakaApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try SharedStore.makeContainer()
        } catch {
            fatalError("保存先を開けませんでした: \(error)")
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-seedSample") {
            SampleData.insertIfEmpty(into: container.mainContext)
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
            if url == AppLink.tasks { tab = .tasks }
        }
    }
}
