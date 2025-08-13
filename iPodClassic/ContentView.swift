import SwiftUI

struct ContentView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    
    var body: some View {
        iPodMenuView()
            .environmentObject(spotifyManager)
            .onAppear {
                print("🌵 ContentView appeared, isLoggedIn: \(spotifyManager.isLoggedIn)")
                // Data fetching is now handled by the navigation system in iPodMenuView
            }
    }
}
