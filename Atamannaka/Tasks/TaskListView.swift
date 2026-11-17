import SwiftData
import SwiftUI

struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: TaskItem.listOrder) private var tasks: [TaskItem]
    @State private var editing: TaskItem?
    @State private var pendingUndo: PendingUndo?
    /// 右上の「編集」で切り替える。編集中は各タスクの左に、削除と文の変更のボタンが出る。
    @State private var editMode: EditMode = {
        #if DEBUG
        // スクリーンショット用。起動引数 -editTasks で、編集中の状態から始める
        if ProcessInfo.processInfo.arguments.contains("-editTasks") { return .active }
        #endif
        return .inactive
    }()

    private var isEditing: Bool { editMode.isEditing }

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
                        .onDelete { offsets in delete(offsets.map { openTasks[$0] }, message: "タスクを削除しました") }
                }
                if !doneTasks.isEmpty {
                    Section {
                        ForEach(doneTasks) { row(for: $0) }
                            .onDelete { offsets in delete(offsets.map { doneTasks[$0] }, message: "タスクを削除しました") }
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
            .environment(\.editMode, $editMode)
            .toolbar {
                // 文の変更と削除のボタンを全部の行に出すと画面がくどくなるので、右上の1か所から出し入れする
                if !tasks.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isEditing ? "完了" : "編集") {
                            withAnimation { editMode = isEditing ? .inactive : .active }
                        }
                        .fontWeight(isEditing ? .bold : .regular)
                    }
                }
            }
            .onChange(of: tasks.isEmpty) {
                if tasks.isEmpty { editMode = .inactive }
            }
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

    /// ふだんは行のどこを押しても完了と未完了が切り替わる。
    /// 編集中は、左に出る削除ボタン(マイナス)と文の変更ボタン(紙と鉛筆)で操作し、行を押しても完了は切り替えない。
    @ViewBuilder
    private func row(for task: TaskItem) -> some View {
        if isEditing {
            HStack(spacing: 4) {
                Button {
                    editing = task
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                        .foregroundStyle(.tint)
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("文を変更")
                Text(task.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .opacity(task.isDone ? 0.45 : 1)
            .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 16))
        } else {
            Button {
                toggle(task)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                    Text(task.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.title)
            .accessibilityValue(task.isDone ? "完了" : "未完了")
            .accessibilityHint(task.isDone ? "未完了に戻します" : "完了にします")
            .opacity(task.isDone ? 0.45 : 1)
            .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 16))
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
