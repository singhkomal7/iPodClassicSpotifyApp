import Foundation
import SpotifyiOS
import Combine
import AVFoundation
import MediaPlayer
import UIKit

class SpotifyManager: NSObject, ObservableObject {
    @Published var isLoggedIn = false
    @Published var trackName = "Unknown"
    @Published var artistName = "Unknown"
    @Published var isPlaying = false
    @Published var playlists: [Playlist] = []
    @Published var tracks: [Track] = []
    @Published var artists: [Artist] = []
    @Published var albums: [Album] = []
    @Published var volume: Float = 0.5 // Volume level (0.0 - 1.0)
    @Published var showNowPlaying = false
    @Published var currentTrackURI: String = ""
    @Published var volumeChanged = false // Trigger for volume bar display
    @Published var currentTrackIndex: Int = 0
    @Published var currentPlaylistId: String = ""
    @Published var coverArtURL: String = ""
    @Published var currentPosition: TimeInterval = 0
    @Published var trackDuration: TimeInterval = 0
    @Published var lastPlayerState: SPTAppRemotePlayerState?

    let appRemote: SPTAppRemote
    private var cancellables = Set<AnyCancellable>()
    private var refreshToken: String?
    private let volumeController = VolumeController()

    override init() {
        print("🛠 Initializing SpotifyManager")
        let configuration = SPTConfiguration(clientID: Config.clientID, redirectURL: Config.redirectURI)
        self.appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        super.init()
        appRemote.delegate = self
        print("✅ SpotifyManager initialized, clientID: \(Config.clientID), redirectURI: \(Config.redirectURI)")
    }

    func login() {
        guard !isLoggedIn else {
            print("🚫 Already logged in, skipping login. isLoggedIn: \(isLoggedIn)")
            return
        }
        print("🔑 Attempting Spotify app-to-app login with clientID: \(Config.clientID), redirectURI: \(Config.redirectURI.absoluteString)")
        
        // Set the flag to pause immediately when connection is established
        shouldPauseOnConnection = true
        
        // Check if Spotify app is available
        guard UIApplication.shared.canOpenURL(URL(string: "spotify:")!) else {
            print("❌ Spotify app is not installed")
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.shouldPauseOnConnection = false
            }
            return
        }
        
        // Use the correct authorization method for iOS SDK
        if appRemote.isConnected {
            print("✅ Already connected to Spotify")
            DispatchQueue.main.async {
                self.isLoggedIn = true
            }
        } else {
            // Use the iOS SDK's native app-to-app authorization flow
            // This bypasses web OAuth and communicates directly with the Spotify app
            print("🔑 Initiating iOS SDK app-to-app authorization flow")
            
            // Use a sample track URI for authorization - this will trigger the native auth flow
            let sampleTrackURI = "spotify:track:4iV5W9uYEdYUVa79Axb7Rh" // "Never Gonna Give You Up" by Rick Astley
            
            // This will trigger the native authorization flow in the Spotify app
            appRemote.authorizeAndPlayURI(sampleTrackURI) { [weak self] result in
                if result {
                    print("✅ App-to-app authorization successful")
                    DispatchQueue.main.async {
                        self?.isLoggedIn = true
                    }
                    // The connection will be established automatically through the delegate
                } else {
                    print("❌ App-to-app authorization failed")
                    DispatchQueue.main.async {
                        self?.isLoggedIn = false
                        self?.shouldPauseOnConnection = false
                    }
                }
            }
        }
    }

    func handleAuthCallback(url: URL) {
        print("📬 Handling app-to-app authorization callback URL: \(url.absoluteString)")
        
        // Check for errors first
        if url.absoluteString.contains("error") {
            print("❌ App-to-app authorization failed")
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.shouldPauseOnConnection = false
            }
            return
        }
        
        // Extract access token from URL fragment
        let urlString = url.absoluteString
        if let fragmentRange = urlString.range(of: "#") {
            let fragment = String(urlString[fragmentRange.upperBound...])
            let parameters = fragment.components(separatedBy: "&")
            
            var accessToken: String?
            var expiresIn: Int?
            
            for parameter in parameters {
                let keyValue = parameter.components(separatedBy: "=")
                if keyValue.count == 2 {
                    let key = keyValue[0]
                    let value = keyValue[1]
                    
                    switch key {
                    case "access_token":
                        accessToken = value
                    case "expires_in":
                        expiresIn = Int(value)
                    default:
                        break
                    }
                }
            }
            
            if let token = accessToken {
                print("🔑 Extracted access token: \(token.prefix(20))...")
                print("⏰ Token expires in: \(expiresIn ?? 0) seconds")
                
                // Store the access token in the app remote connection parameters
                appRemote.connectionParameters.accessToken = token
                
                DispatchQueue.main.async {
                    self.isLoggedIn = true
                }
                
                // Connect to Spotify with the new token
                connectWithImmediatePause()
                
                print("✅ Access token stored and connection initiated")
            } else {
                print("❌ Failed to extract access token from callback URL")
                DispatchQueue.main.async {
                    self.isLoggedIn = false
                    self.shouldPauseOnConnection = false
                }
            }
        } else {
            print("✅ App-to-app authorization callback received")
            // Fallback: The SDK will handle the connection automatically
        }
    }
    
    
    private func connectWithFallback() {
        print("🔌 Attempting robust connection with enhanced monitoring")
        
        // Connect with immediate pause for app-to-app auth
        connectWithImmediatePause()
        
        // Set a timeout to check if connection succeeds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if !self.appRemote.isConnected {
                print("⚠️ Initial connection attempt failed, retrying...")
                // Retry connection
                self.connect()
            } else {
                print("✅ iOS SDK connection established successfully")
            }
        }
    }
    
    
    private func connectWithImmediatePause() {
        guard appRemote.connectionParameters.accessToken != nil else {
            print("🚫 No access token for connection")
            return
        }
        guard !appRemote.isConnected else {
            print("ℹ️ Already connected to Spotify, pausing immediately")
            immediatelyPausePlayback()
            return
        }
        
        print("🔌 Connecting to Spotify with immediate pause")
        appRemote.connect()
        
        // Set a flag to pause immediately upon connection
        shouldPauseOnConnection = true
    }
    
    private var shouldPauseOnConnection = false
    private var connectionHeartbeatTimer: Timer?
    private var reconnectionAttempts = 0
    private let maxReconnectionAttempts = 15 // Increased for better resilience
    private var connectionMonitorTimer: Timer?
    private var lastSuccessfulHeartbeat = Date()
    private let connectionTimeoutInterval: TimeInterval = 30 // Reduced for faster recovery
    private var isReconnecting = false
    private var keepAliveTimer: Timer?
    private var aggressiveMonitoringTimer: Timer?
    private var connectionRetryTimer: Timer?
    
    private func immediatelyPausePlayback() {
        // Pause any current playback immediately
        appRemote.playerAPI?.pause { [weak self] _, error in
            if let error = error {
                print("🔇 Failed to pause immediately: \(error)")
            } else {
                print("🔇 Successfully paused playback immediately")
                DispatchQueue.main.async {
                    self?.isPlaying = false
                }
            }
        }
        
        // Also try to get current player state and pause if playing
        appRemote.playerAPI?.getPlayerState { [weak self] playerState, error in
            if let error = error {
                print("🔇 Failed to get player state: \(error)")
            } else if let playerState = playerState as? SPTAppRemotePlayerState, !playerState.isPaused {
                print("🔇 Player is currently playing, pausing now")
                self?.appRemote.playerAPI?.pause { _, pauseError in
                    if let pauseError = pauseError {
                        print("🔇 Failed to pause playing track: \(pauseError)")
                    } else {
                        print("🔇 Successfully paused currently playing track")
                        DispatchQueue.main.async {
                            self?.isPlaying = false
                        }
                    }
                }
            } else {
                print("ℹ️ Player is already paused or no track playing")
            }
        }
    }

    func connect() {
        guard appRemote.connectionParameters.accessToken != nil else {
            print("🚫 No access token for connection")
            return
        }
        guard !appRemote.isConnected else {
            print("ℹ️ Already connected to Spotify")
            return
        }
        print("🔌 Connecting to Spotify")
        appRemote.connect()
    }

    func disconnect() {
        print("🔌 Disconnecting from Spotify")
        stopConnectionHeartbeat()
        stopConnectionMonitoring()
        stopKeepAlive()
        stopAggressiveMonitoring()
        stopConnectionRetryTimer()
        appRemote.disconnect()
        
        // Clean up state
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentPosition = 0
            self.trackDuration = 0
        }
    }

    func playTrack(uri: String) {
        guard !uri.isEmpty else {
            print("🚫 Cannot play empty URI")
            return
        }
        guard isLoggedIn else {
            print("🚫 Cannot play track - not logged in")
            return
        }
        
        print("▶️ Playing track: \(uri)")
        
        // Ensure connection before playing
        if !appRemote.isConnected {
            connect()
            // Wait a moment for connection to establish
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.executePlayTrack(uri: uri)
            }
        } else {
            executePlayTrack(uri: uri)
        }
    }
    
    private func executePlayTrack(uri: String) {
        appRemote.playerAPI?.play(uri, callback: { [weak self] (result: Any?, error: Error?) in
            if let error = error {
                print("❌ Play error: \(error)")
                // Try to reconnect if connection was lost
                if (error as NSError).code == -1001 || (error as NSError).code == -2001 {
                    print("🔄 Connection lost, attempting to reconnect...")
                    self?.connect()
                }
                } else {
                    print("✅ Track playing successfully")
                    HapticManager.shared.successFeedback()
                    DispatchQueue.main.async {
                        self?.isPlaying = true
                        self?.currentTrackURI = uri
                        self?.showNowPlaying = true
                    }
                }
        })
    }

    func pause() {
        print("⏸ Pausing playback")
        appRemote.playerAPI?.pause { [weak self] (result, error: Error?) in
            if let error = error {
                print("❌ Pause error: \(error)")
            } else {
                print("✅ Paused")
                DispatchQueue.main.async {
                    self?.isPlaying = false
                }
            }
        }
    }
    
    func resume() {
        print("▶️ Attempting to resume playback")
        
        // First try to get current player state to see if we can resume
        appRemote.playerAPI?.getPlayerState { [weak self] (playerState, error) in
            if let error = error {
                print("❌ Error getting player state for resume: \(error)")
                // If we can't get player state, try playing the stored track
                if !(self?.currentTrackURI.isEmpty ?? true) {
                    self?.playTrack(uri: self?.currentTrackURI ?? "")
                }
                return
            }
            
            guard let playerState = playerState as? SPTAppRemotePlayerState else {
                print("❌ No player state available for resume")
                return
            }
            
            // Update our state with current player state
            DispatchQueue.main.async {
                self?.trackName = playerState.track.name
                self?.artistName = playerState.track.artist.name
                self?.currentTrackURI = playerState.track.uri
                self?.currentPosition = TimeInterval(playerState.playbackPosition) / 1000.0
                self?.trackDuration = TimeInterval(playerState.track.duration) / 1000.0
                self?.lastPlayerState = playerState
            }
            
            if playerState.isPaused {
                print("▶️ Track is paused, resuming: \(playerState.track.name)")
                self?.appRemote.playerAPI?.resume { [weak self] (result, error: Error?) in
                    if let error = error {
                        print("❌ Resume error: \(error), trying alternative approach")
                        // Try playing from current position
                        self?.appRemote.playerAPI?.play(playerState.track.uri, callback: { _, playError in
                            if let playError = playError {
                                print("❌ Alternative play error: \(playError)")
                            } else {
                                print("✅ Resumed via play command")
                                DispatchQueue.main.async {
                                    self?.isPlaying = true
                                }
                            }
                        })
                    } else {
                        print("✅ Successfully resumed playback")
                        DispatchQueue.main.async {
                            self?.isPlaying = true
                        }
                    }
                }
            } else {
                print("ℹ️ Track is already playing")
                DispatchQueue.main.async {
                    self?.isPlaying = true
                }
            }
        }
    }

    private func fetchCurrentTrackInfo() {
        appRemote.playerAPI?.getPlayerState { [weak self] (playerState, error) in
            if let error = error {
                print("❌ Error fetching track info: \(error)")
            } else if let playerState = playerState as? SPTAppRemotePlayerState {
                DispatchQueue.main.async {
                    self?.trackName = playerState.track.name
                    self?.artistName = playerState.track.artist.name
                    self?.currentTrackURI = playerState.track.uri
                    self?.currentPosition = TimeInterval(playerState.playbackPosition) / 1000.0
                    self?.trackDuration = TimeInterval(playerState.track.duration) / 1000.0
                }
            }
        }
    }

    func skipToNext() {
        print("⏭ Skipping to next track")
        
        // If we have playlist context, navigate within the playlist
        if !currentPlaylistId.isEmpty && !tracks.isEmpty {
            skipToNextInPlaylist()
        } else {
            // Use Spotify's default next functionality
            appRemote.playerAPI?.skip(toNext: { [weak self] (result: Any?, error: Error?) in
                if let error = error {
                    print("❌ Skip next error: \(error)")
                } else {
                    print("✅ Skipped to next track successfully")
                    self?.fetchCurrentTrackInfo()
                }
            })
        }
    }

    func skipToPrevious() {
        print("⏮ Skipping to previous track")
        
        // If we have playlist context, navigate within the playlist
        if !currentPlaylistId.isEmpty && !tracks.isEmpty {
            skipToPreviousInPlaylist()
        } else {
            // Use Spotify's default previous functionality
            appRemote.playerAPI?.skip(toPrevious: { [weak self] (result: Any?, error: Error?) in
                if let error = error {
                    print("❌ Skip previous error: \(error)")
                } else {
                    print("✅ Skipped to previous track successfully")
                    self?.fetchCurrentTrackInfo()
                }
            })
        }
    }
    
    private func skipToNextInPlaylist() {
        guard currentTrackIndex < tracks.count - 1 else {
            print("⚠️ Already at last track in playlist")
            return
        }
        
        currentTrackIndex += 1
        let nextTrack = tracks[currentTrackIndex]
        print("⏭ Playing next track in playlist: \(nextTrack.name)")
        playTrack(uri: nextTrack.uri)
    }
    
    private func skipToPreviousInPlaylist() {
        guard currentTrackIndex > 0 else {
            print("⚠️ Already at first track in playlist")
            return
        }
        
        currentTrackIndex -= 1
        let prevTrack = tracks[currentTrackIndex]
        print("⏮ Playing previous track in playlist: \(prevTrack.name)")
        playTrack(uri: prevTrack.uri)
    }
    
    func setPlaylistContext(playlistId: String, trackIndex: Int) {
        print("🎵 Setting playlist context: \(playlistId), track index: \(trackIndex)")
        currentPlaylistId = playlistId
        currentTrackIndex = trackIndex
    }
    
    func increaseVolume(by increment: Float = 0.1) {
        print("🔊⬆️ Increasing system volume...")
        volumeController.increaseVolume(by: increment)
        
        // Update our local volume state and trigger UI update
        DispatchQueue.main.async {
            self.volume = self.volumeController.currentVolume
            self.volumeChanged.toggle() // Trigger volume bar display
        }
    }
    
    func decreaseVolume(by decrement: Float = 0.1) {
        print("🔊⬇️ Decreasing system volume...")
        volumeController.decreaseVolume(by: decrement)
        
        // Update our local volume state and trigger UI update
        DispatchQueue.main.async {
            self.volume = self.volumeController.currentVolume
            self.volumeChanged.toggle() // Trigger volume bar display
        }
    }
    
    func getCurrentVolume() {
        appRemote.playerAPI?.getPlayerState { [weak self] playerState, error in
            if let error = error {
                print("❌ Failed to get player state for volume: \(error)")
            } else if let playerState = playerState as? SPTAppRemotePlayerState {
                // Note: SPTAppRemote doesn't provide direct volume access
                // We'll maintain our own volume state
                DispatchQueue.main.async {
                    print("🔊 Current volume maintained at: \(Int((self?.volume ?? 0.5) * 100))%")
                }
            }
        }
    }

    func fetchPlaylists() async {
        guard let accessToken = appRemote.connectionParameters.accessToken else {
            print("🚫 No access token for playlists")
            return
        }
        do {
            let playlists = try await SpotifyService().fetchPlaylists(accessToken: accessToken)
            print("📜 Fetched \(playlists.count) playlists: \(playlists.map { $0.name })")
            DispatchQueue.main.async {
                self.playlists = playlists
            }
        } catch {
            print("❌ Playlist fetch error: \(error)")
        }
    }

    func fetchLibraryTracks() async {
        guard let accessToken = appRemote.connectionParameters.accessToken else {
            print("🚫 No access token for tracks")
            return
        }
        do {
            let tracks = try await SpotifyService().fetchLibraryTracks(accessToken: accessToken)
            print("🎵 Fetched \(tracks.count) library tracks: \(tracks.map { $0.name })")
            DispatchQueue.main.async {
                self.tracks = tracks
            }
        } catch {
            print("❌ Track fetch error: \(error)")
        }
    }
    
    func fetchLikedSongs() async {
        guard let accessToken = appRemote.connectionParameters.accessToken else {
            print("🚫 No access token for liked songs")
            return
        }
        do {
            let tracks = try await SpotifyService().fetchLikedSongs(accessToken: accessToken)
            print("💖 Fetched \(tracks.count) liked songs: \(tracks.map { $0.name })")
            DispatchQueue.main.async {
                self.tracks = tracks
            }
        } catch {
            print("❌ Liked songs fetch error: \(error)")
            // If API call fails due to permissions, fall back to showing library tracks instead
            if (error as? URLError)?.code == .noPermissionsToReadFile {
                print("🔄 Falling back to library tracks due to permission issue")
                await fetchLibraryTracks()
            } else {
                DispatchQueue.main.async {
                    self.tracks = []
                }
            }
        }
    }

    func fetchPlaylistTracks(playlistId: String) async {
        guard let accessToken = appRemote.connectionParameters.accessToken else {
            print("🚫 No access token for tracks")
            return
        }
        do {
            let tracks = try await SpotifyService().fetchPlaylistTracks(playlistId: playlistId, accessToken: accessToken)
            print("🎵 Fetched \(tracks.count) tracks for playlist \(playlistId): \(tracks.map { $0.name })")
            DispatchQueue.main.async {
                self.tracks = tracks
            }
        } catch {
            print("❌ Track fetch error: \(error)")
        }
    }

    func fetchTopArtists() async {
        guard let accessToken = appRemote.connectionParameters.accessToken else {
            print("🚫 No access token for artists")
            return
        }
        do {
            let artists = try await SpotifyService().fetchTopArtists(accessToken: accessToken)
            print("🎤 Fetched \(artists.count) artists: \(artists.map { $0.name })")
            DispatchQueue.main.async {
                self.artists = artists
            }
        } catch {
            print("❌ Artist fetch error: \(error)")
            // If permission denied, show empty list with informative message
            if (error as? URLError)?.code == .noPermissionsToReadFile {
                print("📝 Artists require additional Spotify permissions")
            }
            DispatchQueue.main.async {
                self.artists = []
            }
        }
    }

    func fetchAlbums() async {
        guard let accessToken = appRemote.connectionParameters.accessToken else {
            print("🚫 No access token for albums")
            return
        }
        do {
            let albums = try await SpotifyService().fetchAlbums(accessToken: accessToken)
            print("💿 Fetched \(albums.count) albums: \(albums.map { $0.name })")
            DispatchQueue.main.async {
                self.albums = albums
            }
        } catch {
            print("❌ Album fetch error: \(error)")
            // If permission denied, show empty list with informative message
            if (error as? URLError)?.code == .noPermissionsToReadFile {
                print("📝 Albums require additional Spotify permissions")
            }
            DispatchQueue.main.async {
                self.albums = []
            }
        }
    }

    func fetchArtistTracks(artistId: String) async {
        guard let accessToken = appRemote.connectionParameters.accessToken else {
            print("🚫 No access token for artist tracks")
            return
        }
        do {
            let tracks = try await SpotifyService().fetchArtistTopTracks(artistId: artistId, accessToken: accessToken)
            print("🎵 Fetched \(tracks.count) tracks for artist \(artistId): \(tracks.map { $0.name })")
            DispatchQueue.main.async {
                self.tracks = tracks
            }
        } catch {
            print("❌ Artist tracks fetch error: \(error)")
        }
    }

    func fetchAlbumTracks(albumId: String) async {
        guard let accessToken = appRemote.connectionParameters.accessToken else {
            print("🚫 No access token for album tracks")
            return
        }
        do {
            let tracks = try await SpotifyService().fetchAlbumTracks(albumId: albumId, accessToken: accessToken)
            print("🎵 Fetched \(tracks.count) tracks for album \(albumId): \(tracks.map { $0.name })")
            DispatchQueue.main.async {
                self.tracks = tracks
            }
        } catch {
            print("❌ Album tracks fetch error: \(error)")
        }
    }

    func refreshTokenIfNeeded() async {
        guard let refreshToken = self.refreshToken else {
            print("🚫 No refresh token available")
            DispatchQueue.main.async {
                self.isLoggedIn = false
            }
            return
        }
        do {
            let newToken = try await SpotifyService().refreshAccessToken(refreshToken: refreshToken)
            print("🔐 New access token received: \(newToken.prefix(10))...")
            appRemote.connectionParameters.accessToken = newToken
            DispatchQueue.main.async {
                self.isLoggedIn = true
            }
            connect()
        } catch {
            print("❌ Token refresh error: \(error)")
            DispatchQueue.main.async {
                self.isLoggedIn = false
            }
        }
    }
    
    // Handle reconnection attempts for temporary disconnections
    private func attemptReconnection() {
        guard !appRemote.isConnected, isLoggedIn, !isReconnecting else {
            print("🔌 Already connected, logged out, or reconnecting - skipping")
            return
        }
        
        // Don't exceed max attempts
        guard reconnectionAttempts < maxReconnectionAttempts else {
            print("❌ Max reconnection attempts reached, stopping")
            handlePermanentDisconnection()
            return
        }
        
        isReconnecting = true
        print("🔄 Attempting to reconnect to Spotify (attempt \(reconnectionAttempts + 1)/\(maxReconnectionAttempts))")
        
        // Progressive delay based on attempt count, but shorter delays
        let delay = min(Double(reconnectionAttempts) * 1.0 + 0.5, 5.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if self.isLoggedIn && !self.appRemote.isConnected {
                self.reconnectionAttempts += 1
                self.appRemote.connect()
                print("🔄 Reconnection attempt \(self.reconnectionAttempts) initiated with \(delay)s delay")
                
                // Reset flag after connection attempt
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.isReconnecting = false
                    
                    // If still not connected after this attempt, try again
                    if !self.appRemote.isConnected && self.reconnectionAttempts < self.maxReconnectionAttempts {
                        self.attemptReconnection()
                    }
                }
            } else {
                self.isReconnecting = false
            }
        }
    }

    // Handle permanent disconnection with user notification
    private func handlePermanentDisconnection() {
        stopConnectionHeartbeat()
        DispatchQueue.main.async {
            self.isPlaying = false
            self.isLoggedIn = false
        }
        print("❌ Permanent disconnection - user action required")
        // Could add user notification or visual feedback here
    }
    
    private func startConnectionHeartbeat() {
        stopConnectionHeartbeat() // Stop any existing timer
        
        // Frequent heartbeat to catch issues early
        connectionHeartbeatTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isLoggedIn else { return }
            
            if !self.appRemote.isConnected {
                print("💗 Heartbeat: Connection lost, attempting reconnection")
                self.attemptReconnection()
            } else {
                // Check connection health by getting player state
                self.appRemote.playerAPI?.getPlayerState { [weak self] playerState, error in
                    if let error = error {
                        print("💗 Heartbeat: Connection health check failed: \(error)")
                        // Connection might be unhealthy, preemptively reconnect
                        self?.attemptReconnection()
                    } else {
                        print("💗 Heartbeat: Connection healthy")
                        self?.reconnectionAttempts = 0 // Reset on successful health check
                        self?.lastSuccessfulHeartbeat = Date() // Update last successful heartbeat
                    }
                }
            }
        }
    }
    
    private func stopConnectionHeartbeat() {
        connectionHeartbeatTimer?.invalidate()
        connectionHeartbeatTimer = nil
    }
    
    private func startConnectionMonitoring() {
        stopConnectionMonitoring() // Stop any existing timer
        
        // Aggressive monitoring to catch issues very quickly
        connectionMonitorTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isLoggedIn else { return }
            
            // Check if we haven't had a successful heartbeat in too long
            let timeSinceLastHeartbeat = Date().timeIntervalSince(self.lastSuccessfulHeartbeat)
            
            // Reduced timeout to 20 seconds for very fast detection
            if timeSinceLastHeartbeat > 20.0 {
                print("⚠️ Connection timeout detected (\(Int(timeSinceLastHeartbeat))s since last heartbeat)")
                
                // Proactively reconnect before full disconnection
                if self.appRemote.isConnected {
                    print("🔄 Proactive reconnection to prevent timeout")
                    self.appRemote.disconnect()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.connect()
                    }
                } else {
                    print("🔄 Connection already lost, attempting reconnection")
                    self.attemptReconnection()
                }
            } else if self.appRemote.isConnected {
                // Perform lightweight connection check more frequently
                self.appRemote.playerAPI?.getPlayerState { [weak self] playerState, error in
                    if error == nil {
                        self?.lastSuccessfulHeartbeat = Date()
                    } else {
                        print("⚠️ Connection health check failed: \(error?.localizedDescription ?? "Unknown")")
                        // If health check fails, try reconnection
                        self?.attemptReconnection()
                    }
                }
            }
        }
    }
    
    private func stopConnectionMonitoring() {
        connectionMonitorTimer?.invalidate()
        connectionMonitorTimer = nil
    }
    
    private func startKeepAlive() {
        stopKeepAlive() // Stop any existing timer
        
        // Keep connection alive with frequent, lightweight requests
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isLoggedIn, self.appRemote.isConnected else { return }
            
            // Simple ping to keep connection alive
            self.appRemote.playerAPI?.getPlayerState { [weak self] playerState, error in
                if let error = error {
                    print("📡 Keep-alive failed: \(error)")
                    // If keep-alive fails, try immediate reconnection
                    self?.attemptReconnection()
                } else {
                    print("📡 Keep-alive ping successful")
                    self?.lastSuccessfulHeartbeat = Date()
                }
            }
        }
    }
    
    private func stopKeepAlive() {
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
    }
    
    private func startAggressiveMonitoring() {
        stopAggressiveMonitoring()
        
        // Very aggressive monitoring for the first few minutes after connection
        aggressiveMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isLoggedIn else { return }
            
            if !self.appRemote.isConnected {
                print("🚨 Aggressive monitoring detected disconnection")
                self.attemptReconnection()
            }
        }
        
        // Stop aggressive monitoring after 5 minutes
        DispatchQueue.main.asyncAfter(deadline: .now() + 300.0) {
            self.stopAggressiveMonitoring()
            print("ℹ️ Aggressive monitoring period ended")
        }
    }
    
    private func stopAggressiveMonitoring() {
        aggressiveMonitoringTimer?.invalidate()
        aggressiveMonitoringTimer = nil
    }
    
    private func startConnectionRetryTimer() {
        stopConnectionRetryTimer()
        
        // Retry connection every 5 seconds if disconnected
        connectionRetryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isLoggedIn else { return }
            
            if !self.appRemote.isConnected {
                print("🔄 Retry timer: Attempting reconnection")
                self.connect()
            }
        }
    }
    
    private func stopConnectionRetryTimer() {
        connectionRetryTimer?.invalidate()
        connectionRetryTimer = nil
    }
}

extension SpotifyManager: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("🔌 Spotify connected successfully")
        appRemote.playerAPI?.delegate = self
        
        // Subscribe to player state to track changes
        appRemote.playerAPI?.subscribe(toPlayerState: { [weak self] (result, error) in
            if let error = error {
                print("❌ Failed to subscribe to player state: \(error)")
            } else {
                print("✅ Subscribed to player state successfully")
            }
        })
        
        // If we should pause on connection (after auth), do it immediately
        if shouldPauseOnConnection {
            print("🔇 Connection established after auth - pausing immediately")
            shouldPauseOnConnection = false
            immediatelyPausePlayback()
        }
        
        print("🎮 Player API delegate set and subscribed to player state")
        
        // Start connection heartbeat
        startConnectionHeartbeat()
        
        // Start connection monitoring
        startConnectionMonitoring()
        
        // Start keep-alive mechanism
        startKeepAlive()
        
        // Start aggressive monitoring for the first few minutes
        startAggressiveMonitoring()
        
        // Start connection retry timer as backup
        startConnectionRetryTimer()
        
        // Reset reconnection attempts on successful connection
        reconnectionAttempts = 0
        lastSuccessfulHeartbeat = Date()
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("❌ Connection failed: \(error?.localizedDescription ?? "Unknown")")
        
        // Don't immediately set isLoggedIn to false - token might still be valid
        if let nsError = error as NSError? {
            switch nsError.code {
            case -1001, -1009: // Network errors
                print("🌐 Network error, will retry connection later")
                // Retry connection after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self.isLoggedIn && !appRemote.isConnected {
                        self.connect()
                    }
                }
            default:
                DispatchQueue.main.async {
                    self.isLoggedIn = false
                }
            }
        } else {
            DispatchQueue.main.async {
                self.isLoggedIn = false
            }
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("🔌 Disconnected: \(error?.localizedDescription ?? "Unknown")")
        
        DispatchQueue.main.async {
            self.isPlaying = false
        }
        
        if let nsError = error as NSError? {
            switch nsError.code {
            case -2001: // End of stream - recoverable
                print("🔄 End of stream detected, attempting recovery")
                attemptReconnection()
                
            case -1002: // Connection terminated - attempt to recover
                print("🔄 Connection terminated (-1002), checking underlying error")
                if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                    if underlyingError.code == -2001 {
                        print("🔄 Underlying end of stream, attempting reconnection")
                        attemptReconnection()
                    } else {
                        print("❌ Unrecoverable underlying error: \(underlyingError)")
                        handlePermanentDisconnection()
                    }
                } else {
                    print("🔄 Connection terminated without underlying error, attempting reconnection")
                    attemptReconnection()
                }
                
            case -1001, -1009: // Network errors
                print("🌐 Network disconnection, will retry")
                attemptReconnection()
                
            case -1000: // Generic error - try to recover
                print("🔄 Generic error, attempting recovery")
                attemptReconnection()
                
            default:
                print("❌ Unhandled disconnection error code \(nsError.code): \(nsError)")
                // For unknown errors, try reconnection first before giving up
                attemptReconnection()
            }
        } else {
            // No error means intentional disconnect
            print("ℹ️ Intentional disconnect")
        }
    }
}

extension SpotifyManager: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("🎵 Player state changed: track = \(playerState.track.name), artist = \(playerState.track.artist.name), isPaused = \(playerState.isPaused), position = \(playerState.playbackPosition)ms, duration = \(playerState.track.duration)ms")
        DispatchQueue.main.async {
            self.trackName = playerState.track.name
            self.artistName = playerState.track.artist.name
            self.isPlaying = !playerState.isPaused
            self.currentTrackURI = playerState.track.uri
            self.currentPosition = TimeInterval(playerState.playbackPosition) / 1000.0 // Convert from ms to seconds
            self.trackDuration = TimeInterval(playerState.track.duration) / 1000.0 // Convert from ms to seconds
            self.lastPlayerState = playerState
        }
    }
}


