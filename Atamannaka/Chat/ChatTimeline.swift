import Foundation

/// チャット画面に並べる行。メモのほかに、日付の見出しと間隔の線がある。
enum ChatRow<ID: Hashable>: Hashable {
    case day(Date)
    case gap(before: ID)
    case note(ID)
}

/// メモの並びから画面の行を組み立てる。画面から切り離して単体テストできるようにしている。
enum ChatTimeline {
    /// この間隔以上あいたメモの間に線を引く。
    static let gapInterval: TimeInterval = 5 * 60

    /// - Parameter entries: 作成時刻の古い順に並んだメモ。
    static func rows<ID: Hashable>(
        for entries: [(id: ID, createdAt: Date)],
        calendar: Calendar = .current
    ) -> [ChatRow<ID>] {
        var rows: [ChatRow<ID>] = []
        var previous: Date?
        for entry in entries {
            if let previous, entry.createdAt.timeIntervalSince(previous) >= gapInterval {
                rows.append(.gap(before: entry.id))
            }
            if previous.map({ !calendar.isDate($0, inSameDayAs: entry.createdAt) }) ?? true {
                rows.append(.day(calendar.startOfDay(for: entry.createdAt)))
            }
            rows.append(.note(entry.id))
            previous = entry.createdAt
        }
        return rows
    }

    /// 入力欄の文字を保存する形に整える。末尾の空白と改行だけ落とし、空なら nil。
    static func cleanedInput(_ text: String) -> String? {
        let trimmed = String(text.reversed().drop(while: \.isWhitespace).reversed())
        return trimmed.allSatisfy(\.isWhitespace) ? nil : trimmed
    }
}
