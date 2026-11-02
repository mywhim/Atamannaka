import SwiftUI

/// 画面下に常に出しておく入力欄。案内文は出さない。
struct ComposerBar: View {
    @Binding var text: String
    let onSend: (String) -> Void

    private var cleaned: String? { ChatTimeline.cleanedInput(text) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("", text: $text, axis: .vertical)
                .lineLimit(1...6)
                .font(.system(size: 17))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 18))
                .accessibilityLabel("メモ")

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
        .background(.bar)
    }
}
