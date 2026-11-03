import Foundation
import SwiftData

/// 削除やタスク解除を元に戻すために控えておく内容。削除した TaskItem 自体は使えなくなるので値で持つ。
struct DeletedTask {
    let title: String
    let createdAt: Date
    let completedAt: Date?
    let sortIndex: Double
    let sourceNote: Note?

    init(_ task: TaskItem) {
        title = task.title
        createdAt = task.createdAt
        completedAt = task.completedAt
        sortIndex = task.sortIndex
        sourceNote = task.sourceNote
    }

    /// タスクを作り直す。元のメモが残っていて、まだ別のタスクになっていなければつなぎ直す。
    @discardableResult
    func restore(into context: ModelContext) -> TaskItem {
        let note = sourceNote.flatMap { !$0.isDeleted && $0.task == nil ? $0 : nil }
        let task = TaskItem(title: title, createdAt: createdAt, completedAt: completedAt, sourceNote: note, sortIndex: sortIndex)
        context.insert(task)
        return task
    }
}
