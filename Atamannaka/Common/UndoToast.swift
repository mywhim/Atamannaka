import SwiftUI

/// 「元に戻す」で取り消せる直前の操作。
struct PendingUndo: Identifiable {
    let id = UUID()
    let message: String
    let undo: @MainActor () -> Void
}

extension View {
    /// 画面下に「元に戻す」を一定時間だけ出す。動きで気が散らないよう、出入りは短いフェードだけにする。
    func undoToast(_ pending: Binding<PendingUndo?>) -> some View {
        overlay(alignment: .bottom) {
            if let current = pending.wrappedValue {
                UndoToast(message: current.message) {
                    current.undo()
                    pending.wrappedValue = nil
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: pending.wrappedValue?.id)
        .task(id: pending.wrappedValue?.id) {
            guard let id = pending.wrappedValue?.id else { return }
            try? await Task.sleep(for: .seconds(6))
            if pending.wrappedValue?.id == id { pending.wrappedValue = nil }
        }
    }
}

private struct UndoToast: View {
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
        .foregroundStyle(.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGray5), in: .rect(cornerRadius: 10))
        .padding(.bottom, 12)
    }
}
