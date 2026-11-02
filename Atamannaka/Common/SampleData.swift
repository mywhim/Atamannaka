#if DEBUG
import Foundation
import SwiftData

/// シミュレーターでの確認とスクリーンショット用。起動引数 -seedSample を付けたときだけ使う。
enum SampleData {
    @MainActor
    static func insertIfEmpty(into context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Note>())) ?? 0
        guard count == 0 else { return }

        let base = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        func at(_ minutes: Int) -> Date { base.addingTimeInterval(TimeInterval(minutes * 60)) }

        let notes = [
            Note(text: "朝、駅までの道で金木犀の匂いがした", createdAt: at(0)),
            Note(text: "ゼミの発表スライド、結論を先に書く", createdAt: at(2)),
            Note(text: "歯医者の予約を取る", createdAt: at(3)),
            Note(text: "昼ごはん何にしよう", createdAt: at(240)),
            Note(text: "ES の自己 PR、具体例をひとつに絞る", createdAt: at(1440)),
            Note(text: "牛乳と卵を買う", createdAt: at(1441)),
        ]
        notes.forEach(context.insert)

        context.insert(TaskItem(title: notes[1].text, createdAt: at(10), sourceNote: notes[1]))
        context.insert(TaskItem(title: notes[2].text, createdAt: at(11), sourceNote: notes[2]))
        context.insert(TaskItem(title: notes[5].text, createdAt: at(1442), completedAt: at(1500), sourceNote: notes[5]))
        context.commit()
    }
}
#endif
