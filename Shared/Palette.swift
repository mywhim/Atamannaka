import SwiftUI
import UIKit

extension Color {
    /// チャットでタスクにしたメモの行に敷く色。
    /// 明るい画面では #FC9325。暗い画面では文字が白くなるので、白い文字が読める濃さまで落としている。
    static let marker = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0xa8 / 255, green: 0x5a / 255, blue: 0x0c / 255, alpha: 1)
            : UIColor(red: 0xfc / 255, green: 0x93 / 255, blue: 0x25 / 255, alpha: 1)
    })

    /// ウィジェットで、読んでもらいたい1行に敷く色。蛍光ペンのような黄色にしている。
    static let widgetHighlight = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x5c / 255, green: 0x4f / 255, blue: 0x0a / 255, alpha: 1)
            : UIColor(red: 0xff / 255, green: 0xe6 / 255, blue: 0x80 / 255, alpha: 1)
    })
}
