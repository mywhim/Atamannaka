import SwiftData
import SwiftUI

/// タスクの題名を直す。元のメモは書いた記録として残すため、ここでは変えない。
struct TaskEditSheet: View {
    let task: TaskItem
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @FocusState private var focused: Bool

    init(task: TaskItem) {
        self.task = task
        _text = State(initialValue: task.title)
    }

    private var cleaned: String? { ChatTimeline.cleanedInput(text) }

    var body: some View {
        NavigationStack {
            TextField("", text: $text, axis: .vertical)
                .lineLimit(3...12)
                .font(.system(size: 17))
                .focused($focused)
                .accessibilityLabel("タスク")
                .padding(16)
                .frame(maxHeight: .infinity, alignment: .top)
                .navigationTitle("タスクを編集")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            guard let cleaned else { return }
                            task.title = cleaned
                            context.commit()
                            dismiss()
                        }
                        .disabled(cleaned == nil)
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .onAppear { focused = true }
    }
}
