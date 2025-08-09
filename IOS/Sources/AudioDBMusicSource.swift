import Foundation
import Combine

class AudioDBMusicSource: MusicSourceProtocol {
    var sourceType: MusicSourceType = .audioDB
    var isAvailable: Bool = true
    
    private let audioDBService = AudioDBService.shared
    func searchArtists(query: String) -> AnyPublisher<[Artist], APIError> {
        return audioDBService.searchArtist(name: query)
    }
    
    func searchAlbums(query: String) -> AnyPublisher<[Album], APIError> {
        return searchArtists(query: query)
            .flatMap { artists -> AnyPublisher<[Album], APIError> in
                guard let firstArtist = artists.first else {
                    return Just([])
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                }
                return self.getArtistAlbums(artistId: firstArtist.id)
            }
            .eraseToAnyPublisher()
    }
    
    func searchTracks(query: String) -> AnyPublisher<[Track], APIError> {
        return searchArtists(query: query)
            .flatMap { artists -> AnyPublisher<[Track], APIError> in
                guard let firstArtist = artists.first else {
                    return Just([])
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                }
                return self.getArtistTopTracks(artistId: firstArtist.id)
            }
            .eraseToAnyPublisher()
    }
    
    func searchAll(query: String) -> AnyPublisher<SearchResults, APIError> {
        return audioDBService.searchEverything(for: query)
    }
    func getArtist(id: String) -> AnyPublisher<Artist?, APIError> {
        return audioDBService.getArtist(byId: id)
    }
    
    func getArtistAlbums(artistId: String) -> AnyPublisher<[Album], APIError> {
        return audioDBService.getAlbums(forArtistId: artistId)
    }
    
    func getArtistTopTracks(artistId: String) -> AnyPublisher<[Track], APIError> {
        return getArtist(id: artistId)
            .flatMap { artist -> AnyPublisher<[Track], APIError> in
                guard let artist = artist else {
                    return Just([])
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                }
                return self.audioDBService.getTopTracks(forArtist: artist.name)
            }
            .eraseToAnyPublisher()
    }
    
    func getArtistMusicVideos(artistId: String) -> AnyPublisher<[MusicVideo], APIError> {
        return audioDBService.getMusicVideos(forArtistId: artistId)
    }
    func getAlbum(id: String) -> AnyPublisher<Album?, APIError> {
        return audioDBService.getAlbum(byId: id)
    }
    
    func getAlbumTracks(albumId: String) -> AnyPublisher<[Track], APIError> {
        return audioDBService.getTracks(forAlbumId: albumId)
    }
    func getTrack(id: String) -> AnyPublisher<Track?, APIError> {
        return audioDBService.getTrack(byId: id)
    }
    
    func getTrackAudioURL(trackId: String) -> AnyPublisher<URL?, APIError> {
        return getTrack(id: trackId)
            .map { track in
                guard let previewString = track?.preview else { return nil }
                return URL(string: previewString)
            }
            .eraseToAnyPublisher()
    }
    func getTrendingTracks() -> AnyPublisher<[Track], APIError> {
        return getTrendingAlbums()
            .flatMap { albums -> AnyPublisher<[Track], APIError> in
                guard !albums.isEmpty else {
                    return Just([])
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                }
                let albumPublishers = Array(albums.prefix(3)).map { album in
                    self.getAlbumTracks(albumId: album.id)
                }
                
                return Publishers.MergeMany(albumPublishers)
                    .collect()
                    .map { trackArrays in
                        let allTracks = trackArrays.flatMap { $0 }
                        return Array(allTracks.prefix(20))
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func getTrendingAlbums() -> AnyPublisher<[Album], APIError> {
        return audioDBService.getTrendingMusic()
            .map { trendingAlbums in
                return trendingAlbums.compactMap { trending in
                    Album(
                        id: UUID().uuidString, // Generate a UUID since trending doesn't have IDs
                        artistId: "", // Unknown from trending data
                        title: trending.albumName,
                        artistName: trending.artistName,
                        description: nil,
                        genre: nil,
                        mood: nil,
                        style: nil,
                        theme: nil,
                        speed: nil,
                        releaseDate: nil,
                        label: nil,
                        sales: nil,
                        score: nil,
                        scoreVotes: nil,
                        thumb: trending.imageURL,
                        thumbHQ: nil,
                        thumbHD: nil,
                        spine: nil,
                        cdArt: nil
                    )
                }
            }
            .eraseToAnyPublisher()
    }
    
    func getTrendingArtists() -> AnyPublisher<[Artist], APIError> {
        return getTrendingAlbums()
            .map { albums in
                var uniqueArtists: [String: Artist] = [:]
                
                for album in albums {
                    if uniqueArtists[album.artistName] == nil {
                        uniqueArtists[album.artistName] = Artist(
                            id: UUID().uuidString,
                            name: album.artistName,
                            biography: nil,
                            formed: nil,
                            genre: album.genre,
                            mood: nil,
                            style: nil,
                            country: nil,
                            website: nil,
                            facebook: nil,
                            twitter: nil,
                            lastFMChart: nil,
                            thumb: album.thumb,
                            logo: nil,
                            fanart: nil,
                            banner: nil
                        )
                    }
                }
                
                return Array(uniqueArtists.values)
            }
            .eraseToAnyPublisher()
    }
    func getRecommendations(basedOn track: Track) -> AnyPublisher<[Track], APIError> {
        return getArtistTopTracks(artistId: track.artistId ?? "")
            .map { tracks in
                tracks.filter { $0.id != track.id }
            }
            .eraseToAnyPublisher()
    }
    
    func getRecommendations(basedOn artist: Artist) -> AnyPublisher<[Track], APIError> {
        return getArtistTopTracks(artistId: artist.id)
    }
    
    func getRecommendations(basedOn album: Album) -> AnyPublisher<[Track], APIError> {
        return getAlbumTracks(albumId: album.id)
    }
}
