import SwiftData
import SwiftUI

struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: TaskItem.listOrder) private var tasks: [TaskItem]
    @State private var editing: TaskItem?
    @State private var pendingUndo: PendingUndo?
    /// 右上の「編集」で切り替える。編集中は各タスクの左に削除ボタン、右に文の変更ボタンが出る。
    ///
    /// iOS 標準の編集モード(EditMode)は、行の左に削除ボタンの場所を差し込んで文字を横にずらし、切り替えにも動きが付く。
    /// ここでは文字を動かさないよう、標準の編集モードは使わず、行の左右にいつも同じ幅の場所を取っておいて中身だけを入れ替える。
    @State private var isEditing: Bool = {
        #if DEBUG
        // スクリーンショット用。起動引数 -editTasks で、編集中の状態から始める
        if ProcessInfo.processInfo.arguments.contains("-editTasks") { return true }
        #endif
        return false
    }()
    /// 並べ替えの処理。編集中は nil にして、つまみ(三本線)を出さない。
    private var moveAction: ((IndexSet, Int) -> Void)? {
        if isEditing { return nil }
        return { source, destination in move(from: source, to: destination) }
    }

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
                        // 長押しして上下に動かす。ウィジェットもこの順で上から表示する。
                        // 編集中は並べ替えのつまみ(三本線)が出て画面がくどくなるので、並べ替えはふだんの表示だけにする
                        .onMove(perform: moveAction)
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
            .toolbar {
                // 文の変更と削除のボタンを全部の行に出すと画面がくどくなるので、右上の1か所から出し入れする
                if !tasks.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isEditing ? "完了" : "編集") {
                            isEditing.toggle()
                        }
                        .fontWeight(isEditing ? .bold : .regular)
                    }
                }
            }
            .onChange(of: tasks.isEmpty) {
                if tasks.isEmpty { isEditing = false }
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
    /// 編集中は、左の削除ボタン(マイナス)と右の文の変更ボタン(紙と鉛筆)で操作し、行を押しても完了は切り替えない。
    /// 左右の場所の幅は編集中もふだんも同じなので、切り替えても文字の位置と折り返しは変わらない。
    private func row(for task: TaskItem) -> some View {
        HStack(spacing: 4) {
            Group {
                if isEditing {
                    Button {
                        delete([task], message: "タスクを削除しました")
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .red)
                            .frame(width: 44, height: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("削除")
                } else {
                    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
            }
            Text(task.title)
                .frame(maxWidth: .infinity, alignment: .leading)
            Group {
                if isEditing {
                    Button {
                        editing = task
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("文を変更")
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                        .accessibilityHidden(true)
                }
            }
        }
        .opacity(task.isDone ? 0.45 : 1)
        .contentShape(.rect)
        .onTapGesture {
            if !isEditing { toggle(task) }
        }
        .accessibilityElement(children: isEditing ? .contain : .ignore)
        .accessibilityLabel(isEditing ? "" : task.title)
        .accessibilityValue(isEditing ? "" : (task.isDone ? "完了" : "未完了"))
        .accessibilityHint(isEditing ? "" : (task.isDone ? "未完了に戻します" : "完了にします"))
        .accessibilityAddTraits(isEditing ? [] : .isButton)
        .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
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
