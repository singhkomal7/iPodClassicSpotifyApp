import SwiftUI
import Combine

// Navigation state manager for the iPod interface
class iPodNavigationState: ObservableObject {
    @Published var currentScreen: iPodScreen = .mainMenu
    @Published var navigationStack: [iPodScreen] = [.mainMenu]
    @Published var selectedIndex = 0
    @Published var selectedPlaylistId: String?
    @Published var selectedArtistId: String?
    @Published var selectedAlbumId: String?
    
    func navigateTo(_ screen: iPodScreen) {
        print("🧭 Navigating from \(currentScreen) to: \(screen)")
        print("📍 Navigation stack before: \(navigationStack.map { "\($0)" })")
        currentScreen = screen
        navigationStack.append(screen)
        selectedIndex = 0 // Reset selection when navigating
        print("📍 Navigation stack after: \(navigationStack.map { "\($0)" })")
    }
    
    func navigateBack() {
        guard navigationStack.count > 1 else { 
            print("🚫 Cannot navigate back - already at root level")
            return 
        }
        
        let previousScreen = currentScreen
        navigationStack.removeLast()
        currentScreen = navigationStack.last ?? .mainMenu
        selectedIndex = 0
        print("🔙 Navigated back from \(previousScreen) to: \(currentScreen)")
        print("📍 Navigation stack after back: \(navigationStack.map { "\($0)" })")
    }
    
    func resetToMainMenu() {
        currentScreen = .mainMenu
        navigationStack = [.mainMenu]
        selectedIndex = 0
        selectedPlaylistId = nil
        selectedArtistId = nil
        selectedAlbumId = nil
        print("🏠 Reset to main menu")
    }
    
    var canGoBack: Bool {
        return navigationStack.count > 1
    }
    
    var currentTitle: String {
        switch currentScreen {
        case .mainMenu:
            return "iPod"
        case .playlists:
            return "Playlists"
        case .playlistTracks:
            return "Tracks"
        case .artists:
            return "Artists"
        case .artistTracks:
            return "Tracks"
        case .albums:
            return "Albums"
        case .albumTracks:
            return "Tracks"
        case .songs:
            return "Songs"
        case .nowPlaying:
            return "Now Playing"
        }
    }
}

enum iPodScreen: Equatable {
    case mainMenu
    case playlists
    case playlistTracks(String) // playlist ID
    case artists
    case artistTracks(String) // artist ID
    case albums
    case albumTracks(String) // album ID
    case songs
    case nowPlaying
}
