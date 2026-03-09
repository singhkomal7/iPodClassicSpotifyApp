//
//  Config.swift
//  iPodClassic
//
//  Created by Komal Singh on 6/5/25.
//

import Foundation

struct Config {
    static let clientID = "87c724c9210a4cdfa70a227860c3e347"
    static let redirectURI = URL(string: "kommiipodclassic://spotify-login-callback")!
    static let clientSecret = ""
    
    // Network timeout settings
    static let defaultTimeoutInterval: TimeInterval = 30.0
    static let connectionRetryDelay: TimeInterval = 2.0
    static let maxRetryAttempts: Int = 3
    
    // Spotify-specific settings
    static let requiredScopes: [String] = [
        "app-remote-control",
        "playlist-read-private",
        "user-library-read", 
        "user-top-read"
    ]
}
