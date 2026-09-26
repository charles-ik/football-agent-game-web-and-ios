import SwiftUI

@main
struct FootballAgentApp: App {
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(store)
        }
    }
}
