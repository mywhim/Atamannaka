import SwiftData
import SwiftUI

struct ChatView: View {
    @Environment(\.modelContext) private var context
    /// 書きかけは画面を離れても、アプリを閉じても残す。
    @AppStorage("chat.draft") private var draft = ""
    @State private var pendingUndo: PendingUndo?
    /// 読み込むメモの件数。いちばん上までスクロールすると増やす。
    @State private var limit = ChatTimeline.pageSize

    var body: some View {
        NavigationStack {
            // 入力欄はリストに重ねず、下に並べる。重ねると、下端へのスクロールで最後のメモが入力欄の下に隠れるため
            VStack(spacing: 0) {
                NoteList(limit: $limit, pendingUndo: $pendingUndo)
                    .undoToast($pendingUndo)
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
}

/// メモを新しいものから limit 件だけ読み込み、古い順に並べる。
///
/// 開くたびに全部を読み込むと、メモが増えるほど開くのが遅くなり、手軽に書けるというこのアプリの良さが消えてしまう。
/// そこで最初は新しい500件だけにして、いちばん上までスクロールしたら、その前の500件を読み足す。
private struct NoteList: View {
    @Environment(\.modelContext) private var context
    @Query private var newestFirst: [Note]
    @Binding var limit: Int
    @Binding var pendingUndo: PendingUndo?
    /// 古いメモを読み足す直前に、いちばん上にあったメモ。読み足したあとも同じ位置に見えるようにする。
    @State private var anchorID: PersistentIdentifier?
    /// 開いた直後にいちばん下へ送り終えたか。送り終えるまでは、上にいても古いメモを読み足さない。
    @State private var isReady = false
    /// 表示しているところから内容の下端までの距離。0 ならいちばん下まで見えている。
    @State private var distanceToBottom: CGFloat = .infinity
    /// リストの最後に置く余白の行。最後のメモが入力欄に張り付かないよう間を空け、下端へ送るときの目印にもする。
    private static let bottomID = "chat.bottom"

    init(limit: Binding<Int>, pendingUndo: Binding<PendingUndo?>) {
        _limit = limit
        _pendingUndo = pendingUndo
        var descriptor = FetchDescriptor<Note>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = limit.wrappedValue
        _newestFirst = Query(descriptor)
    }

    private var notes: [Note] { newestFirst.reversed() }

    private var rows: [ChatRow<PersistentIdentifier>] {
        ChatTimeline.rows(for: notes.map { ($0.persistentModelID, $0.createdAt) })
    }

    var body: some View {
        let byID = Dictionary(uniqueKeysWithValues: newestFirst.map { ($0.persistentModelID, $0) })
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
                Color.clear
                    .frame(height: 12)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .id(Self.bottomID)
            }
            .listStyle(.plain)
            // 区切り線や日付見出しの行が 44pt の最小高さで間延びしないようにする
            .environment(\.defaultMinListRowHeight, 1)
            .defaultScrollAnchor(.bottom)
            .defaultScrollAnchor(.bottom, for: .sizeChanges)
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                if newestFirst.isEmpty {
                    Text("まだ何もありません")
                        .foregroundStyle(.secondary)
                }
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top < 200
            } action: { _, isNearTop in
                if isNearTop { loadOlder() }
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                max(0, geometry.contentSize.height - geometry.visibleRect.maxY)
            } action: { _, distance in
                distanceToBottom = distance
            }
            .onChange(of: newestFirst.count) {
                guard let anchorID else { return }
                proxy.scrollTo(ChatRow.note(anchorID), anchor: .top)
                self.anchorID = nil
            }
            .onChange(of: newestFirst.first?.persistentModelID) {
                // 末尾にメモが増えたときだけ下へ送る。削除や元に戻すでは動かさない
                guard pendingUndo == nil else { return }
                Task { await scrollToBottom(proxy) }
            }
            .task {
                // メモが画面に入りきらないほどあると、defaultScrollAnchor だけでは最初にいちばん下が表示されない。
                // 開いたら自分でいちばん下へ送り、そのあとで読み足しを受け付ける
                await scrollToBottom(proxy)
                isReady = true
                #if DEBUG
                // 動作確認用。起動引数 -scrollToTop で、起動後にいちばん上までスクロールする
                if ProcessInfo.processInfo.arguments.contains("-scrollToTop"), let first = rows.first {
                    try? await Task.sleep(for: .seconds(1))
                    proxy.scrollTo(first, anchor: .top)
                }
                #endif
            }
        }
    }

    /// いちばん下まで送る。
    /// 行の高さは表示してみるまで見積もりで、測るたびに内容全体が伸びる。そのため1回送っただけでは下端の手前で止まるので、
    /// 2回続けて下端にいると確かめられるまで送り直す。
    private func scrollToBottom(_ proxy: ScrollViewProxy) async {
        var settled = 0
        for _ in 0..<20 where settled < 2 {
            proxy.scrollTo(Self.bottomID, anchor: .bottom)
            try? await Task.sleep(for: .milliseconds(80))
            settled = distanceToBottom < 4 ? settled + 1 : 0
        }
    }

    /// 今いちばん上にあるメモより前のメモがあれば、次の500件を読み足す。
    private func loadOlder() {
        guard isReady, anchorID == nil, newestFirst.count >= limit, let oldest = newestFirst.last else { return }
        let date = oldest.createdAt
        let olderCount = (try? context.fetchCount(FetchDescriptor<Note>(predicate: #Predicate { $0.createdAt < date }))) ?? 0
        guard olderCount > 0 else { return }
        anchorID = oldest.persistentModelID
        limit += ChatTimeline.pageSize
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
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .listRowSeparator(.hidden)
            .accessibilityHidden(true)
    }
}

/// 吹き出しを使わず、本文と追加時刻だけを並べる。
/// タスクにしたメモは左にオレンジのバーを付け、タスクを完了したらバーを灰色にして本文に取り消し線を引く。
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
        .listRowBackground(isTask ? TaskBar(color: isDone ? .doneTaskBar : .taskBar) : nil)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isDone ? "完了したタスク" : isTask ? "タスク" : "")
    }
}

/// メモの左に縦に付けるバー。上下を少し空けて、タスクのメモが続いても1件ずつ分かれて見えるようにする。
private struct TaskBar: View {
    let color: Color

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4)
                .padding(.vertical, 5)
                .padding(.leading, 6)
            Spacer(minLength: 0)
        }
        .background(Color(.systemBackground))
    }
}
