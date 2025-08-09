import Foundation

struct Album: Codable, Identifiable, Hashable {
    let id: String
    let artistId: String
    let title: String
    let artistName: String
    let description: String?
    let genre: String?
    let mood: String?
    let style: String?
    let theme: String?
    let speed: String?
    let releaseDate: String?
    let label: String?
    let sales: String?
    let score: String?
    let scoreVotes: String?
    let thumb: String?
    let thumbHQ: String?
    let thumbHD: String?
    let spine: String?
    let cdArt: String?
    enum CodingKeys: String, CodingKey {
        case id = "idAlbum"
        case artistId = "idArtist"
        case title = "strAlbum"
        case artistName = "strArtist"
        case description = "strDescriptionEN"
        case genre = "strGenre"
        case mood = "strMood"
        case style = "strStyle"
        case theme = "strTheme"
        case speed = "strSpeed"
        case releaseDate = "intYearReleased"
        case label = "strLabel"
        case sales = "intSales"
        case score = "intScore"
        case scoreVotes = "intScoreVotes"
        case thumb = "strAlbumThumb"
        case thumbHQ = "strAlbumThumbHQ"
        case thumbHD = "strAlbumThumbBack"
        case spine = "strAlbumSpine"
        case cdArt = "strAlbumCDart"
    }
    var imageURL: String? {
        return thumbHD ?? thumbHQ ?? thumb
    }
    
    var smallImageURL: String? {
        return thumb ?? thumbHQ
    }
    
    var largeImageURL: String? {
        return thumbHD ?? thumbHQ ?? thumb
    }
    var formattedReleaseDate: String? {
        guard let releaseDate = releaseDate else { return nil }
        return releaseDate
    }
    var ratingPercentage: Double? {
        guard let scoreString = score,
              let score = Double(scoreString) else { return nil }
        return min(max(score / 10.0, 0.0), 1.0) // Normalize to 0-1 range
    }
}
struct AlbumResponse: Codable {
    let album: [Album]?
}

struct AlbumsResponse: Codable {
    let album: [Album]?
}
struct TrendingAlbumsResponse: Codable {
    let trending: [TrendingAlbum]?
}

struct TrendingAlbum: Codable, Identifiable {
    let id = UUID()
    let artistName: String
    let albumName: String
    let chartPosition: String?
    let imageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case artistName = "strArtist"
        case albumName = "strAlbum"
        case chartPosition = "intChartPlace"
        case imageURL = "strTrackThumb"
    }
}
