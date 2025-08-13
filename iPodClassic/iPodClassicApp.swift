import SwiftUI

@main
struct iPodClassicApp: App {
    @StateObject private var spotifyManager = SpotifyManager()
    
    init() {
        print("🎵 iPodClassicApp init called")
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if spotifyManager.isLoggedIn {
                    ContentView()
                        .onAppear {
                            print("🌵 ContentView appeared, isLoggedIn: \(spotifyManager.isLoggedIn)")
                        }
                } else {
                    LoginView()
                        .onAppear {
                            print("🔐 LoginView appeared, isLoggedIn: \(spotifyManager.isLoggedIn)")
                        }
                }
            }
            .environmentObject(spotifyManager)
            .onAppear {
                print("🖼️ Main view hierarchy appeared")
            }
            .onOpenURL { callbackURL in
                print("📫 App received URL: \(callbackURL.absoluteString)")
                spotifyManager.handleAuthCallback(url: callbackURL)
            }
        }
    }
}
