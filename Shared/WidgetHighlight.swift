import Foundation

/// ウィジェットで目立たせる1行を、時間ごとに入れ替えるための予定表。
///
/// ウィジェットは「見られた瞬間」にコードを動かせないため、先の時刻ごとの表示をまとめて作って渡しておく。
/// 予定の中の表示の切り替えは、ウィジェットの更新回数の上限に数えられない。
enum WidgetHighlight {
    /// 目立たせる行を入れ替える間隔。
    static let interval: TimeInterval = 15 * 60
    /// 一度に作っておく予定の数。使い切るとシステムが次の予定を求めてくる。
    static let entryCount = 24
    /// ウィジェットに並べる最大の件数。
    static let maxRows = 6

    /// 時刻ごとに目立たせる行の番号を決める。同じ行が続けて選ばれないようにする。
    /// - Returns: タスクがないときは nil の並び。
    static func indices<G: RandomNumberGenerator>(rowCount: Int, length: Int, using generator: inout G) -> [Int?] {
        guard rowCount > 0 else { return Array(repeating: nil, count: length) }
        var result: [Int?] = []
        var previous: Int?
        for _ in 0..<length {
            var next = Int.random(in: 0..<rowCount, using: &generator)
            if rowCount > 1, next == previous {
                next = (next + Int.random(in: 1..<rowCount, using: &generator)) % rowCount
            }
            result.append(next)
            previous = next
        }
        return result
    }
}
