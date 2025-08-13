import SwiftUI
import SpotifyiOS

struct PlaylistTracksView: View {
    let playlistId: String
    @EnvironmentObject var spotifyManager: SpotifyManager
    @State private var selectedIndex = 0
    @State private var isLoading = true
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        iPodLayoutView(
            content: {
                tracksScreenContent
            },
            onMenuPress: {
                print("🔙 Menu pressed - going back to playlists")
                presentationMode.wrappedValue.dismiss()
            },
            onPlayPausePress: {
                print("⏯️ Play/Pause pressed")
                if spotifyManager.isPlaying {
                    spotifyManager.pause()
                } else {
                    if !spotifyManager.tracks.isEmpty {
                        let selectedTrack = spotifyManager.tracks[selectedIndex]
                        print("▶️ Playing track: \(selectedTrack.name) by \(selectedTrack.artists.first?.name ?? "Unknown")")
                        spotifyManager.playTrack(uri: selectedTrack.uri)
                    }
                }
            },
            onPreviousPress: {
                print("⏮️ Previous pressed")
                spotifyManager.skipToPrevious()
            },
            onNextPress: {
                print("⏭️ Next pressed")
                spotifyManager.skipToNext()
            },
            onCenterPress: {
                guard !spotifyManager.tracks.isEmpty else { return }
                let selectedTrack = spotifyManager.tracks[selectedIndex]
                print("✅ Center pressed - playing track: \(selectedTrack.name) by \(selectedTrack.artists.first?.name ?? "Unknown")")
                print("🎵 Track URI: \(selectedTrack.uri)")
                spotifyManager.playTrack(uri: selectedTrack.uri)
            },
            onScrollUp: {
                if selectedIndex > 0 {
                    selectedIndex -= 1
                    if !spotifyManager.tracks.isEmpty {
                        print("⬆️ Scroll up - selected: \(spotifyManager.tracks[selectedIndex].name)")
                    }
                }
            },
            onScrollDown: {
                if selectedIndex < spotifyManager.tracks.count - 1 {
                    selectedIndex += 1
                    if !spotifyManager.tracks.isEmpty {
                        print("⬇️ Scroll down - selected: \(spotifyManager.tracks[selectedIndex].name)")
                    }
                }
            },
            onScrollLeft: {
                print("⬅️ Scroll left")
            },
            onScrollRight: {
                print("➡️ Scroll right")
            }
        )
        .onAppear {
            Task {
                isLoading = true
                await spotifyManager.fetchPlaylistTracks(playlistId: playlistId)
                isLoading = false
                if !spotifyManager.tracks.isEmpty {
                    selectedIndex = 0
                }
            }
        }
    }
    
    private var tracksScreenContent: some View {
        VStack(spacing: 0) {
            iPodScreenHeader(
                title: "Tracks", 
                subtitle: "\(spotifyManager.tracks.count) songs"
            )
            
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 0) {
                    if isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading...")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if spotifyManager.tracks.isEmpty {
                        VStack {
                            Text("No Tracks")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            Text("This playlist is empty")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ForEach(Array(spotifyManager.tracks.enumerated()), id: \.offset) { index, track in
                            iPodListItem(
                                icon: spotifyManager.isPlaying && index == selectedIndex ? "speaker.wave.2.fill" : "music.note",
                                title: track.name,
                                subtitle: track.artists.first?.name ?? "Unknown Artist",
                                isSelected: index == selectedIndex
                            )
                            .id(index)
                            
                            if index < spotifyManager.tracks.count - 1 {
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                    .padding(.leading, 50)
                            }
                        }
                        Spacer()
                    }
                }
                .onChange(of: selectedIndex) { newIndex in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
            .padding(.top, 10)
        }
    }
}
