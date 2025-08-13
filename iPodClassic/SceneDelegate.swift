import UIKit
import SwiftUI
import SpotifyiOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var spotifyManager: SpotifyManager = SpotifyManager()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // Create a RootView with the SpotifyManager as an environment object
        let rootView = RootView()
            .environmentObject(spotifyManager)

        let contentView = UIHostingController(rootView: rootView)
        window.rootViewController = contentView
        window.makeKeyAndVisible()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        print("SceneDelegate received URL: \(url.absoluteString)")
        
        // Handle authentication on main thread
        DispatchQueue.main.async {
            self.spotifyManager.handleAuthCallback(url: url)
            
            // Multiple layers of auto-play prevention after authentication
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.spotifyManager.pause()
                print("🔇 Defensive pause 0.5s after auth")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.spotifyManager.pause()
                print("🔇 Defensive pause 1.0s after auth")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.spotifyManager.pause()
                print("🔇 Defensive pause 1.5s after auth")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if self.spotifyManager.isPlaying {
                    self.spotifyManager.pause()
                    print("🔇 Final defensive pause 2.0s after auth")
                }
            }
        }
    }
}

// Define RootView to mirror iPodClassicApp's view hierarchy
struct RootView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @State private var isAuthenticated = false
    @State private var viewRefreshKey = UUID()

    var body: some View {
        Group {
            if isAuthenticated {
                ContentView()
                    .onAppear {
                        print("ContentView appeared, isLoggedIn: \(spotifyManager.isLoggedIn), isAuthenticated: \(isAuthenticated)")
                    }
            } else {
                LoginView()
                    .onAppear {
                        print("LoginView appeared, isLoggedIn: \(spotifyManager.isLoggedIn), isAuthenticated: \(isAuthenticated)")
                    }
            }
        }
        .id(viewRefreshKey)
        .onOpenURL { callbackURL in
            print("RootView received URL: \(callbackURL.absoluteString)")
            
            // Handle authentication and prevent auto-play
            spotifyManager.handleAuthCallback(url: callbackURL)
            
            // Multiple defensive pauses to ensure no automatic playback starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                spotifyManager.pause()
                print("🔇 RootView: Defensive pause 0.3s")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                spotifyManager.pause()
                print("🔇 RootView: Defensive pause 0.8s")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if spotifyManager.isPlaying {
                    spotifyManager.pause()
                    print("🔇 RootView: Final defensive pause if still playing")
                }
            }
        }
        .onChange(of: spotifyManager.isLoggedIn) { newValue in
            print("isLoggedIn changed to: \(newValue)")
            isAuthenticated = newValue
            viewRefreshKey = UUID() // Force view refresh
        }
    }
}
