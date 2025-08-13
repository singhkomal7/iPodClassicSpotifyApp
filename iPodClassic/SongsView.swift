//
//  SongsView.swift
//  iPodClassic
//
//  Created by Komal Singh on 6/10/25.
//

import SwiftUI
import SpotifyiOS

struct SongsView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Songs...")
                    .foregroundColor(.white)
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .font(.custom("Px437_IBM_VGA8", size: 16))
                    .foregroundColor(.red)
            } else if spotifyManager.tracks.isEmpty {
                Text("No Songs Found")
                    .font(.custom("Px437_IBM_VGA8", size: 16))
                    .foregroundColor(.white)
            } else {
                List(spotifyManager.tracks) { track in
                    Button(action: {
                        spotifyManager.playTrack(uri: track.uri)
                    }) {
                        Text("\(track.name) - \(track.artists.first?.name ?? "Unknown")")
                            .font(.custom("Px437_IBM_VGA8", size: 16))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .background(Color.black)
        .onAppear {
            Task {
                isLoading = true
                await spotifyManager.fetchLikedSongs()
                isLoading = false
                if spotifyManager.tracks.isEmpty {
                    errorMessage = "No liked songs found. Like some songs in Spotify to see them here."
                }
            }
        }
    }
}
