import SwiftUI
import UIKit

extension Color {
    /// チャットでタスクにしたメモの行に敷く色。
    /// #FC9325 を半透明にして敷く。背景が透けるので、明るい画面でも暗い画面でも同じ色の指定で文字が読める。
    static let marker = Color(red: 0xfc / 255, green: 0x93 / 255, blue: 0x25 / 255).opacity(0.3)

    /// ウィジェットで、読んでもらいたい1行に敷く色。蛍光ペンのような黄色にしている。
    static let widgetHighlight = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x5c / 255, green: 0x4f / 255, blue: 0x0a / 255, alpha: 1)
            : UIColor(red: 0xff / 255, green: 0xe6 / 255, blue: 0x80 / 255, alpha: 1)
    })
}
