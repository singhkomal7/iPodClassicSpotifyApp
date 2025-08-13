//
//  ArtistsView.swift
//  iPodClassic
//
//  Created by Komal Singh on 6/10/25.
//

import SwiftUI

struct ArtistsView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Artists...")
                    .foregroundColor(.white)
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .font(.custom("Px437_IBM_VGA8", size: 16))
                    .foregroundColor(.red)
            } else if spotifyManager.artists.isEmpty {
                VStack(spacing: 8) {
                    Text("No Artists Found")
                        .font(.custom("Px437_IBM_VGA8", size: 16))
                        .foregroundColor(.white)
                    Text("Listen to music in Spotify to see your top artists")
                        .font(.custom("Px437_IBM_VGA8", size: 12))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            } else {
                List(spotifyManager.artists) { artist in
                    NavigationLink(destination: ArtistTracksView(artistId: artist.id)) {
                        Text(artist.name)
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
                await spotifyManager.fetchTopArtists()
                isLoading = false
                if spotifyManager.artists.isEmpty {
                    errorMessage = "No artists loaded. Check logs for errors."
                }
            }
        }
    }
}
