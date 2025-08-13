//
//  AlbumTracksView.swift
//  iPodClassic
//
//  Created by Komal Singh on 6/10/25.
//

import SwiftUI

struct AlbumTracksView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    let albumId: String
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Tracks...")
                    .foregroundColor(.white)
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .font(.custom("Px437_IBM_VGA8", size: 16))
                    .foregroundColor(.red)
            } else if spotifyManager.tracks.isEmpty {
                Text("No Tracks Found")
                    .font(.custom("Px437_IBM_VGA8", size: 16))
                    .foregroundColor(.white)
            } else {
                List(spotifyManager.tracks) { track in
                    Button(action: {
                        spotifyManager.playTrack(uri: track.uri)
                    }) {
                        Text("\(track.name)")
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
                await spotifyManager.fetchAlbumTracks(albumId: albumId)
                isLoading = false
                if spotifyManager.tracks.isEmpty {
                    errorMessage = "No tracks loaded. Check logs for errors."
                }
            }
        }
    }
}
