import SwiftUI

@main
struct ConflictMonitorApp: App {
    @StateObject private var store = EventStore()

    var body: some Scene {
        MenuBarExtra("Conflict Monitor", systemImage: "dot.radiowaves.left.and.right") {
            EventsMenuView(store: store)
                .frame(width: 420)
        }
        .menuBarExtraStyle(.window)
    }
}

