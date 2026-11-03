import SwiftData
import SwiftUI

struct ChatView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.createdAt) private var notes: [Note]
    /// 書きかけは画面を離れても、アプリを閉じても残す。
    @AppStorage("chat.draft") private var draft = ""
    @State private var pendingUndo: PendingUndo?

    private var rows: [ChatRow<PersistentIdentifier>] {
        ChatTimeline.rows(for: notes.map { ($0.persistentModelID, $0.createdAt) })
    }

    var body: some View {
        let byID = Dictionary(uniqueKeysWithValues: notes.map { ($0.persistentModelID, $0) })
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(rows, id: \.self) { row in
                        switch row {
                        case .day(let date):
                            DayHeader(date: date)
                        case .gap:
                            GapLine()
                        case .note(let id):
                            if let note = byID[id] {
                                NoteRow(note: note)
                                    // タスクのタブは右隣にあるので、右へスワイプしてタスクにする。同じ動作で解除もできる。
                                    // 解除は直した題名などが消えるので、スワイプしきっただけでは実行せず、ボタンを押してもらう
                                    .swipeActions(edge: .leading, allowsFullSwipe: note.task == nil) {
                                        if note.task == nil {
                                            Button {
                                                makeTask(from: note)
                                            } label: {
                                                Label("タスクにする", systemImage: "checklist")
                                            }
                                            .tint(.orange)
                                        } else {
                                            Button {
                                                removeTask(from: note)
                                            } label: {
                                                Label("タスク解除", systemImage: "xmark")
                                            }
                                            .tint(.gray)
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            delete(note)
                                        } label: {
                                            Label("削除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                // 区切り線や日付見出しの行が 44pt の最小高さで間延びしないようにする
                .environment(\.defaultMinListRowHeight, 1)
                .defaultScrollAnchor(.bottom)
                .defaultScrollAnchor(.bottom, for: .sizeChanges)
                .scrollDismissesKeyboard(.interactively)
                .overlay {
                    if notes.isEmpty {
                        Text("まだ何もありません")
                            .foregroundStyle(.secondary)
                    }
                }
                .undoToast($pendingUndo)
                .onChange(of: notes.last?.persistentModelID) {
                    // 末尾にメモが増えたときだけ下へ送る。削除や元に戻すでは動かさない
                    guard pendingUndo == nil, let last = rows.last else { return }
                    withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ComposerBar(text: $draft, onSend: add)
            }
            .navigationTitle("ひとりチャット")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func add(_ text: String) {
        context.insert(Note(text: text))
        context.commit(reloadingWidget: false)
    }

    private func makeTask(from note: Note) {
        withAnimation {
            context.insert(TaskItem(title: note.text, sourceNote: note, sortIndex: TaskItem.nextSortIndex(in: context)))
        }
        context.commit()
    }

    /// タスクを消して、メモの行の色を外す。
    private func removeTask(from note: Note) {
        guard let task = note.task else { return }
        withAnimation { context.delete(task) }
        context.commit()
    }

    /// メモを消しても、そこから作ったタスクは残す。タスクはもう独り立ちした「やること」なので。
    private func delete(_ note: Note) {
        let snapshot = DeletedNote(note)
        withAnimation { context.delete(note) }
        context.commit(reloadingWidget: false)
        pendingUndo = PendingUndo(message: "メモを削除しました") { [context] in
            withAnimation { snapshot.restore(into: context) }
            context.commit(reloadingWidget: false)
        }
    }
}

/// 削除を元に戻すために控えておく内容。
struct DeletedNote {
    let text: String
    let createdAt: Date
    let task: TaskItem?

    init(_ note: Note) {
        text = note.text
        createdAt = note.createdAt
        task = note.task
    }

    /// メモを作り直し、タスクがまだ残っていればつなぎ直してハイライトも戻す。
    @discardableResult
    func restore(into context: ModelContext) -> Note {
        let note = Note(text: text, createdAt: createdAt)
        context.insert(note)
        if let task, !task.isDeleted, task.sourceNote == nil {
            task.sourceNote = note
        }
        return note
    }
}

private struct DayHeader: View {
    let date: Date

    var body: some View {
        // 時刻と同じく右に寄せる
        Text(date.dayText)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 2, trailing: 16))
            .listRowSeparator(.hidden)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct GapLine: View {
    var body: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(height: 1)
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            .listRowSeparator(.hidden)
            .accessibilityHidden(true)
    }
}

/// 吹き出しを使わず、本文と追加時刻だけを並べる。
/// タスクにしたメモは行全体に色を敷き、タスクを完了したら本文に取り消し線を引く。
private struct NoteRow: View {
    let note: Note

    private var isTask: Bool { note.task != nil }
    private var isDone: Bool { note.task?.isDone == true }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(note.text)
                .font(.system(size: 17))
                .lineSpacing(4)
                .strikethrough(isDone)
                .foregroundStyle(isDone ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(note.createdAt.clockText)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
        .listRowSeparator(.hidden)
        // 上下を少し空けて、タスクのメモが続いても1行ずつ分かれて見えるようにする
        .listRowBackground(isTask ? Color.marker.padding(.vertical, 2) : nil)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isDone ? "完了したタスク" : isTask ? "タスク" : "")
    }
}
