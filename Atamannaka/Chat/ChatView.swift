import SwiftData
import SwiftUI

struct ChatView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.createdAt) private var notes: [Note]
    /// 書きかけは画面を離れても、アプリを閉じても残す。
    @AppStorage("chat.draft") private var draft = ""
    @State private var deleted: DeletedNote?

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
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        if note.task == nil {
                                            Button {
                                                makeTask(from: note)
                                            } label: {
                                                Label("タスクにする", systemImage: "checklist")
                                            }
                                            .tint(.orange)
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
                .overlay(alignment: .bottom) {
                    if let deleted {
                        UndoToast(message: "メモを削除しました") { restore(deleted) }
                    }
                }
                .task(id: deleted?.id) {
                    guard deleted != nil else { return }
                    try? await Task.sleep(for: .seconds(6))
                    withAnimation { deleted = nil }
                }
                .onChange(of: notes.last?.persistentModelID) {
                    // 末尾にメモが増えたときだけ下へ送る。削除や元に戻すでは動かさない
                    guard deleted == nil, let last = rows.last else { return }
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
            context.insert(TaskItem(title: note.text, sourceNote: note))
        }
        context.commit()
    }

    /// メモを消しても、そこから作ったタスクは残す。タスクはもう独り立ちした「やること」なので。
    private func delete(_ note: Note) {
        let snapshot = DeletedNote(note)
        withAnimation {
            context.delete(note)
            deleted = snapshot
        }
        context.commit(reloadingWidget: false)
    }

    private func restore(_ snapshot: DeletedNote) {
        withAnimation {
            snapshot.restore(into: context)
            deleted = nil
        }
        context.commit(reloadingWidget: false)
    }
}

/// 削除を元に戻すために控えておく内容。
struct DeletedNote: Identifiable {
    let id = UUID()
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
        Text(date.dayText)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
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
private struct NoteRow: View {
    let note: Note

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(highlightedText)
                .font(.system(size: 17))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(note.createdAt.clockText)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
        .listRowSeparator(.hidden)
        .accessibilityElement(children: .combine)
        .accessibilityValue(note.task == nil ? "" : "タスク")
    }

    /// 行ごとに色が付く蛍光ペン風のハイライトにするため、背景ではなく文字の属性として付ける。
    private var highlightedText: AttributedString {
        var text = AttributedString(note.text)
        if note.task != nil {
            text.backgroundColor = .marker
        }
        return text
    }
}
