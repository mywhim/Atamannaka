import Foundation
import SwiftData

/// チャットに書いた1件のメモ。書いた記録として残すため、タスクにしても本文は変えない。
@Model
final class Note {
    var text: String
    var createdAt: Date

    /// このメモから作ったタスク。タスクを削除すると nil に戻り、メモの左のバーも消える。
    @Relationship(deleteRule: .nullify, inverse: \TaskItem.sourceNote)
    var task: TaskItem?

    init(text: String, createdAt: Date = .now) {
        self.text = text
        self.createdAt = createdAt
    }
}

/// タスク。題名はメモの本文を写したもので、メモとは別に編集できる。
@Model
final class TaskItem {
    var title: String
    var createdAt: Date
    var completedAt: Date?
    var sourceNote: Note?
    /// タスク一覧で並べ替えた順番。小さいほど上。並べ替える前のタスクは 0 のままで、作成順に並ぶ。
    var sortIndex: Double = 0

    init(title: String, createdAt: Date = .now, completedAt: Date? = nil, sourceNote: Note? = nil, sortIndex: Double = 0) {
        self.title = title
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.sourceNote = sourceNote
        self.sortIndex = sortIndex
    }

    var isDone: Bool { completedAt != nil }
}

extension TaskItem {
    /// タスク一覧の並び。並べ替えた順番を優先し、同じなら作成順にする。
    static let listOrder = [SortDescriptor(\TaskItem.sortIndex), SortDescriptor(\TaskItem.createdAt)]

    /// 未完了のタスクを一覧と同じ順に取り出す。ウィジェットはこの順で上から表示する。
    static var openTasks: FetchDescriptor<TaskItem> {
        FetchDescriptor(predicate: #Predicate { $0.completedAt == nil }, sortBy: listOrder)
    }

    /// 新しいタスクを一覧のいちばん下に置くための順番。
    static func nextSortIndex(in context: ModelContext) -> Double {
        var descriptor = FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.sortIndex, order: .reverse)])
        descriptor.fetchLimit = 1
        let last = (try? context.fetch(descriptor).first?.sortIndex) ?? -1
        return last + 1
    }
}
