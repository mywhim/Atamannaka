import SwiftUI
import UIKit

extension Color {
    /// チャットでタスクにしたメモの左に付けるバーの色。#FC9325 を不透明度 80% で使う。
    static let taskBar = Color(red: 0xfc / 255, green: 0x93 / 255, blue: 0x25 / 255).opacity(0.8)

    /// 完了したタスクのバーの色。taskBar と同じ明るさ(#FC9325 とほぼ同じ明度の #ABABAB)の灰色にして、色みだけを抜いている。
    static let doneTaskBar = Color(red: 0xab / 255, green: 0xab / 255, blue: 0xab / 255).opacity(0.8)

    /// ウィジェットで、読んでもらいたい1行に敷く色。蛍光ペンのような黄色にしている。
    static let widgetHighlight = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x5c / 255, green: 0x4f / 255, blue: 0x0a / 255, alpha: 1)
            : UIColor(red: 0xff / 255, green: 0xe6 / 255, blue: 0x80 / 255, alpha: 1)
    })
}
