import SwiftUI

struct iPodMenuView: View {
    @StateObject private var navigationState = iPodNavigationState()
    @EnvironmentObject var spotifyManager: SpotifyManager
    
    let menuItems = [
        MenuItem(title: "Playlists", icon: "music.note.list", action: .playlists),
        MenuItem(title: "Artists", icon: "person.fill", action: .artists),
        MenuItem(title: "Albums", icon: "opticaldisc", action: .albums),
        MenuItem(title: "Songs", icon: "music.note", action: .songs),
        MenuItem(title: "Now Playing", icon: "music.note.tv", action: .nowPlaying)
    ]
    
    var body: some View {
        iPodLayoutView(
            content: {
                currentScreenContent
            },
            onMenuPress: {
                if navigationState.canGoBack {
                    print("🔙 Menu pressed - navigating back from \(navigationState.currentScreen) to previous screen")
                    navigationState.navigateBack()
                } else {
                    print("🔙 Menu pressed - already at main menu, no action taken")
                    // Optional: Could add haptic feedback or visual indication
                }
            },
            onPlayPausePress: {
                handlePlayPausePress()
            },
            onPreviousPress: {
                handlePreviousPress()
            },
            onNextPress: {
                handleNextPress()
            },
            onCenterPress: {
                handleCenterPress()
            },
            onScrollUp: {
                if navigationState.selectedIndex > 0 {
                    navigationState.selectedIndex -= 1
                    HapticManager.shared.selectionFeedback()
                    logCurrentSelection()
                }
            },
            onScrollDown: {
                let maxIndex = getMaxIndexForCurrentScreen()
                if navigationState.selectedIndex < maxIndex {
                    navigationState.selectedIndex += 1
                    HapticManager.shared.selectionFeedback()
                    logCurrentSelection()
                }
            },
            onScrollLeft: {
                print("⬅️ Scroll left")
            },
            onScrollRight: {
                print("➡️ Scroll right")
            },
            onVolumeUp: {
                if navigationState.currentScreen == .nowPlaying {
                    // Enable volume controls in Now Playing view
                    print("🔊⬆️ Volume up in Now Playing")
                    spotifyManager.increaseVolume()
                } else {
                    // Volume controls disabled on other screens to avoid interference with scrolling
                    print("🔊 Volume controls only available in Now Playing view")
                }
            },
            onVolumeDown: {
                if navigationState.currentScreen == .nowPlaying {
                    // Enable volume controls in Now Playing view
                    print("🔊⬇️ Volume down in Now Playing")
                    spotifyManager.decreaseVolume()
                } else {
                    // Volume controls disabled on other screens to avoid interference with scrolling
                    print("🔊 Volume controls only available in Now Playing view")
                }
            }
        )
        .environmentObject(navigationState)
        .onAppear {
            // Load initial data when view appears
            loadDataForCurrentScreen()
        }
        .onChange(of: navigationState.currentScreen) { _ in
            // Load data when screen changes
            loadDataForCurrentScreen()
        }
        .onChange(of: spotifyManager.showNowPlaying) { shouldShow in
            if shouldShow {
                navigationState.navigateTo(.nowPlaying)
                spotifyManager.showNowPlaying = false // Reset the flag
            }
        }
    }
    
    @ViewBuilder
    private var currentScreenContent: some View {
        switch navigationState.currentScreen {
        case .mainMenu:
            mainMenuContent
        case .playlists:
            playlistsContent
        case .playlistTracks(let playlistId):
            playlistTracksContent(playlistId: playlistId)
        case .artists:
            artistsContent
        case .artistTracks(let artistId):
            artistTracksContent(artistId: artistId)
        case .albums:
            albumsContent
        case .albumTracks(let albumId):
            albumTracksContent(albumId: albumId)
        case .songs:
            songsContent
        case .nowPlaying:
            NowPlayingView()
                .environmentObject(spotifyManager)
                .environmentObject(navigationState)
        }
    }
    
    private var mainMenuContent: some View {
        VStack(spacing: 0) {
            iPodScreenHeader(title: navigationState.currentTitle)
            
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(menuItems.enumerated()), id: \.offset) { index, item in
                        iPodListItem(
                            icon: item.icon,
                            title: item.title,
                            isSelected: index == navigationState.selectedIndex
                        )
                        .id(index)
                        
                        if index < menuItems.count - 1 {
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .padding(.leading, 50)
                        }
                    }
                    Spacer()
                }
                .onChange(of: navigationState.selectedIndex) { newIndex in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
            .padding(.top, 10)
        }
    }
    
    private var playlistsContent: some View {
        VStack(spacing: 0) {
            iPodScreenHeader(
                title: navigationState.currentTitle,
                subtitle: "\(spotifyManager.playlists.count) playlists"
            )
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if spotifyManager.playlists.isEmpty {
                            VStack(spacing: 8) {
                                Text("No Playlists")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Text("Create playlists in Spotify")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                        } else {
                            ForEach(Array(spotifyManager.playlists.enumerated()), id: \.offset) { index, playlist in
                                enhancedPlaylistItem(
                                    playlist: playlist,
                                    index: index,
                                    isSelected: index == navigationState.selectedIndex
                                )
                                .id(index)
                                
                                if index < spotifyManager.playlists.count - 1 {
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
                                        .padding(.leading, 40)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxHeight: 160) // Constrain scroll area height
                .clipped()
                .onChange(of: navigationState.selectedIndex) { newIndex in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    private func playlistTracksContent(playlistId: String) -> some View {
        VStack(spacing: 0) {
            iPodScreenHeader(
                title: navigationState.currentTitle, 
                subtitle: "\(spotifyManager.tracks.count) songs"
            )
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if spotifyManager.tracks.isEmpty {
                            VStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading tracks...")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                        } else {
                            ForEach(Array(spotifyManager.tracks.enumerated()), id: \.offset) { index, track in
                                enhancedTrackItem(
                                    track: track,
                                    index: index,
                                    isSelected: index == navigationState.selectedIndex,
                                    isPlaying: spotifyManager.isPlaying && index == navigationState.selectedIndex
                                )
                                .id(index)
                                
                                if index < spotifyManager.tracks.count - 1 {
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
                                        .padding(.leading, 40)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxHeight: 160) // Constrain scroll area height
                .clipped()
                .onChange(of: navigationState.selectedIndex) { newIndex in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var artistsContent: some View {
        VStack(spacing: 0) {
            iPodScreenHeader(
                title: navigationState.currentTitle,
                subtitle: "\(spotifyManager.artists.count) artists"
            )
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if spotifyManager.artists.isEmpty {
                            VStack(spacing: 8) {
                                Text("No Artists")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Text("Listen to music to see your top artists")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                        } else {
                            ForEach(Array(spotifyManager.artists.enumerated()), id: \.offset) { index, artist in
                                enhancedArtistItem(
                                    artist: artist,
                                    index: index,
                                    isSelected: index == navigationState.selectedIndex
                                )
                                .id(index)
                                
                                if index < spotifyManager.artists.count - 1 {
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
                                        .padding(.leading, 40)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxHeight: 160)
                .clipped()
                .onChange(of: navigationState.selectedIndex) { newIndex in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    private func artistTracksContent(artistId: String) -> some View {
        VStack {
            Text("Artist Tracks - Coming Soon")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var albumsContent: some View {
        VStack(spacing: 0) {
            iPodScreenHeader(
                title: navigationState.currentTitle,
                subtitle: "\(spotifyManager.albums.count) albums"
            )
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if spotifyManager.albums.isEmpty {
                            VStack(spacing: 8) {
                                Text("No Albums")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Text("Listen to more music to see your albums")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                        } else {
                            ForEach(Array(spotifyManager.albums.enumerated()), id: \.offset) { index, album in
                                enhancedAlbumItem(
                                    album: album,
                                    index: index,
                                    isSelected: index == navigationState.selectedIndex
                                )
                                .id(index)
                                
                                if index < spotifyManager.albums.count - 1 {
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
                                        .padding(.leading, 40)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxHeight: 160)
                .clipped()
                .onChange(of: navigationState.selectedIndex) { newIndex in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    private func albumTracksContent(albumId: String) -> some View {
        VStack {
            Text("Album Tracks - Coming Soon")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var songsContent: some View {
        VStack(spacing: 0) {
            iPodScreenHeader(
                title: navigationState.currentTitle,
                subtitle: "\(spotifyManager.tracks.count) songs"
            )
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if spotifyManager.tracks.isEmpty {
                            VStack(spacing: 8) {
                                Text("No Songs")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Text("Save songs to your library in Spotify")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                        } else {
                            ForEach(Array(spotifyManager.tracks.enumerated()), id: \.offset) { index, track in
                                enhancedTrackItem(
                                    track: track,
                                    index: index,
                                    isSelected: index == navigationState.selectedIndex,
                                    isPlaying: spotifyManager.isPlaying && track.uri == spotifyManager.currentTrackURI
                                )
                                .id(index)
                                
                                if index < spotifyManager.tracks.count - 1 {
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
                                        .padding(.leading, 40)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxHeight: 160)
                .clipped()
                .onChange(of: navigationState.selectedIndex) { newIndex in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    
    // MARK: - Enhanced UI Components
    
    private func enhancedTrackItem(
        track: Track,
        index: Int,
        isSelected: Bool,
        isPlaying: Bool
    ) -> some View {
        HStack(spacing: 12) {
            // Icon with visual feedback
            Image(systemName: isPlaying ? "speaker.wave.2.fill" : "music.note")
                .foregroundColor(isSelected ? .white : (isPlaying ? .blue : .black))
                .frame(width: 16, height: 16)
                .font(.system(size: 12, weight: .medium))
            
            // Track information with proper text handling
            VStack(alignment: .leading, spacing: 2) {
                // Track name with truncation and scaling
                Text(track.name)
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .foregroundColor(isSelected ? .white : .black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .allowsTightening(true)
                    .truncationMode(.tail)
                
                // Artist name with smaller font
                Text(track.artists.first?.name ?? "Unknown Artist")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .truncationMode(.tail)
            }
            
            Spacer(minLength: 8)
            
            // Selection indicator
            if isSelected {
                HStack(spacing: 4) {
                    if isPlaying {
                        Image(systemName: "waveform")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 36) // Fixed height for consistent spacing
        .background(trackItemBackground(isSelected: isSelected, isPlaying: isPlaying))
        .cornerRadius(4)
    }
    
    private func trackItemBackground(isSelected: Bool, isPlaying: Bool) -> some View {
        Group {
            if isSelected {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.9),
                        Color.blue.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else if isPlaying {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.blue.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                Color.clear
            }
        }
    }
    
    private func enhancedPlaylistItem(
        playlist: Playlist,
        index: Int,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: 12) {
            // Playlist icon
            Image(systemName: "music.note.list")
                .foregroundColor(isSelected ? .white : .black)
                .frame(width: 16, height: 16)
                .font(.system(size: 12, weight: .medium))
            
            // Playlist information with proper text handling
            VStack(alignment: .leading, spacing: 2) {
                // Playlist name with truncation and scaling
                Text(playlist.name)
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .foregroundColor(isSelected ? .white : .black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .allowsTightening(true)
                    .truncationMode(.tail)
                
                // Track count with smaller font
                if let trackCount = playlist.trackCount {
                    Text("\(trackCount) songs")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .allowsTightening(true)
                        .truncationMode(.tail)
                }
            }
            
            Spacer(minLength: 8)
            
            // Selection indicator
            if isSelected {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 36) // Fixed height for consistent spacing
        .background(playlistItemBackground(isSelected: isSelected))
        .cornerRadius(4)
    }
    
    private func playlistItemBackground(isSelected: Bool) -> some View {
        Group {
            if isSelected {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.9),
                        Color.blue.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                Color.clear
            }
        }
    }
    
    private func enhancedArtistItem(
        artist: Artist,
        index: Int,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: 12) {
            // Artist icon
            Image(systemName: "person.fill")
                .foregroundColor(isSelected ? .white : .black)
                .frame(width: 16, height: 16)
                .font(.system(size: 12, weight: .medium))
            
            // Artist information
            VStack(alignment: .leading, spacing: 2) {
                // Artist name with truncation and scaling
                Text(artist.name)
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .foregroundColor(isSelected ? .white : .black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .allowsTightening(true)
                    .truncationMode(.tail)
                
                // Artist label
                Text("Artist")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 8)
            
            // Selection indicator
            if isSelected {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 36)
        .background(artistItemBackground(isSelected: isSelected))
        .cornerRadius(4)
    }
    
    private func artistItemBackground(isSelected: Bool) -> some View {
        Group {
            if isSelected {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.9),
                        Color.blue.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                Color.clear
            }
        }
    }
    
    private func enhancedAlbumItem(
        album: Album,
        index: Int,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: 12) {
            // Album icon
            Image(systemName: "opticaldisc")
                .foregroundColor(isSelected ? .white : .black)
                .frame(width: 16, height: 16)
                .font(.system(size: 12, weight: .medium))
            
            // Album information
            VStack(alignment: .leading, spacing: 2) {
                // Album name with truncation and scaling
                Text(album.name)
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .foregroundColor(isSelected ? .white : .black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .allowsTightening(true)
                    .truncationMode(.tail)
                
                // Artist name
                Text(album.artists.first?.name ?? "Unknown Artist")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .truncationMode(.tail)
            }
            
            Spacer(minLength: 8)
            
            // Selection indicator
            if isSelected {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 36)
        .background(albumItemBackground(isSelected: isSelected))
        .cornerRadius(4)
    }
    
    private func albumItemBackground(isSelected: Bool) -> some View {
        Group {
            if isSelected {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.9),
                        Color.blue.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                Color.clear
            }
        }
    }
    
    // MARK: - Music Control Functions
    
    private func handlePlayPausePress() {
        print("⏯️ Play/Pause button pressed")
        
        // Only allow play/pause control in Now Playing screen
        switch navigationState.currentScreen {
        case .nowPlaying:
            // In Now Playing screen - direct play/pause control
            if spotifyManager.isPlaying {
                print("⏸️ Pausing playback from Now Playing")
                spotifyManager.pause()
            } else {
                print("▶️ Resuming playback from Now Playing")
                spotifyManager.resume()
            }
            
        default:
            // In other screens - play/pause controls are disabled
            print("🚫 Play/Pause controls only available in Now Playing screen")
        }
    }
    
    private func handleNextPress() {
        print("⏭️ Next button pressed")
        
        // Only allow next/previous controls in Now Playing screen
        switch navigationState.currentScreen {
        case .nowPlaying:
            // In Now Playing screen - use Spotify's native next function
            print("⏭️ Skipping to next track via Spotify")
            spotifyManager.skipToNext()
            
        default:
            // In other screens - next/previous controls are disabled
            print("🚫 Next/Previous controls only available in Now Playing screen")
        }
    }
    
    private func handlePreviousPress() {
        print("⏮️ Previous button pressed")
        
        // Only allow next/previous controls in Now Playing screen
        switch navigationState.currentScreen {
        case .nowPlaying:
            // In Now Playing screen - use Spotify's native previous function
            print("⏮️ Skipping to previous track via Spotify")
            spotifyManager.skipToPrevious()
            
        default:
            // In other screens - next/previous controls are disabled
            print("🚫 Next/Previous controls only available in Now Playing screen")
        }
    }
    
    // MARK: - Volume Control Functions
    
    private func handleVolumeUp() {
        spotifyManager.increaseVolume()
    }
    
    private func handleVolumeDown() {
        spotifyManager.decreaseVolume()
    }
    
    // MARK: - Helper Functions
    
    private func handleCenterPress() {
        switch navigationState.currentScreen {
        case .mainMenu:
            let selectedItem = menuItems[navigationState.selectedIndex]
            print("✅ Center pressed - selecting: \(selectedItem.title)")
            
            switch selectedItem.action {
            case .playlists:
                navigationState.navigateTo(.playlists)
            case .artists:
                navigationState.navigateTo(.artists)
            case .albums:
                navigationState.navigateTo(.albums)
            case .songs:
                navigationState.navigateTo(.songs)
            case .nowPlaying:
                if spotifyManager.isPlaying || !spotifyManager.currentTrackURI.isEmpty {
                    navigationState.navigateTo(.nowPlaying)
                } else {
                    print("⚠️ No track currently playing or available")
                }
            }
            
        case .playlists:
            guard !spotifyManager.playlists.isEmpty else { return }
            let selectedPlaylist = spotifyManager.playlists[navigationState.selectedIndex]
            print("✅ Center pressed - selecting playlist: \(selectedPlaylist.name)")
            navigationState.selectedPlaylistId = selectedPlaylist.id
            navigationState.navigateTo(.playlistTracks(selectedPlaylist.id))
            
        case .playlistTracks(let playlistId):
            guard !spotifyManager.tracks.isEmpty else { return }
            let selectedTrack = spotifyManager.tracks[navigationState.selectedIndex]
            print("✅ Center pressed - playing track: \(selectedTrack.name)")
            // Set playlist context before playing
            spotifyManager.setPlaylistContext(playlistId: playlistId, trackIndex: navigationState.selectedIndex)
            spotifyManager.playTrack(uri: selectedTrack.uri)
            
        case .songs:
            guard !spotifyManager.tracks.isEmpty else { return }
            let selectedTrack = spotifyManager.tracks[navigationState.selectedIndex]
            print("✅ Center pressed - playing liked song: \(selectedTrack.name)")
            spotifyManager.playTrack(uri: selectedTrack.uri)
            
        default:
            print("✅ Center pressed - no action for current screen")
        }
    }
    
    private func logCurrentSelection() {
        switch navigationState.currentScreen {
        case .mainMenu:
            if navigationState.selectedIndex < menuItems.count {
                print("📍 Selected: \(menuItems[navigationState.selectedIndex].title)")
            }
        case .playlists:
            if navigationState.selectedIndex < spotifyManager.playlists.count {
                print("📍 Selected playlist: \(spotifyManager.playlists[navigationState.selectedIndex].name)")
            }
        case .playlistTracks(_):
            if navigationState.selectedIndex < spotifyManager.tracks.count {
                print("📍 Selected track: \(spotifyManager.tracks[navigationState.selectedIndex].name)")
            }
        default:
            print("📍 Selection updated")
        }
    }
    
    private func getMaxIndexForCurrentScreen() -> Int {
        switch navigationState.currentScreen {
        case .mainMenu:
            return menuItems.count - 1
        case .playlists:
            return max(0, spotifyManager.playlists.count - 1)
        case .playlistTracks(_):
            return max(0, spotifyManager.tracks.count - 1)
        case .artists:
            return max(0, spotifyManager.artists.count - 1)
        case .albums:
            return max(0, spotifyManager.albums.count - 1)
        case .songs:
            return max(0, spotifyManager.tracks.count - 1)
        default:
            return 0
        }
    }
    
    private func loadDataForCurrentScreen() {
        guard spotifyManager.isLoggedIn else {
            print("⚠️ Cannot load data - not logged in")
            return
        }
        
        switch navigationState.currentScreen {
        case .playlists:
            print("📊 Loading playlists data...")
            Task {
                await spotifyManager.fetchPlaylists()
                print("📊 Playlists loaded: \(spotifyManager.playlists.count) items")
            }
        case .playlistTracks(let playlistId):
            print("📊 Loading playlist tracks for ID: \(playlistId)...")
            Task {
                await spotifyManager.fetchPlaylistTracks(playlistId: playlistId)
                print("📊 Playlist tracks loaded: \(spotifyManager.tracks.count) items")
            }
        case .artists:
            print("📊 Loading artists data...")
            Task {
                await spotifyManager.fetchTopArtists()
                print("📊 Artists loaded: \(spotifyManager.artists.count) items")
            }
        case .albums:
            print("📊 Loading albums data...")
            Task {
                await spotifyManager.fetchAlbums()
                print("📊 Albums loaded: \(spotifyManager.albums.count) items")
            }
        case .songs:
            print("📊 Loading liked songs data...")
            Task {
                await spotifyManager.fetchLikedSongs()
                print("📊 Liked songs loaded: \(spotifyManager.tracks.count) items")
            }
        default:
            break
        }
    }
    
    @ViewBuilder
    private func destinationView(for action: MenuAction) -> some View {
        switch action {
        case .playlists:
            PlaylistsView()
                .environmentObject(spotifyManager)
        case .artists:
            ArtistsView()
                .environmentObject(spotifyManager)
        case .albums:
            AlbumsView()
                .environmentObject(spotifyManager)
        case .songs:
            SongsView()
                .environmentObject(spotifyManager)
        case .nowPlaying:
            NowPlayingView()
                .environmentObject(spotifyManager)
        }
    }
}

struct MenuItem {
    let title: String
    let icon: String
    let action: MenuAction
}

enum MenuAction {
    case playlists
    case artists
    case albums
    case songs
    case nowPlaying
}

struct iPodMenuView_Previews: PreviewProvider {
    static var previews: some View {
        iPodMenuView()
            .environmentObject(SpotifyManager())
            .previewDevice("iPhone 14")
    }
}
