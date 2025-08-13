//
//  AlbumsView.swift
//  iPodClassic
//
//  Created by Komal Singh on 6/10/25.
//

import SwiftUI

struct AlbumsView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Albums...")
                    .foregroundColor(.white)
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .font(.custom("Px437_IBM_VGA8", size: 16))
                    .foregroundColor(.red)
            } else if spotifyManager.albums.isEmpty {
                VStack(spacing: 8) {
                    Text("No Albums Found")
                        .font(.custom("Px437_IBM_VGA8", size: 16))
                        .foregroundColor(.white)
                    Text("Save albums in your Spotify library to see them here")
                        .font(.custom("Px437_IBM_VGA8", size: 12))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            } else {
                List(spotifyManager.albums) { album in
                    NavigationLink(destination: AlbumTracksView(albumId: album.id)) {
                        Text("\(album.name) - \(album.artists.first?.name ?? "Unknown")")
                            .font(.custom("Px437_IBM_VGA8", size: 18))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .background(Color.black)
        .onAppear {
            Task {
                isLoading = true
                await spotifyManager.fetchAlbums()
                isLoading = false
                if spotifyManager.albums.isEmpty {
                    errorMessage = "No albums loaded. Check logs for errors."
                }
            }
        }
    }
}
