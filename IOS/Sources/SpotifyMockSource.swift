import Foundation
import Combine

class SpotifyMockSource: MusicSourceProtocol {
    var sourceType: MusicSourceType = .spotifyMock
    var isAvailable: Bool = true
    
    private let mockArtists: [Artist] = [
        Artist(id: "spotify_1", name: "The Weeknd", biography: "Canadian singer and songwriter", formed: "2010", genre: "R&B", mood: "Dark", style: "Alternative R&B", country: "Canada", website: "https://theweeknd.com", facebook: nil, twitter: nil, lastFMChart: nil, thumb: "https://i.scdn.co/image/ab6761610000e5ebccc4a9ea11b8374446fb55e4", logo: nil, fanart: nil, banner: nil),
        
        Artist(id: "spotify_2", name: "Billie Eilish", biography: "American singer and songwriter", formed: "2015", genre: "Pop", mood: "Moody", style: "Alternative Pop", country: "USA", website: "https://billieeilish.com", facebook: nil, twitter: nil, lastFMChart: nil, thumb: "https://i.scdn.co/image/ab6761610000e5ebb1e5fb8c6a140e45c6c106d7", logo: nil, fanart: nil, banner: nil),
        
        Artist(id: "spotify_3", name: "Daft Punk", biography: "French electronic music duo", formed: "1993", genre: "Electronic", mood: "Energetic", style: "House", country: "France", website: nil, facebook: nil, twitter: nil, lastFMChart: nil, thumb: "https://i.scdn.co/image/ab6761610000e5eb7a4d2a46e5c6e53b8b3b8d2e", logo: nil, fanart: nil, banner: nil)
    ]
    
    private let mockAlbums: [Album] = [
        Album(id: "spotify_album_1", artistId: "spotify_1", title: "After Hours", artistName: "The Weeknd", description: "Fourth studio album", genre: "R&B", mood: "Dark", style: "Alternative R&B", theme: "Nocturnal", speed: "Medium", releaseDate: "2020", label: "Republic Records", sales: "5000000", score: "8.5", scoreVotes: "1250", thumb: "https://i.scdn.co/image/ab67616d0000b273c6d8e7b3d0e1b8c5b5f7e5a0", thumbHQ: nil, thumbHD: nil, spine: nil, cdArt: nil),
        
        Album(id: "spotify_album_2", artistId: "spotify_2", title: "When We All Fall Asleep, Where Do We Go?", artistName: "Billie Eilish", description: "Debut studio album", genre: "Pop", mood: "Dark", style: "Alternative Pop", theme: "Dreams", speed: "Slow", releaseDate: "2019", label: "Interscope Records", sales: "8000000", score: "9.0", scoreVotes: "2100", thumb: "https://i.scdn.co/image/ab67616d0000b273a9f6c04ba168a55c7a4a6dc8", thumbHQ: nil, thumbHD: nil, spine: nil, cdArt: nil),
        
        Album(id: "spotify_album_3", artistId: "spotify_3", title: "Random Access Memories", artistName: "Daft Punk", description: "Fourth studio album", genre: "Electronic", mood: "Nostalgic", style: "Disco", theme: "Retro-futurism", speed: "Medium", releaseDate: "2013", label: "Columbia Records", sales: "3000000", score: "8.8", scoreVotes: "1800", thumb: "https://i.scdn.co/image/ab67616d0000b273d6d7f7e8b8c9b1b7c5a4d3c2", thumbHQ: nil, thumbHD: nil, spine: nil, cdArt: nil)
    ]
    
    private let mockTracks: [Track] = [
        Track(id: "spotify_track_1", artistId: "spotify_1", albumId: "spotify_album_1", title: "Blinding Lights", artistName: "The Weeknd", albumName: "After Hours", description: "Hit single", genre: "R&B", mood: "Euphoric", style: "Synthwave", theme: "Night", duration: "200000", trackNumber: "3", lyrics: nil, musicVideo: "https://youtube.com/watch?v=4NRXx6U8ABQ", score: "9.2", scoreVotes: "5000", thumb: "https://i.scdn.co/image/ab67616d0000b273c6d8e7b3d0e1b8c5b5f7e5a0", preview: "https://p.scdn.co/mp3-preview/mock_preview_1"),
        
        Track(id: "spotify_track_2", artistId: "spotify_2", albumId: "spotify_album_2", title: "bad guy", artistName: "Billie Eilish", albumName: "When We All Fall Asleep, Where Do We Go?", description: "Grammy-winning single", genre: "Pop", mood: "Mischievous", style: "Alternative Pop", theme: "Rebellion", duration: "194000", trackNumber: "1", lyrics: nil, musicVideo: "https://youtube.com/watch?v=DyDfgMOUjCI", score: "8.9", scoreVotes: "4200", thumb: "https://i.scdn.co/image/ab67616d0000b273a9f6c04ba168a55c7a4a6dc8", preview: "https://p.scdn.co/mp3-preview/mock_preview_2"),
        
        Track(id: "spotify_track_3", artistId: "spotify_3", albumId: "spotify_album_3", title: "Get Lucky", artistName: "Daft Punk", albumName: "Random Access Memories", description: "Featuring Pharrell Williams", genre: "Electronic", mood: "Upbeat", style: "Funk", theme: "Party", duration: "248000", trackNumber: "8", lyrics: nil, musicVideo: "https://youtube.com/watch?v=5NV6Rdv1a3I", score: "8.7", scoreVotes: "3800", thumb: "https://i.scdn.co/image/ab67616d0000b273d6d7f7e8b8c9b1b7c5a4d3c2", preview: "https://p.scdn.co/mp3-preview/mock_preview_3"),
        
        Track(id: "spotify_track_4", artistId: "spotify_1", albumId: "spotify_album_1", title: "Save Your Tears", artistName: "The Weeknd", albumName: "After Hours", description: "Emotional ballad", genre: "R&B", mood: "Melancholic", style: "Synthpop", theme: "Heartbreak", duration: "215000", trackNumber: "5", lyrics: nil, musicVideo: nil, score: "8.5", scoreVotes: "2900", thumb: "https://i.scdn.co/image/ab67616d0000b273c6d8e7b3d0e1b8c5b5f7e5a0", preview: "https://p.scdn.co/mp3-preview/mock_preview_4"),
        
        Track(id: "spotify_track_5", artistId: "spotify_2", albumId: "spotify_album_2", title: "when the party's over", artistName: "Billie Eilish", albumName: "When We All Fall Asleep, Where Do We Go?", description: "Emotional track", genre: "Pop", mood: "Sad", style: "Ballad", theme: "Loneliness", duration: "196000", trackNumber: "7", lyrics: nil, musicVideo: "https://youtube.com/watch?v=pbMwTqkKSps", score: "9.1", scoreVotes: "3500", thumb: "https://i.scdn.co/image/ab67616d0000b273a9f6c04ba168a55c7a4a6dc8", preview: "https://p.scdn.co/mp3-preview/mock_preview_5")
    ]
    
    func searchArtists(query: String) -> AnyPublisher<[Artist], APIError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let filteredArtists = self.mockArtists.filter { artist in
                    artist.name.lowercased().contains(query.lowercased())
                }
                promise(.success(filteredArtists))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func searchAlbums(query: String) -> AnyPublisher<[Album], APIError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let filteredAlbums = self.mockAlbums.filter { album in
                    album.title.lowercased().contains(query.lowercased()) ||
                    album.artistName.lowercased().contains(query.lowercased())
                }
                promise(.success(filteredAlbums))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func searchTracks(query: String) -> AnyPublisher<[Track], APIError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let filteredTracks = self.mockTracks.filter { track in
                    track.title.lowercased().contains(query.lowercased()) ||
                    track.artistName.lowercased().contains(query.lowercased()) ||
                    (track.albumName?.lowercased().contains(query.lowercased()) ?? false)
                }
                promise(.success(filteredTracks))
            }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let artist = self.mockArtists.first { $0.id == id }
                promise(.success(artist))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getArtistAlbums(artistId: String) -> AnyPublisher<[Album], APIError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                let albums = self.mockAlbums.filter { $0.artistId == artistId }
                promise(.success(albums))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getArtistTopTracks(artistId: String) -> AnyPublisher<[Track], APIError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                let tracks = self.mockTracks
                    .filter { $0.artistId == artistId }
                    .sorted { track1, track2 in
                        let score1 = Double(track1.score ?? "0") ?? 0
                        let score2 = Double(track2.score ?? "0") ?? 0
                        return score1 > score2
                    }
                promise(.success(Array(tracks.prefix(10))))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getArtistMusicVideos(artistId: String) -> AnyPublisher<[MusicVideo], APIError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                let tracks = self.mockTracks.filter { $0.artistId == artistId && $0.hasMusicVideo }
                let musicVideos = tracks.map { track in
                    MusicVideo(
                        id: "mv_\(track.id)",
                        artistId: track.artistId ?? "",
                        trackName: track.title,
                        artistName: track.artistName,
                        albumName: track.albumName,
                        description: track.description,
                        videoURL: track.musicVideo,
                        thumb: track.thumb,
                        director: nil,
                        company: nil,
                        budget: nil,
                        views: nil
                    )
                }
                promise(.success(musicVideos))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getAlbum(id: String) -> AnyPublisher<Album?, APIError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let album = self.mockAlbums.first { $0.id == id }
                promise(.success(album))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getAlbumTracks(albumId: String) -> AnyPublisher<[Track], APIError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                let tracks = self.mockTracks
                    .filter { $0.albumId == albumId }
                    .sorted { track1, track2 in
                        let trackNum1 = Int(track1.trackNumber ?? "0") ?? 0
                        let trackNum2 = Int(track2.trackNumber ?? "0") ?? 0
                        return trackNum1 < trackNum2
                    }
                promise(.success(tracks))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getTrack(id: String) -> AnyPublisher<Track?, APIError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let track = self.mockTracks.first { $0.id == id }
                promise(.success(track))
            }
        }
        .eraseToAnyPublisher()
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
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                let trendingTracks = self.mockTracks.sorted { track1, track2 in
                    let score1 = Double(track1.score ?? "0") ?? 0
                    let score2 = Double(track2.score ?? "0") ?? 0
                    return score1 > score2
                }
                promise(.success(trendingTracks))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getTrendingAlbums() -> AnyPublisher<[Album], APIError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                let trendingAlbums = self.mockAlbums.sorted { album1, album2 in
                    let score1 = Double(album1.score ?? "0") ?? 0
                    let score2 = Double(album2.score ?? "0") ?? 0
                    return score1 > score2
                }
                promise(.success(trendingAlbums))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getTrendingArtists() -> AnyPublisher<[Artist], APIError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                promise(.success(self.mockArtists))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getRecommendations(basedOn track: Track) -> AnyPublisher<[Track], APIError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let recommendations = self.mockTracks.filter { mockTrack in
                    return mockTrack.id != track.id && (
                        mockTrack.genre == track.genre ||
                        mockTrack.artistId == track.artistId ||
                        mockTrack.mood == track.mood
                    )
                }
                promise(.success(Array(recommendations.prefix(5))))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getRecommendations(basedOn artist: Artist) -> AnyPublisher<[Track], APIError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let recommendations = self.mockTracks.filter { track in
                    return track.artistId != artist.id && (
                        track.genre == artist.genre ||
                        track.mood == artist.mood
                    )
                }
                promise(.success(Array(recommendations.prefix(5))))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getRecommendations(basedOn album: Album) -> AnyPublisher<[Track], APIError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let recommendations = self.mockTracks.filter { track in
                    return track.albumId != album.id && (
                        track.genre == album.genre ||
                        track.style == album.style ||
                        track.mood == album.mood
                    )
                }
                promise(.success(Array(recommendations.prefix(5))))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func generateMockPreviewURL(for trackId: String) -> String {
        return "https://p.scdn.co/mp3-preview/mock_preview_\(trackId.suffix(1))"
    }
}
