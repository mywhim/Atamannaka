import Foundation
import SwiftData

/// アプリとウィジェットが同じデータを読むための保存先。
enum SharedStore {
    static let appGroupID = "group.com.yukarii.atamannaka"

    /// App Group が使えない署名(無料アカウントで許可されなかった場合など)では nil になる。
    static var groupContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    /// App Group の領域に置けるかどうか。置けない場合はアプリ専用の領域に保存し、ウィジェットからは読めない。
    static var isShared: Bool { groupContainerURL != nil }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([Note.self, TaskItem.self])
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if let dir = groupContainerURL {
            config = ModelConfiguration(schema: schema, url: dir.appending(path: "Atamannaka.store"))
        } else {
            config = ModelConfiguration(schema: schema)
        }
        return try ModelContainer(for: schema, configurations: [config])
    }
}

enum AppLink {
    static let tasks = URL(string: "atamannaka://tasks")!
}
