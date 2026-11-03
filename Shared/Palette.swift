import SwiftUI
import UIKit

extension Color {
    /// タスクにしたメモの行と、ウィジェットで目立たせる1行に敷く色。
    /// 文字を読みやすいよう、明るい画面では淡いオレンジ、暗い画面では落ち着いた茶色寄りにしている。
    static let marker = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x4d / 255, green: 0x30 / 255, blue: 0x12 / 255, alpha: 1)
            : UIColor(red: 0xff / 255, green: 0xe2 / 255, blue: 0xc2 / 255, alpha: 1)
    })
}
