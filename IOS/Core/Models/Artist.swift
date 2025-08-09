import Foundation

struct Artist: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let biography: String?
    let formed: String?
    let genre: String?
    let mood: String?
    let style: String?
    let country: String?
    let website: String?
    let facebook: String?
    let twitter: String?
    let lastFMChart: String?
    let thumb: String?
    let logo: String?
    let fanart: String?
    let banner: String?
    enum CodingKeys: String, CodingKey {
        case id = "idArtist"
        case name = "strArtist"
        case biography = "strBiographyEN"
        case formed = "intFormedYear"
        case genre = "strGenre"
        case mood = "strMood"
        case style = "strStyle"
        case country = "strCountry"
        case website = "strWebsite"
        case facebook = "strFacebook"
        case twitter = "strTwitter"
        case lastFMChart = "strLastFMChart"
        case thumb = "strArtistThumb"
        case logo = "strArtistLogo"
        case fanart = "strArtistFanart"
        case banner = "strArtistBanner"
    }
    var socialLinks: [SocialLink] {
        var links: [SocialLink] = []
        
        if let website = website, !website.isEmpty {
            links.append(SocialLink(type: .website, url: website))
        }
        if let facebook = facebook, !facebook.isEmpty {
            links.append(SocialLink(type: .facebook, url: facebook))
        }
        if let twitter = twitter, !twitter.isEmpty {
            links.append(SocialLink(type: .twitter, url: twitter))
        }
        if let lastFM = lastFMChart, !lastFM.isEmpty {
            links.append(SocialLink(type: .lastFM, url: lastFM))
        }
        
        return links
    }
    var imageURL: String? {
        return thumb ?? logo ?? fanart
    }
    
    var bannerImageURL: String? {
        return banner ?? fanart
    }
}
struct ArtistResponse: Codable {
    let artists: [Artist]?
}

struct SocialLink: Identifiable, Hashable {
    let id = UUID()
    let type: SocialLinkType
    let url: String
}

enum SocialLinkType: String, CaseIterable {
    case website = "Website"
    case facebook = "Facebook"
    case twitter = "Twitter"
    case lastFM = "Last.fm"
    
    var iconName: String {
        switch self {
        case .website:
            return "globe"
        case .facebook:
            return "f.square"
        case .twitter:
            return "t.square"
        case .lastFM:
            return "music.note"
        }
    }
    
    var color: String {
        switch self {
        case .website:
            return "#FFFFFF"
        case .facebook:
            return "#FFFFFF"
        case .twitter:
            return "#FFFFFF"
        case .lastFM:
            return "#FFFFFF"
        }
    }
}
