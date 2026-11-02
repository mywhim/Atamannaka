import Foundation
import SwiftData
import Testing
@testable import Atamannaka

struct ChatTimelineTests {
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return c
    }()

    private func date(_ day: Int, _ hour: Int, _ minute: Int, _ second: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute, second: second))!
    }

    @Test func 最初のメモの前に日付見出しを出す() {
        let rows = ChatTimeline.rows(for: [(id: 1, createdAt: date(3, 9, 0))], calendar: calendar)
        #expect(rows == [.day(date(3, 0, 0)), .note(1)])
    }

    @Test func ちょうど5分あいたら線を引く() {
        let rows = ChatTimeline.rows(for: [
            (id: 1, createdAt: date(3, 9, 0)),
            (id: 2, createdAt: date(3, 9, 5)),
        ], calendar: calendar)
        #expect(rows == [.day(date(3, 0, 0)), .note(1), .gap(before: 2), .note(2)])
    }

    @Test func 間隔が5分未満なら線を引かない() {
        let rows = ChatTimeline.rows(for: [
            (id: 1, createdAt: date(3, 9, 0)),
            (id: 2, createdAt: date(3, 9, 4, 59)),
        ], calendar: calendar)
        #expect(rows == [.day(date(3, 0, 0)), .note(1), .note(2)])
    }

    @Test func 日付が変わったら線のあとに見出しを出す() {
        let rows = ChatTimeline.rows(for: [
            (id: 1, createdAt: date(3, 23, 58)),
            (id: 2, createdAt: date(4, 0, 1)),
            (id: 3, createdAt: date(4, 9, 0)),
        ], calendar: calendar)
        #expect(rows == [
            .day(date(3, 0, 0)), .note(1),
            .day(date(4, 0, 0)), .note(2),
            .gap(before: 3), .note(3),
        ])
    }

    @Test func 入力は末尾の空白だけを落とす() {
        #expect(ChatTimeline.cleanedInput("  買い物\n\n ") == "  買い物")
        #expect(ChatTimeline.cleanedInput("1行目\n2行目") == "1行目\n2行目")
        #expect(ChatTimeline.cleanedInput(" \n　") == nil)
    }
}

@MainActor
struct TaskModelTests {
    @Test func タスクを削除するとメモのハイライトが外れる() throws {
        let container = try SharedStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let note = Note(text: "歯医者の予約を取る")
        context.insert(note)
        let task = TaskItem(title: note.text, sourceNote: note)
        context.insert(task)
        try context.save()
        #expect(note.task === task)

        context.delete(task)
        try context.save()
        #expect(note.task == nil)
        #expect(try context.fetchCount(FetchDescriptor<Note>()) == 1)
    }

    @Test func タスクの題名を変えてもメモは変わらない() throws {
        let container = try SharedStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let note = Note(text: "スライド")
        context.insert(note)
        let task = TaskItem(title: note.text, sourceNote: note)
        context.insert(task)
        task.title = "ゼミの発表スライドを作る"
        try context.save()
        #expect(note.text == "スライド")
    }

    @Test func 未完了のタスクだけを古い順に取り出す() throws {
        let container = try SharedStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let now = Date.now
        context.insert(TaskItem(title: "新しい", createdAt: now))
        context.insert(TaskItem(title: "古い", createdAt: now.addingTimeInterval(-60)))
        context.insert(TaskItem(title: "完了", createdAt: now.addingTimeInterval(-120), completedAt: now))
        try context.save()
        #expect(try context.fetch(TaskItem.openTasks).map(\.title) == ["古い", "新しい"])
    }
}
