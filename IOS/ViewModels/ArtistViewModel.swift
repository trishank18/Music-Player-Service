import Foundation
import Combine

class ArtistViewModel: ObservableObject {
    @Published var artist: Artist?
    @Published var albums: [Album] = []
    @Published var topTracks: [Track] = []
    @Published var musicVideos: [MusicVideo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var albumsLoadingState: LoadingState<[Album]> = .idle
    @Published var tracksLoadingState: LoadingState<[Track]> = .idle
    @Published var videosLoadingState: LoadingState<[MusicVideo]> = .idle
    private let musicSource: MusicSourceProtocol
    private let musicPlayer = MusicPlayerService.shared
    private var cancellables = Set<AnyCancellable>()
    init(musicSource: MusicSourceProtocol = MusicSourceManager.shared.currentSource) {
        self.musicSource = musicSource
    }
    func loadArtist(_ artist: Artist) {
        self.artist = artist
        loadArtistDetails()
    }
    
    func loadArtist(byId artistId: String) {
        isLoading = true
        errorMessage = nil
        
        musicSource.getArtist(id: artistId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] artist in
                    if let artist = artist {
                        self?.artist = artist
                        self?.loadArtistDetails()
                    } else {
                        self?.errorMessage = "Artist not found"
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func searchArtist(name: String) {
        isLoading = true
        errorMessage = nil
        
        musicSource.searchArtists(query: name)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] artists in
                    if let firstArtist = artists.first {
                        self?.artist = firstArtist
                        self?.loadArtistDetails()
                    } else {
                        self?.errorMessage = "No artists found"
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func refresh() {
        guard let artist = artist else { return }
        loadArtistDetails()
    }
    func playArtistTopTracks() {
        guard !topTracks.isEmpty else { return }
        musicPlayer.playTracks(topTracks)
    }
    
    func playTrack(_ track: Track) {
        musicPlayer.playTrack(track)
    }
    
    func addTrackToQueue(_ track: Track) {
        musicPlayer.addToQueue(track)
    }
    
    func addAllTracksToQueue() {
        musicPlayer.addToQueue(topTracks)
    }
    
    func shufflePlay() {
        guard !topTracks.isEmpty else { return }
        var shuffledTracks = topTracks
        shuffledTracks.shuffle()
        musicPlayer.playTracks(shuffledTracks)
    }
    private func loadArtistDetails() {
        guard let artist = artist else { return }
        
        loadAlbums(for: artist.id)
        loadTopTracks(for: artist.id)
        loadMusicVideos(for: artist.id)
    }
    
    private func loadAlbums(for artistId: String) {
        albumsLoadingState = .loading
        
        musicSource.getArtistAlbums(artistId: artistId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.albumsLoadingState = .error(error)
                    }
                },
                receiveValue: { [weak self] albums in
                    self?.albums = albums.sorted { album1, album2 in
                        guard let date1 = album1.releaseDate,
                              let date2 = album2.releaseDate else {
                            return album1.title < album2.title
                        }
                        return date1 > date2
                    }
                    self?.albumsLoadingState = .loaded(albums)
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadTopTracks(for artistId: String) {
        tracksLoadingState = .loading
        
        musicSource.getArtistTopTracks(artistId: artistId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.tracksLoadingState = .error(error)
                    }
                },
                receiveValue: { [weak self] tracks in
                    self?.topTracks = tracks
                    self?.tracksLoadingState = .loaded(tracks)
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadMusicVideos(for artistId: String) {
        videosLoadingState = .loading
        
        musicSource.getArtistMusicVideos(artistId: artistId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.videosLoadingState = .error(error)
                    }
                },
                receiveValue: { [weak self] videos in
                    self?.musicVideos = videos
                    self?.videosLoadingState = .loaded(videos)
                }
            )
            .store(in: &cancellables)
    }
    var hasAlbums: Bool {
        return !albums.isEmpty
    }
    
    var hasTopTracks: Bool {
        return !topTracks.isEmpty
    }
    
    var hasMusicVideos: Bool {
        return !musicVideos.isEmpty
    }
    
    var formattedBiography: String {
        return artist?.biography?.replacingOccurrences(of: "\\n", with: "\n") ?? ""
    }
    
    var socialLinks: [SocialLink] {
        return artist?.socialLinks ?? []
    }
    
    var latestAlbum: Album? {
        return albums.first
    }
    
    var albumCount: Int {
        return albums.count
    }
    
    var trackCount: Int {
        return topTracks.count
    }
    
    var videoCount: Int {
        return musicVideos.count
    }
    func getRecommendations() -> AnyPublisher<[Track], APIError> {
        guard let artist = artist else {
            return Just([])
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        
        return musicSource.getRecommendations(basedOn: artist)
    }
    
    func isCurrentlyPlaying(_ track: Track) -> Bool {
        return musicPlayer.currentTrack?.id == track.id && musicPlayer.isPlaying
    }
    
    func isInQueue(_ track: Track) -> Bool {
        return QueueManager.shared.isInQueue(track)
    }
}
