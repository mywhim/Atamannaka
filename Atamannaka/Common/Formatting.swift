import Foundation
import SwiftUI
import UIKit

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

extension Color {
    /// タスクにしたメモに引く蛍光ペン風の色。Web 版の黄色の色調に合わせている。
    static let marker = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x5c / 255, green: 0x4f / 255, blue: 0x0a / 255, alpha: 1)
            : UIColor(red: 0xff / 255, green: 0xe6 / 255, blue: 0x80 / 255, alpha: 1)
    })
}
