import Foundation

struct Track: Codable, Identifiable, Hashable {
    let id: String
    let artistId: String?
    let albumId: String?
    let title: String
    let artistName: String
    let albumName: String?
    let description: String?
    let genre: String?
    let mood: String?
    let style: String?
    let theme: String?
    let duration: String?
    let trackNumber: String?
    let lyrics: String?
    let musicVideo: String?
    let score: String?
    let scoreVotes: String?
    let thumb: String?
    let preview: String? // 30-second preview URL if available
    enum CodingKeys: String, CodingKey {
        case id = "idTrack"
        case artistId = "idArtist"
        case albumId = "idAlbum"
        case title = "strTrack"
        case artistName = "strArtist"
        case albumName = "strAlbum"
        case description = "strDescriptionEN"
        case genre = "strGenre"
        case mood = "strMood"
        case style = "strStyle"
        case theme = "strTheme"
        case duration = "intDuration"
        case trackNumber = "intTrackNumber"
        case lyrics = "strLyrics"
        case musicVideo = "strMusicVid"
        case score = "intScore"
        case scoreVotes = "intScoreVotes"
        case thumb = "strTrackThumb"
        case preview = "strTrackPreview"
    }
    var formattedDuration: String {
        guard let durationString = duration,
              let durationMS = Int(durationString) else {
            return "0:00"
        }
        
        let seconds = durationMS / 1000
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    var durationInSeconds: TimeInterval {
        guard let durationString = duration,
              let durationMS = Double(durationString) else {
            return 0
        }
        return durationMS / 1000.0
    }
    
    var trackNumberInt: Int? {
        guard let trackNumber = trackNumber else { return nil }
        return Int(trackNumber)
    }
    
    var rating: Double? {
        guard let scoreString = score,
              let score = Double(scoreString) else { return nil }
        return min(max(score / 10.0, 0.0), 1.0) // Normalize to 0-1 range
    }
    
    var hasLyrics: Bool {
        return lyrics != nil && !lyrics!.isEmpty
    }
    
    var hasMusicVideo: Bool {
        return musicVideo != nil && !musicVideo!.isEmpty
    }
    
    var hasPreview: Bool {
        return preview != nil && !preview!.isEmpty
    }
}
struct TrackResponse: Codable {
    let track: [Track]?
}

struct TracksResponse: Codable {
    let track: [Track]?
}
struct MusicVideo: Codable, Identifiable {
    let id: String
    let artistId: String
    let trackName: String
    let artistName: String
    let albumName: String?
    let description: String?
    let videoURL: String?
    let thumb: String?
    let director: String?
    let company: String?
    let budget: String?
    let views: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "idVideo"
        case artistId = "idArtist"
        case trackName = "strTrack"
        case artistName = "strArtist"
        case albumName = "strAlbum"
        case description = "strDescriptionEN"
        case videoURL = "strVideoEmbed"
        case thumb = "strVideoThumb"
        case director = "strVideoDirector"
        case company = "strVideoCompany"
        case budget = "intVideoBudget"
        case views = "intVideoViews"
    }
}

struct MusicVideoResponse: Codable {
    let mvids: [MusicVideo]?
}
struct PlaybackState {
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var isPlaying: Bool = false
    var isBuffering: Bool = false
    var volume: Float = 1.0
    var playbackRate: Float = 1.0
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    var remainingTime: TimeInterval {
        return max(0, duration - currentTime)
    }
    
    var formattedCurrentTime: String {
        return formatTime(currentTime)
    }
    
    var formattedDuration: String {
        return formatTime(duration)
    }
    
    var formattedRemainingTime: String {
        return "-" + formatTime(remainingTime)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
