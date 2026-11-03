import SwiftUI
import UIKit

extension Color {
    /// チャットでタスクにしたメモの行に敷く色。
    /// 文字を読みやすいよう、明るい画面では赤みのある淡いオレンジ、暗い画面では落ち着いた赤茶にしている。
    static let marker = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x5a / 255, green: 0x2b / 255, blue: 0x17 / 255, alpha: 1)
            : UIColor(red: 0xff / 255, green: 0xd4 / 255, blue: 0xbe / 255, alpha: 1)
    })

    /// ウィジェットで、読んでもらいたい1行に敷く色。蛍光ペンのような黄色にしている。
    static let widgetHighlight = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x5c / 255, green: 0x4f / 255, blue: 0x0a / 255, alpha: 1)
            : UIColor(red: 0xff / 255, green: 0xe6 / 255, blue: 0x80 / 255, alpha: 1)
    })
}
