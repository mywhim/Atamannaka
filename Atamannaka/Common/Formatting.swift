import Foundation

extension Date {
    /// 「14:05」の形。端末の言語設定によらず24時間表記にする。
    var clockText: String {
        formatted(.verbatim(
            "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)",
            timeZone: .current,
            calendar: .current
        ))
    }

    /// 「2026年11月3日(火)」の形。
    var dayText: String {
        formatted(.dateTime.year().month().day().weekday(.abbreviated).locale(Locale(identifier: "ja_JP")))
    }
}
