import Foundation
import SwiftUI

enum PlaybackState {
    case stopped
    case playing
    case paused
    case buffering
    case error(PlaybackError)
}

enum RepeatMode: String, CaseIterable {
    case off = "off"
    case single = "single"
    case all = "all"
    
    var iconName: String {
        switch self {
        case .off:
            return "repeat"
        case .single:
            return "repeat.1"
        case .all:
            return "repeat"
        }
    }
    
    var description: String {
        switch self {
        case .off:
            return "Repeat Off"
        case .single:
            return "Repeat One"
        case .all:
            return "Repeat All"
        }
    }
}

enum ShuffleMode: String, CaseIterable {
    case off = "off"
    case on = "on"
    
    var iconName: String {
        return "shuffle"
    }
    
    var description: String {
        switch self {
        case .off:
            return "Shuffle Off"
        case .on:
            return "Shuffle On"
        }
    }
}

enum PlaybackError: Error, LocalizedError {
    case networkError
    case audioSessionError
    case fileNotFound
    case invalidURL
    case decodingError
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error"
        case .audioSessionError:
            return "Audio session configuration error"
        case .fileNotFound:
            return "Audio file not found"
        case .invalidURL:
            return "Invalid audio URL"
        case .decodingError:
            return "Audio decoding error"
        case .unknownError(let message):
            return message
        }
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(Int)
    case rateLimited
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error: \(code)"
        case .rateLimited:
            return "Rate limit exceeded"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

enum MusicSourceType: String, CaseIterable {
    case local = "local"
    case audioDB = "audiodb"
    case spotifyMock = "spotify_mock"
    
    var displayName: String {
        switch self {
        case .local:
            return "Local Music"
        case .audioDB:
            return "TheAudioDB"
        case .spotifyMock:
            return "Spotify (Mock)"
        }
    }
    
    var iconName: String {
        switch self {
        case .local:
            return "music.note"
        case .audioDB:
            return "globe"
        case .spotifyMock:
            return "music.mic"
        }
    }
}

enum SearchCategory: String, CaseIterable {
    case all = "all"
    case artists = "artists"
    case albums = "albums"
    case tracks = "tracks"
    
    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .artists:
            return "Artists"
        case .albums:
            return "Albums"
        case .tracks:
            return "Tracks"
        }
    }
    
    var iconName: String {
        switch self {
        case .all:
            return "magnifyingglass"
        case .artists:
            return "person.circle"
        case .albums:
            return "opticaldisc"
        case .tracks:
            return "music.note"
        }
    }
}

enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var data: T? {
        if case .loaded(let data) = self {
            return data
        }
        return nil
    }
    
    var error: Error? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
}

enum ViewState {
    case loading
    case loaded
    case empty
    case error(String)
}

enum AnimationType {
    case slideIn
    case slideOut
    case fadeIn
    case fadeOut
    case scale
    case rotate
    case bounce
    
    var animation: Animation {
        switch self {
        case .slideIn, .slideOut:
            return .easeInOut(duration: 0.3)
        case .fadeIn, .fadeOut:
            return .easeInOut(duration: 0.25)
        case .scale:
            return .spring(response: 0.4, dampingFraction: 0.6)
        case .rotate:
            return .linear(duration: 1.0)
        case .bounce:
            return .spring(response: 0.5, dampingFraction: 0.5)
        }
    }
}

enum ThemeMode: String, CaseIterable {
    case dark = "dark"
    case light = "light"
    case auto = "auto"
    
    var displayName: String {
        switch self {
        case .dark:
            return "Dark"
        case .light:
            return "Light"
        case .auto:
            return "Auto"
        }
    }
    
    var iconName: String {
        switch self {
        case .dark:
            return "moon.fill"
        case .light:
            return "sun.max.fill"
        case .auto:
            return "circle.lefthalf.filled"
        }
    }
}
