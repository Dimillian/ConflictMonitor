import SwiftUI

@main
struct ConflictMonitorApp: App {
    @State private var store = EventStore()

    var body: some Scene {
        MenuBarExtra("Conflict Monitor", systemImage: "dot.radiowaves.left.and.right") {
            EventsMenuView(store: store)
                .frame(width: 460, height: 780)
        }
        .menuBarExtraStyle(.window)
    }
}
