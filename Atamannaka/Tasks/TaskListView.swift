import SwiftData
import SwiftUI

struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: TaskItem.listOrder) private var tasks: [TaskItem]
    @State private var editing: TaskItem?
    @State private var pendingUndo: PendingUndo?

    private var openTasks: [TaskItem] { tasks.filter { !$0.isDone } }
    /// 完了したものは、最近完了した順に下へ薄く残す。
    private var doneTasks: [TaskItem] {
        tasks.filter(\.isDone).sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(openTasks) { row(for: $0) }
                        // 長押しして上下に動かす。ウィジェットもこの順で上から表示する
                        .onMove(perform: move)
                }
                if !doneTasks.isEmpty {
                    Section {
                        ForEach(doneTasks) { row(for: $0) }
                    } header: {
                        HStack {
                            Text("完了")
                            Spacer()
                            Button("完了したタスクを削除", role: .destructive, action: deleteDone)
                                .font(.footnote)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .overlay {
                if tasks.isEmpty {
                    ContentUnavailableView(
                        "タスクはありません",
                        systemImage: "checklist",
                        description: Text("チャットのメモを右へスワイプすると、タスクになります。")
                    )
                }
            }
            .undoToast($pendingUndo)
            .sheet(item: $editing) { TaskEditSheet(task: $0) }
            .navigationTitle("タスク")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func row(for task: TaskItem) -> some View {
        HStack(spacing: 4) {
            Button {
                toggle(task)
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isDone ? "未完了に戻す" : "完了にする")

            Button {
                editing = task
            } label: {
                Text(task.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("編集します")
        }
        .opacity(task.isDone ? 0.45 : 1)
        .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 16))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                delete([task], message: "タスクを削除しました")
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    private func toggle(_ task: TaskItem) {
        withAnimation {
            task.completedAt = task.isDone ? nil : .now
        }
        context.commit()
    }

    /// 動かした結果の並びどおりに、未完了のタスクへ番号を振り直す。
    private func move(from source: IndexSet, to destination: Int) {
        var reordered = openTasks
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, task) in reordered.enumerated() {
            task.sortIndex = Double(index)
        }
        context.commit()
    }

    private func deleteDone() {
        let done = doneTasks
        delete(done, message: "完了したタスクを\(done.count)件削除しました")
    }

    private func delete(_ targets: [TaskItem], message: String) {
        let snapshots = targets.map(DeletedTask.init)
        withAnimation {
            targets.forEach(context.delete)
        }
        context.commit()
        pendingUndo = PendingUndo(message: message) { [context] in
            withAnimation {
                snapshots.forEach { $0.restore(into: context) }
            }
            context.commit()
        }
    }
}
