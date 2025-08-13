//
//  PlaylistsView.swift
//  iPodClassic
//
//  Created by Komal Singh on 6/10/25.
//

import SwiftUI
import SpotifyiOS

struct PlaylistsView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @State private var selectedIndex = 0
    @State private var selectedPlaylist: Playlist?
    @State private var showingTracks = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        iPodLayoutView(
            content: {
                playlistsScreenContent
            },
            onMenuPress: {
                print("🔙 Menu pressed - going back")
                presentationMode.wrappedValue.dismiss()
            },
            onPlayPausePress: {
                print("⏯️ Play/Pause pressed")
                if spotifyManager.isPlaying {
                    spotifyManager.pause()
                } else {
                    spotifyManager.pause()
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
                guard !spotifyManager.playlists.isEmpty else { return }
                print("✅ Center pressed - selecting playlist: \(spotifyManager.playlists[selectedIndex].name)")
                selectedPlaylist = spotifyManager.playlists[selectedIndex]
                showingTracks = true
            },
            onScrollUp: {
                if selectedIndex > 0 {
                    selectedIndex -= 1
                    if !spotifyManager.playlists.isEmpty {
                        print("⬆️ Scroll up - selected: \(spotifyManager.playlists[selectedIndex].name)")
                    }
                }
            },
            onScrollDown: {
                if selectedIndex < spotifyManager.playlists.count - 1 {
                    selectedIndex += 1
                    if !spotifyManager.playlists.isEmpty {
                        print("⬇️ Scroll down - selected: \(spotifyManager.playlists[selectedIndex].name)")
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
        .sheet(isPresented: $showingTracks) {
            if let playlist = selectedPlaylist {
                PlaylistTracksView(playlistId: playlist.id)
                    .environmentObject(spotifyManager)
            }
        }
        .onAppear {
            if !spotifyManager.playlists.isEmpty {
                selectedIndex = 0
            }
        }
    }
    
    private var playlistsScreenContent: some View {
        VStack(spacing: 0) {
            iPodScreenHeader(
                title: "Playlists",
                subtitle: "\(spotifyManager.playlists.count) playlists"
            )
            
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 0) {
                    if spotifyManager.playlists.isEmpty {
                        VStack {
                            Text("No Playlists")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            Text("Create playlists in Spotify")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ForEach(Array(spotifyManager.playlists.enumerated()), id: \.offset) { index, playlist in
                            iPodListItem(
                                icon: "music.note.list",
                                title: playlist.name,
                                subtitle: playlist.trackCount != nil ? "\(playlist.trackCount!) songs" : nil,
                                isSelected: index == selectedIndex
                            )
                            .id(index)
                            
                            if index < spotifyManager.playlists.count - 1 {
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

