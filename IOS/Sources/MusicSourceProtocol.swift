import Foundation
import Combine

protocol MusicSourceProtocol {
    var sourceType: MusicSourceType { get }
    var isAvailable: Bool { get }
    
    func searchArtists(query: String) -> AnyPublisher<[Artist], APIError>
    func searchAlbums(query: String) -> AnyPublisher<[Album], APIError>
    func searchTracks(query: String) -> AnyPublisher<[Track], APIError>
    func searchAll(query: String) -> AnyPublisher<SearchResults, APIError>
    
    func getArtist(id: String) -> AnyPublisher<Artist?, APIError>
    func getArtistAlbums(artistId: String) -> AnyPublisher<[Album], APIError>
    func getArtistTopTracks(artistId: String) -> AnyPublisher<[Track], APIError>
    func getArtistMusicVideos(artistId: String) -> AnyPublisher<[MusicVideo], APIError>
    
    func getAlbum(id: String) -> AnyPublisher<Album?, APIError>
    func getAlbumTracks(albumId: String) -> AnyPublisher<[Track], APIError>
    
    func getTrack(id: String) -> AnyPublisher<Track?, APIError>
    func getTrackAudioURL(trackId: String) -> AnyPublisher<URL?, APIError>
    
    func getTrendingTracks() -> AnyPublisher<[Track], APIError>
    func getTrendingAlbums() -> AnyPublisher<[Album], APIError>
    func getTrendingArtists() -> AnyPublisher<[Artist], APIError>
    
    func getRecommendations(basedOn track: Track) -> AnyPublisher<[Track], APIError>
    func getRecommendations(basedOn artist: Artist) -> AnyPublisher<[Track], APIError>
    func getRecommendations(basedOn album: Album) -> AnyPublisher<[Track], APIError>
}

extension MusicSourceProtocol {
    var isAvailable: Bool { return true }
    func getArtistMusicVideos(artistId: String) -> AnyPublisher<[MusicVideo], APIError> {
        return Just([])
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    func getRecommendations(basedOn track: Track) -> AnyPublisher<[Track], APIError> {
        return Just([])
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    func getRecommendations(basedOn artist: Artist) -> AnyPublisher<[Track], APIError> {
        return Just([])
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    func getRecommendations(basedOn album: Album) -> AnyPublisher<[Track], APIError> {
        return Just([])
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
}
class MusicSourceManager: ObservableObject {
    static let shared = MusicSourceManager()
    
    @Published var currentSource: MusicSourceProtocol
    @Published var availableSources: [MusicSourceProtocol] = []
    
    private init() {
        let audioDBSource = AudioDBMusicSource()
        self.currentSource = audioDBSource
        self.availableSources = [
            audioDBSource,
            LocalMusicSource(),
            SpotifyMockSource()
        ]
    }
    
    func switchToSource(_ sourceType: MusicSourceType) {
        if let source = availableSources.first(where: { $0.sourceType == sourceType }) {
            currentSource = source
        }
    }
    
    func getSource(of type: MusicSourceType) -> MusicSourceProtocol? {
        return availableSources.first { $0.sourceType == type }
    }
    func searchAcrossAllSources(query: String) -> AnyPublisher<[SearchResults], APIError> {
        let publishers = availableSources.map { source in
            source.searchAll(query: query)
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
    func findBestMatch(for track: Track) -> AnyPublisher<Track?, APIError> {
        let searchQuery = "\(track.artistName) \(track.title)"
        
        return searchAcrossAllSources(query: searchQuery)
            .map { results in
                for result in results {
                    for foundTrack in result.tracks {
                        if self.isGoodMatch(original: track, found: foundTrack) {
                            return foundTrack
                        }
                    }
                }
                return nil
            }
            .eraseToAnyPublisher()
    }
    
    private func isGoodMatch(original: Track, found: Track) -> Bool {
        let originalTitle = original.title.lowercased().trimmingCharacters(in: .whitespacesAndPunctuation)
        let foundTitle = found.title.lowercased().trimmingCharacters(in: .whitespacesAndPunctuation)
        let originalArtist = original.artistName.lowercased().trimmingCharacters(in: .whitespacesAndPunctuation)
        let foundArtist = found.artistName.lowercased().trimmingCharacters(in: .whitespacesAndPunctuation)
        let titleSimilarity = stringSimilarity(originalTitle, foundTitle)
        let artistSimilarity = stringSimilarity(originalArtist, foundArtist)
        
        return titleSimilarity > 0.8 && artistSimilarity > 0.8
    }
    
    private func stringSimilarity(_ str1: String, _ str2: String) -> Double {
        let longer = str1.count > str2.count ? str1 : str2
        let shorter = str1.count > str2.count ? str2 : str1
        
        guard longer.count > 0 else { return 1.0 }
        
        let editDistance = levenshteinDistance(shorter, longer)
        return (Double(longer.count) - Double(editDistance)) / Double(longer.count)
    }
    
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let arr1 = Array(str1)
        let arr2 = Array(str2)
        let len1 = arr1.count
        let len2 = arr2.count
        
        var matrix = Array(repeating: Array(repeating: 0, count: len2 + 1), count: len1 + 1)
        
        for i in 0...len1 {
            matrix[i][0] = i
        }
        
        for j in 0...len2 {
            matrix[0][j] = j
        }
        
        for i in 1...len1 {
            for j in 1...len2 {
                let cost = arr1[i-1] == arr2[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }
        
        return matrix[len1][len2]
    }
}
