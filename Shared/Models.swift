import Foundation
import SwiftData

/// チャットに書いた1件のメモ。書いた記録として残すため、タスクにしても本文は変えない。
@Model
final class Note {
    var text: String
    var createdAt: Date

    /// このメモから作ったタスク。タスクを削除すると nil に戻り、ハイライトも消える。
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

    init(title: String, createdAt: Date = .now, completedAt: Date? = nil, sourceNote: Note? = nil) {
        self.title = title
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.sourceNote = sourceNote
    }

    var isDone: Bool { completedAt != nil }
}

extension TaskItem {
    /// 未完了のタスクを古い順に並べる。タスク一覧とウィジェットで同じ並びにするため共通にしている。
    static var openTasks: FetchDescriptor<TaskItem> {
        FetchDescriptor(
            predicate: #Predicate { $0.completedAt == nil },
            sortBy: [SortDescriptor(\.createdAt)]
        )
    }
}
