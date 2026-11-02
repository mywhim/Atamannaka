import SwiftData
import WidgetKit

extension ModelContext {
    /// 変更をすぐ保存する。ウィジェットは別プロセスでファイルを読むので、自動保存を待たずに書き込んでから更新を頼む。
    func commit(reloadingWidget: Bool = true) {
        do {
            try save()
        } catch {
            assertionFailure("保存に失敗しました: \(error)")
        }
        if reloadingWidget {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
