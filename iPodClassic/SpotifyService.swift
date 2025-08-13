import SwiftUI
import Foundation

struct SpotifyService {
    private let baseURL = "https://api.spotify.com/v1"
    private let accountsURL = "https://accounts.spotify.com/api/token"

    func fetchPlaylists(accessToken: String) async throws -> [Playlist] {
        guard let url = URL(string: "\(baseURL)/me/playlists?limit=50") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = Config.defaultTimeoutInterval
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Playlists API error: Status \(httpResponse.statusCode)")
            if httpResponse.statusCode == 401 {
                throw URLError(.userAuthenticationRequired)
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let playlistResponse = try decoder.decode(PlaylistResponse.self, from: data)
        return playlistResponse.items
    }

    func fetchLibraryTracks(accessToken: String) async throws -> [Track] {
        guard let url = URL(string: "\(baseURL)/me/tracks?limit=50") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = Config.defaultTimeoutInterval
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Library tracks API error: Status \(httpResponse.statusCode)")
            if httpResponse.statusCode == 401 {
                throw URLError(.userAuthenticationRequired)
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let trackResponse = try decoder.decode(TrackResponse.self, from: data)
        return trackResponse.items.map { $0.track }
    }
    
    func fetchLikedSongs(accessToken: String) async throws -> [Track] {
        guard let url = URL(string: "\(baseURL)/me/tracks?limit=50") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = Config.defaultTimeoutInterval
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Liked songs API error: Status \(httpResponse.statusCode)")
            if httpResponse.statusCode == 401 {
                throw URLError(.userAuthenticationRequired)
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let trackResponse = try decoder.decode(TrackResponse.self, from: data)
        return trackResponse.items.map { $0.track }
    }

    func fetchPlaylistTracks(playlistId: String, accessToken: String) async throws -> [Track] {
        guard let url = URL(string: "\(baseURL)/playlists/\(playlistId)/tracks?limit=50") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = Config.defaultTimeoutInterval
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Playlist tracks API error: Status \(httpResponse.statusCode)")
            if httpResponse.statusCode == 401 {
                throw URLError(.userAuthenticationRequired)
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let trackResponse = try decoder.decode(TrackResponse.self, from: data)
        return trackResponse.items.map { $0.track }
    }

    func fetchTopArtists(accessToken: String) async throws -> [Artist] {
        guard let url = URL(string: "\(baseURL)/me/top/artists?limit=50") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = Config.defaultTimeoutInterval
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Top artists API error: Status \(httpResponse.statusCode)")
            if httpResponse.statusCode == 401 {
                throw URLError(.userAuthenticationRequired)
            } else if httpResponse.statusCode == 403 {
                print("❌ Access forbidden - check Spotify app permissions")
                throw URLError(.noPermissionsToReadFile)
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let artistResponse = try decoder.decode(ArtistResponse.self, from: data)
        return artistResponse.items
    }

    func fetchArtistTopTracks(artistId: String, accessToken: String) async throws -> [Track] {
        guard let url = URL(string: "\(baseURL)/artists/\(artistId)/top-tracks?market=US") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        let trackResponse = try decoder.decode(ArtistTrackResponse.self, from: data)
        return trackResponse.tracks
    }

    func fetchAlbums(accessToken: String) async throws -> [Album] {
        guard let url = URL(string: "\(baseURL)/me/albums?limit=50") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = Config.defaultTimeoutInterval
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Albums API error: Status \(httpResponse.statusCode)")
            if httpResponse.statusCode == 401 {
                throw URLError(.userAuthenticationRequired)
            } else if httpResponse.statusCode == 403 {
                print("❌ Access forbidden - check Spotify app permissions")
                throw URLError(.noPermissionsToReadFile)
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let albumResponse = try decoder.decode(AlbumResponse.self, from: data)
        return albumResponse.items.map { $0.album }
    }

    func fetchAlbumTracks(albumId: String, accessToken: String) async throws -> [Track] {
        guard let url = URL(string: "\(baseURL)/albums/\(albumId)/tracks?limit=50") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        let trackResponse = try decoder.decode(AlbumTrackResponse.self, from: data)
        return trackResponse.items
    }

    func refreshAccessToken(refreshToken: String) async throws -> String {
        guard let url = URL(string: accountsURL) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let clientString = "\(Config.clientID):\(Config.clientSecret)"
        guard let clientData = clientString.data(using: .utf8) else {
            throw URLError(.cannotCreateFile)
        }
        request.setValue("Basic \(clientData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]
        guard let bodyString = bodyComponents.percentEncodedQuery, let bodyData = bodyString.data(using: .utf8) else {
            throw URLError(.cannotCreateFile)
        }
        request.httpBody = bodyData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accessToken = json?["access_token"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        return accessToken
    }
}


struct PlaylistResponse: Codable {
    let items: [Playlist]
}

struct Playlist: Codable, Identifiable {
    let id: String
    let name: String
    let tracks: PlaylistTracks?
    
    var trackCount: Int? {
        return tracks?.total
    }
}

struct PlaylistTracks: Codable {
    let total: Int
}

struct TrackResponse: Codable {
    let items: [TrackItem]
}

struct TrackItem: Codable {
    let track: Track
}

struct Track: Codable, Identifiable {
    let id: String
    let name: String
    let artists: [Artist]
    let uri: String
    let album: TrackAlbum?
}

struct TrackAlbum: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]?
}

struct SpotifyImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
}

struct ArtistResponse: Codable {
    let items: [Artist]
}

struct Artist: Codable, Identifiable {
    let id: String
    let name: String
}

struct ArtistTrackResponse: Codable {
    let tracks: [Track]
}

struct AlbumResponse: Codable {
    let items: [AlbumItem]
}

struct AlbumItem: Codable {
    let album: Album
}

struct Album: Codable, Identifiable {
    let id: String
    let name: String
    let artists: [Artist]
}

struct AlbumTrackResponse: Codable {
    let items: [Track]
}
