import Foundation
import Combine

class AudioDBService: ObservableObject {
    static let shared = AudioDBService()
    
    private let baseURL = "https://www.theaudiodb.com/api/v1/json/2"
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    func searchArtist(name: String) -> AnyPublisher<[Artist], APIError> {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search.php?s=\(encodedName)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return performRequest(url: url, responseType: ArtistResponse.self)
            .map { $0.artists ?? [] }
            .eraseToAnyPublisher()
    }
    func getArtist(byId id: String) -> AnyPublisher<Artist?, APIError> {
        guard let url = URL(string: "\(baseURL)/artist.php?i=\(id)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return performRequest(url: url, responseType: ArtistResponse.self)
            .map { $0.artists?.first }
            .eraseToAnyPublisher()
    }
    func getArtist(byMusicBrainzId id: String) -> AnyPublisher<Artist?, APIError> {
        guard let url = URL(string: "\(baseURL)/artist-mb.php?i=\(id)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return performRequest(url: url, responseType: ArtistResponse.self)
            .map { $0.artists?.first }
            .eraseToAnyPublisher()
    }
    func getAlbums(forArtistId artistId: String) -> AnyPublisher<[Album], APIError> {
        guard let url = URL(string: "\(baseURL)/album.php?i=\(artistId)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return performRequest(url: url, responseType: AlbumsResponse.self)
            .map { $0.album ?? [] }
            .eraseToAnyPublisher()
    }
    func getAlbum(byId albumId: String) -> AnyPublisher<Album?, APIError> {
        guard let url = URL(string: "\(baseURL)/album.php?m=\(albumId)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return performRequest(url: url, responseType: AlbumResponse.self)
            .map { $0.album?.first }
            .eraseToAnyPublisher()
    }
    func getTracks(forAlbumId albumId: String) -> AnyPublisher<[Track], APIError> {
        guard let url = URL(string: "\(baseURL)/track.php?m=\(albumId)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return performRequest(url: url, responseType: TracksResponse.self)
            .map { $0.track ?? [] }
            .eraseToAnyPublisher()
    }
    func getTrack(byId trackId: String) -> AnyPublisher<Track?, APIError> {
        guard let url = URL(string: "\(baseURL)/track.php?h=\(trackId)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return performRequest(url: url, responseType: TrackResponse.self)
            .map { $0.track?.first }
            .eraseToAnyPublisher()
    }
    func getTopTracks(forArtist artistName: String) -> AnyPublisher<[Track], APIError> {
        guard let encodedName = artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/track-top10.php?s=\(encodedName)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return performRequest(url: url, responseType: TracksResponse.self)
            .map { $0.track ?? [] }
            .eraseToAnyPublisher()
    }
    func getMusicVideos(forArtistId artistId: String) -> AnyPublisher<[MusicVideo], APIError> {
        guard let url = URL(string: "\(baseURL)/mvid.php?i=\(artistId)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return performRequest(url: url, responseType: MusicVideoResponse.self)
            .map { $0.mvids ?? [] }
            .eraseToAnyPublisher()
    }
    func getTrendingMusic(country: String = "us", type: String = "itunes", format: String = "albums") -> AnyPublisher<[TrendingAlbum], APIError> {
        guard let url = URL(string: "\(baseURL)/trending.php?country=\(country)&type=\(type)&format=\(format)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return performRequest(url: url, responseType: TrendingAlbumsResponse.self)
            .map { $0.trending ?? [] }
            .eraseToAnyPublisher()
    }
    
    private func performRequest<T: Codable>(url: URL, responseType: T.Type) -> AnyPublisher<T, APIError> {
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: responseType, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    return APIError.decodingError
                } else {
                    return APIError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }
    func searchEverything(for artistName: String) -> AnyPublisher<SearchResults, APIError> {
        let artistSearch = searchArtist(name: artistName)
        
        return artistSearch
            .flatMap { artists -> AnyPublisher<SearchResults, APIError> in
                guard let firstArtist = artists.first else {
                    return Just(SearchResults(artists: [], albums: [], tracks: []))
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                }
                
                let albumsPublisher = self.getAlbums(forArtistId: firstArtist.id)
                let topTracksPublisher = self.getTopTracks(forArtist: artistName)
                
                return Publishers.Zip3(
                    Just(artists).setFailureType(to: APIError.self),
                    albumsPublisher,
                    topTracksPublisher
                )
                .map { artists, albums, tracks in
                    SearchResults(artists: artists, albums: albums, tracks: tracks)
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

struct SearchResults {
    let artists: [Artist]
    let albums: [Album]
    let tracks: [Track]
    
    var isEmpty: Bool {
        return artists.isEmpty && albums.isEmpty && tracks.isEmpty
    }
    
    var totalResults: Int {
        return artists.count + albums.count + tracks.count
    }
}
