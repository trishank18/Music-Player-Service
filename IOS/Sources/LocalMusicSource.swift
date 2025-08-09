import Foundation
import Combine
import MediaPlayer

class LocalMusicSource: MusicSourceProtocol {
    var sourceType: MusicSourceType = .local
    var isAvailable: Bool {
        return MPMediaLibrary.authorizationStatus() == .authorized
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        requestMediaLibraryAccess()
    }
    
    private func requestMediaLibraryAccess() {
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Media library access granted")
                case .denied, .restricted:
                    print("Media library access denied")
                case .notDetermined:
                    print("Media library access not determined")
                @unknown default:
                    print("Unknown media library access status")
                }
            }
        }
    }
    
    func searchArtists(query: String) -> AnyPublisher<[Artist], APIError> {
        return Future { promise in
            guard self.isAvailable else {
                promise(.failure(.unauthorized))
                return
            }
            
            let artistsQuery = MPMediaQuery.artists()
            artistsQuery.filterPredicates = [
                MPMediaPropertyPredicate(value: query, forProperty: MPMediaItemPropertyArtist, comparisonType: .contains)
            ]
            
            guard let collections = artistsQuery.collections else {
                promise(.success([]))
                return
            }
            
            let artists = collections.compactMap { collection -> Artist? in
                guard let representativeItem = collection.representativeItem else { return nil }
                return self.createArtist(from: representativeItem)
            }
            
            promise(.success(artists))
        }
        .eraseToAnyPublisher()
    }
    
    func searchAlbums(query: String) -> AnyPublisher<[Album], APIError> {
        return Future { promise in
            guard self.isAvailable else {
                promise(.failure(.unauthorized))
                return
            }
            
            let albumsQuery = MPMediaQuery.albums()
            albumsQuery.filterPredicates = [
                MPMediaPropertyPredicate(value: query, forProperty: MPMediaItemPropertyAlbumTitle, comparisonType: .contains)
            ]
            
            guard let collections = albumsQuery.collections else {
                promise(.success([]))
                return
            }
            
            let albums = collections.compactMap { collection -> Album? in
                guard let representativeItem = collection.representativeItem else { return nil }
                return self.createAlbum(from: representativeItem)
            }
            
            promise(.success(albums))
        }
        .eraseToAnyPublisher()
    }
    
    func searchTracks(query: String) -> AnyPublisher<[Track], APIError> {
        return Future { promise in
            guard self.isAvailable else {
                promise(.failure(.unauthorized))
                return
            }
            
            let tracksQuery = MPMediaQuery.songs()
            tracksQuery.filterPredicates = [
                MPMediaPropertyPredicate(value: query, forProperty: MPMediaItemPropertyTitle, comparisonType: .contains)
            ]
            
            guard let items = tracksQuery.items else {
                promise(.success([]))
                return
            }
            
            let tracks = items.compactMap { self.createTrack(from: $0) }
            promise(.success(tracks))
        }
        .eraseToAnyPublisher()
    }
    
    func searchAll(query: String) -> AnyPublisher<SearchResults, APIError> {
        let artistsPublisher = searchArtists(query: query)
        let albumsPublisher = searchAlbums(query: query)
        let tracksPublisher = searchTracks(query: query)
        
        return Publishers.Zip3(artistsPublisher, albumsPublisher, tracksPublisher)
            .map { artists, albums, tracks in
                SearchResults(artists: artists, albums: albums, tracks: tracks)
            }
            .eraseToAnyPublisher()
    }
    
    func getArtist(id: String) -> AnyPublisher<Artist?, APIError> {
        return Future { promise in
            guard self.isAvailable else {
                promise(.failure(.unauthorized))
                return
            }
            
            let query = MPMediaQuery.artists()
            query.filterPredicates = [
                MPMediaPropertyPredicate(value: id, forProperty: MPMediaItemPropertyArtistPersistentID)
            ]
            
            if let collection = query.collections?.first,
               let representativeItem = collection.representativeItem {
                let artist = self.createArtist(from: representativeItem)
                promise(.success(artist))
            } else {
                promise(.success(nil))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getArtistAlbums(artistId: String) -> AnyPublisher<[Album], APIError> {
        return Future { promise in
            guard self.isAvailable else {
                promise(.failure(.unauthorized))
                return
            }
            
            let query = MPMediaQuery.albums()
            query.filterPredicates = [
                MPMediaPropertyPredicate(value: artistId, forProperty: MPMediaItemPropertyArtistPersistentID)
            ]
            
            guard let collections = query.collections else {
                promise(.success([]))
                return
            }
            
            let albums = collections.compactMap { collection -> Album? in
                guard let representativeItem = collection.representativeItem else { return nil }
                return self.createAlbum(from: representativeItem)
            }
            
            promise(.success(albums))
        }
        .eraseToAnyPublisher()
    }
    
    func getArtistTopTracks(artistId: String) -> AnyPublisher<[Track], APIError> {
        return Future { promise in
            guard self.isAvailable else {
                promise(.failure(.unauthorized))
                return
            }
            
            let query = MPMediaQuery.songs()
            query.filterPredicates = [
                MPMediaPropertyPredicate(value: artistId, forProperty: MPMediaItemPropertyArtistPersistentID)
            ]
            
            guard let items = query.items else {
                promise(.success([]))
                return
            }
            let sortedItems = items.sorted { item1, item2 in
                return item1.playCount > item2.playCount
            }
            
            let topTracks = Array(sortedItems.prefix(10)).compactMap { self.createTrack(from: $0) }
            promise(.success(topTracks))
        }
        .eraseToAnyPublisher()
    }
    
    func getArtistMusicVideos(artistId: String) -> AnyPublisher<[MusicVideo], APIError> {
        return Just([])
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    func getAlbum(id: String) -> AnyPublisher<Album?, APIError> {
        return Future { promise in
            guard self.isAvailable else {
                promise(.failure(.unauthorized))
                return
            }
            
            let query = MPMediaQuery.albums()
            query.filterPredicates = [
                MPMediaPropertyPredicate(value: id, forProperty: MPMediaItemPropertyAlbumPersistentID)
            ]
            
            if let collection = query.collections?.first,
               let representativeItem = collection.representativeItem {
                let album = self.createAlbum(from: representativeItem)
                promise(.success(album))
            } else {
                promise(.success(nil))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getAlbumTracks(albumId: String) -> AnyPublisher<[Track], APIError> {
        return Future { promise in
            guard self.isAvailable else {
                promise(.failure(.unauthorized))
                return
            }
            
            let query = MPMediaQuery.songs()
            query.filterPredicates = [
                MPMediaPropertyPredicate(value: albumId, forProperty: MPMediaItemPropertyAlbumPersistentID)
            ]
            
            guard let items = query.items else {
                promise(.success([]))
                return
            }
            let sortedItems = items.sorted { item1, item2 in
                return item1.albumTrackNumber < item2.albumTrackNumber
            }
            
            let tracks = sortedItems.compactMap { self.createTrack(from: $0) }
            promise(.success(tracks))
        }
        .eraseToAnyPublisher()
    }
    
    func getTrack(id: String) -> AnyPublisher<Track?, APIError> {
        return Future { promise in
            guard self.isAvailable else {
                promise(.failure(.unauthorized))
                return
            }
            
            let query = MPMediaQuery.songs()
            query.filterPredicates = [
                MPMediaPropertyPredicate(value: id, forProperty: MPMediaItemPropertyPersistentID)
            ]
            
            if let item = query.items?.first {
                let track = self.createTrack(from: item)
                promise(.success(track))
            } else {
                promise(.success(nil))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getTrackAudioURL(trackId: String) -> AnyPublisher<URL?, APIError> {
        return getTrack(id: trackId)
            .map { track in
                return track?.preview != nil ? URL(string: track!.preview!) : nil
            }
            .eraseToAnyPublisher()
    }
    
    func getTrendingTracks() -> AnyPublisher<[Track], APIError> {
        return Future { promise in
            guard self.isAvailable else {
                promise(.failure(.unauthorized))
                return
            }
            
            let query = MPMediaQuery.songs()
            guard let items = query.items else {
                promise(.success([]))
                return
            }
            let sortedItems = items.sorted { item1, item2 in
                if item1.playCount == item2.playCount {
                    return item1.lastPlayedDate ?? Date.distantPast > item2.lastPlayedDate ?? Date.distantPast
                }
                return item1.playCount > item2.playCount
            }
            
            let trendingTracks = Array(sortedItems.prefix(20)).compactMap { self.createTrack(from: $0) }
            promise(.success(trendingTracks))
        }
        .eraseToAnyPublisher()
    }
    
    func getTrendingAlbums() -> AnyPublisher<[Album], APIError> {
        return Future { promise in
            guard self.isAvailable else {
                promise(.failure(.unauthorized))
                return
            }
            
            let query = MPMediaQuery.albums()
            guard let collections = query.collections else {
                promise(.success([]))
                return
            }
            let sortedCollections = collections.sorted { collection1, collection2 in
                let playCount1 = collection1.items.reduce(0) { $0 + $1.playCount }
                let playCount2 = collection2.items.reduce(0) { $0 + $1.playCount }
                return playCount1 > playCount2
            }
            
            let trendingAlbums = Array(sortedCollections.prefix(20)).compactMap { collection -> Album? in
                guard let representativeItem = collection.representativeItem else { return nil }
                return self.createAlbum(from: representativeItem)
            }
            
            promise(.success(trendingAlbums))
        }
        .eraseToAnyPublisher()
    }
    
    func getTrendingArtists() -> AnyPublisher<[Artist], APIError> {
        return Future { promise in
            guard self.isAvailable else {
                promise(.failure(.unauthorized))
                return
            }
            
            let query = MPMediaQuery.artists()
            guard let collections = query.collections else {
                promise(.success([]))
                return
            }
            let sortedCollections = collections.sorted { collection1, collection2 in
                let playCount1 = collection1.items.reduce(0) { $0 + $1.playCount }
                let playCount2 = collection2.items.reduce(0) { $0 + $1.playCount }
                return playCount1 > playCount2
            }
            
            let trendingArtists = Array(sortedCollections.prefix(20)).compactMap { collection -> Artist? in
                guard let representativeItem = collection.representativeItem else { return nil }
                return self.createArtist(from: representativeItem)
            }
            
            promise(.success(trendingArtists))
        }
        .eraseToAnyPublisher()
    }
    
    private func createArtist(from mediaItem: MPMediaItem) -> Artist {
        return Artist(
            id: String(mediaItem.artistPersistentID),
            name: mediaItem.artist ?? "Unknown Artist",
            biography: nil,
            formed: nil,
            genre: mediaItem.genre,
            mood: nil,
            style: nil,
            country: nil,
            website: nil,
            facebook: nil,
            twitter: nil,
            lastFMChart: nil,
            thumb: nil,
            logo: nil,
            fanart: nil,
            banner: nil
        )
    }
    
    private func createAlbum(from mediaItem: MPMediaItem) -> Album {
        return Album(
            id: String(mediaItem.albumPersistentID),
            artistId: String(mediaItem.artistPersistentID),
            title: mediaItem.albumTitle ?? "Unknown Album",
            artistName: mediaItem.albumArtist ?? mediaItem.artist ?? "Unknown Artist",
            description: nil,
            genre: mediaItem.genre,
            mood: nil,
            style: nil,
            theme: nil,
            speed: nil,
            releaseDate: mediaItem.releaseDate?.formatted(.dateTime.year()) ?? nil,
            label: nil,
            sales: nil,
            score: nil,
            scoreVotes: nil,
            thumb: nil,
            thumbHQ: nil,
            thumbHD: nil,
            spine: nil,
            cdArt: nil
        )
    }
    
    private func createTrack(from mediaItem: MPMediaItem) -> Track {
        return Track(
            id: String(mediaItem.persistentID),
            artistId: String(mediaItem.artistPersistentID),
            albumId: String(mediaItem.albumPersistentID),
            title: mediaItem.title ?? "Unknown Track",
            artistName: mediaItem.artist ?? "Unknown Artist",
            albumName: mediaItem.albumTitle,
            description: nil,
            genre: mediaItem.genre,
            mood: nil,
            style: nil,
            theme: nil,
            duration: String(Int(mediaItem.playbackDuration * 1000)), // Convert to milliseconds
            trackNumber: String(mediaItem.albumTrackNumber),
            lyrics: nil,
            musicVideo: nil,
            score: nil,
            scoreVotes: nil,
            thumb: nil,
            preview: mediaItem.assetURL?.absoluteString // Local file URL
        )
    }
}
