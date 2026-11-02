import SwiftUI

/// 画面下に一時的に出す「元に戻す」付きの通知。
struct UndoToast: View {
    let message: String
    let undo: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(message)
            Button("元に戻す", action: undo)
                .fontWeight(.bold)
                .underline()
        }
        .font(.subheadline)
        .foregroundStyle(Color(.systemBackground))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.label))
        .padding(.bottom, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
