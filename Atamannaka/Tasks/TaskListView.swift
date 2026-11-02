import SwiftData
import SwiftUI

struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.createdAt) private var tasks: [TaskItem]
    @State private var editing: TaskItem?
    @State private var deleted: DeletedTask?

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
                }
                if !doneTasks.isEmpty {
                    Section("完了") {
                        ForEach(doneTasks) { row(for: $0) }
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
            .overlay(alignment: .bottom) {
                if let deleted {
                    UndoToast(message: "タスクを削除しました") { restore(deleted) }
                }
            }
            .task(id: deleted?.id) {
                guard deleted != nil else { return }
                try? await Task.sleep(for: .seconds(6))
                withAnimation { deleted = nil }
            }
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
                delete(task)
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

    private func delete(_ task: TaskItem) {
        let snapshot = DeletedTask(task)
        withAnimation {
            context.delete(task)
            deleted = snapshot
        }
        context.commit()
    }

    private func restore(_ snapshot: DeletedTask) {
        withAnimation {
            context.insert(snapshot.makeTask())
            deleted = nil
        }
        context.commit()
    }
}

/// 削除を元に戻すために控えておく内容。削除した TaskItem 自体は使えなくなるので値で持つ。
private struct DeletedTask: Identifiable {
    let id = UUID()
    let title: String
    let createdAt: Date
    let completedAt: Date?
    let sourceNote: Note?

    init(_ task: TaskItem) {
        title = task.title
        createdAt = task.createdAt
        completedAt = task.completedAt
        sourceNote = task.sourceNote
    }

    func makeTask() -> TaskItem {
        let note = sourceNote?.isDeleted == false ? sourceNote : nil
        return TaskItem(title: title, createdAt: createdAt, completedAt: completedAt, sourceNote: note)
    }
}
