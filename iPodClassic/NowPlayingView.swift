import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @EnvironmentObject var navigationState: iPodNavigationState
    @State private var showVolumeBar = false
    @State private var volumeBarTimer: Timer?
    @State private var progressTimer: Timer?
    
    private var progressRatio: CGFloat {
        guard spotifyManager.trackDuration > 0 else { return 0 }
        return CGFloat(spotifyManager.currentPosition / spotifyManager.trackDuration)
    }
    
    var body: some View {
        nowPlayingContent
    }
    
    private var nowPlayingContent: some View {
        VStack(spacing: 0) {
            iPodScreenHeader(title: "Now Playing")
            
            VStack(spacing: 16) {
                // Album artwork
                Group {
                    if let coverArtURL = getCurrentTrackCoverArt(), !coverArtURL.isEmpty {
                        AsyncImage(url: URL(string: coverArtURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .tint(.blue)
                                )
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            )
                    }
                }
                
                // Track information
                VStack(spacing: 4) {
                    Text(spotifyManager.trackName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                    
                    Text(spotifyManager.artistName)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: 250)
                
                // Progress/Volume bar
                VStack(spacing: 4) {
                    if showVolumeBar {
                        // Volume bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 2)
                                
                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(width: geometry.size.width * CGFloat(spotifyManager.volume), height: 2)
                            }
                        }
                        .frame(height: 2)
                        
                        // Volume labels
                        HStack {
                            Image(systemName: "speaker.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(Int(spotifyManager.volume * 100))%")
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                        }
                    } else {
                        // Song progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 2)
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * progressRatio, height: 2)
                            }
                        }
                        .frame(height: 2)
                        
                        // Time labels
                        HStack {
                            Text(formatTime(spotifyManager.currentPosition))
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                            Spacer()
                            Text(formatTime(spotifyManager.trackDuration))
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Playback controls
                HStack(spacing: 24) {
                    Button(action: {
                        spotifyManager.skipToPrevious()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {
                        if spotifyManager.isPlaying {
                            spotifyManager.pause()
                        } else {
                            spotifyManager.resume()
                        }
                    }) {
                        Image(systemName: spotifyManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        spotifyManager.skipToNext()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .onAppear {
            // Start real progress tracking
            startProgressTracking()
        }
        .onDisappear {
            stopProgressTracking()
        }
        .onChange(of: spotifyManager.volumeChanged) { _ in
            // Show volume bar when volume is changed
            showVolumeBarTemporarily()
        }
    }
    
    private func startProgressTracking() {
        stopProgressTracking() // Stop any existing timer
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard spotifyManager.isPlaying else { return }
            
            // Update position if playing (estimate between server updates)
            DispatchQueue.main.async {
                if spotifyManager.currentPosition < spotifyManager.trackDuration {
                    spotifyManager.currentPosition += 0.5
                }
            }
        }
    }
    
    private func stopProgressTracking() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func showVolumeBarTemporarily() {
        showVolumeBar = true
        
        // Cancel existing timer
        volumeBarTimer?.invalidate()
        
        // Set new timer to hide volume bar after 2 seconds
        volumeBarTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showVolumeBar = false
            }
        }
    }
    
    func handleVolumeUp() {
        HapticManager.shared.lightFeedback()
        spotifyManager.increaseVolume()
        showVolumeBarTemporarily()
    }
    
    func handleVolumeDown() {
        HapticManager.shared.lightFeedback()
        spotifyManager.decreaseVolume()
        showVolumeBarTemporarily()
    }
    
    private func getCurrentTrackCoverArt() -> String? {
        // Try to find the current track in the loaded tracks to get cover art
        if let currentTrack = spotifyManager.tracks.first(where: { $0.uri == spotifyManager.currentTrackURI }) {
            return currentTrack.album?.images?.first?.url
        }
        return nil
    }
}
