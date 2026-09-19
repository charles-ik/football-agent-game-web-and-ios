import SwiftUI

@main
struct FootballAgentApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(url: AppConfiguration.gameURL)
        }
    }
}

enum AppConfiguration {
    static let gameURL: URL = {
        let info = Bundle.main.infoDictionary ?? [:]
        var components = URLComponents()
        components.scheme = info["FootballAgentScheme"] as? String ?? "http"
        components.host = info["FootballAgentHost"] as? String ?? "MacBook-Pro.local"
        components.port = Int(info["FootballAgentPort"] as? String ?? "3000")
        return components.url!
    }()
}
