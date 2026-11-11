import SwiftUI

/// 画面下に常に出しておく入力欄。案内文は出さない。
struct ComposerBar: View {
    @Binding var text: String
    /// 値が変わると、入力欄にカーソルを入れてキーボードを出す。
    var focusRequest: UUID?
    let onSend: (String) -> Void
    @FocusState private var isFocused: Bool

    private var cleaned: String? { ChatTimeline.cleanedInput(text) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("", text: $text, axis: .vertical)
                .lineLimit(1...6)
                .font(.system(size: 17))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                // 枠線を付けて、下の帯の灰色から入力欄だけが浮いて見えるようにする
                .background(Color(.systemBackground), in: .rect(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(.systemGray3), lineWidth: 1))
                .accessibilityLabel("メモ")
                .focused($isFocused)

            Button {
                guard let cleaned else { return }
                onSend(cleaned)
                text = ""
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color(.label)))
            }
            .disabled(cleaned == nil)
            .opacity(cleaned == nil ? 0.3 : 1)
            .accessibilityLabel("追加")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .overlay(alignment: .top) { Divider() }
        .task(id: focusRequest) {
            guard focusRequest != nil else { return }
            // 起動直後は画面の準備が終わるまでカーソルを入れられないので、少し待つ
            try? await Task.sleep(for: .milliseconds(300))
            isFocused = true
        }
    }
}
