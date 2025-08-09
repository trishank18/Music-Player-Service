import Foundation
import Combine

class AlbumViewModel: ObservableObject {
    @Published var album: Album?
    @Published var tracks: [Track] = []
    @Published var artist: Artist?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var tracksLoadingState: LoadingState<[Track]> = .idle
    @Published var artistLoadingState: LoadingState<Artist?> = .idle
    private let musicSource: MusicSourceProtocol
    private let musicPlayer = MusicPlayerService.shared
    private var cancellables = Set<AnyCancellable>()
    init(musicSource: MusicSourceProtocol = MusicSourceManager.shared.currentSource) {
        self.musicSource = musicSource
    }
    func loadAlbum(_ album: Album) {
        self.album = album
        loadAlbumDetails()
    }
    
    func loadAlbum(byId albumId: String) {
        isLoading = true
        errorMessage = nil
        
        musicSource.getAlbum(id: albumId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] album in
                    if let album = album {
                        self?.album = album
                        self?.loadAlbumDetails()
                    } else {
                        self?.errorMessage = "Album not found"
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func refresh() {
        guard let album = album else { return }
        loadAlbumDetails()
    }
    func playAlbum() {
        guard !tracks.isEmpty else { return }
        musicPlayer.playTracks(tracks)
    }
    
    func playTrack(_ track: Track) {
        let trackIndex = tracks.firstIndex(of: track) ?? 0
        musicPlayer.playTracks(tracks, startingAt: trackIndex)
    }
    
    func addTrackToQueue(_ track: Track) {
        musicPlayer.addToQueue(track)
    }
    
    func addAlbumToQueue() {
        musicPlayer.addToQueue(tracks)
    }
    
    func shufflePlayAlbum() {
        guard !tracks.isEmpty else { return }
        var shuffledTracks = tracks
        shuffledTracks.shuffle()
        musicPlayer.playTracks(shuffledTracks)
    }
    
    func playNext(_ track: Track) {
        QueueManager.shared.insertNext(track)
    }
    private func loadAlbumDetails() {
        guard let album = album else { return }
        
        loadTracks(for: album.id)
        loadArtist(for: album.artistId)
    }
    
    private func loadTracks(for albumId: String) {
        tracksLoadingState = .loading
        
        musicSource.getAlbumTracks(albumId: albumId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.tracksLoadingState = .error(error)
                    }
                },
                receiveValue: { [weak self] tracks in
                    self?.tracks = tracks.sorted { track1, track2 in
                        let trackNum1 = track1.trackNumberInt ?? 0
                        let trackNum2 = track2.trackNumberInt ?? 0
                        return trackNum1 < trackNum2
                    }
                    self?.tracksLoadingState = .loaded(tracks)
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadArtist(for artistId: String) {
        guard !artistId.isEmpty else { return }
        
        artistLoadingState = .loading
        
        musicSource.getArtist(id: artistId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.artistLoadingState = .error(error)
                    }
                },
                receiveValue: { [weak self] artist in
                    self?.artist = artist
                    self?.artistLoadingState = .loaded(artist)
                }
            )
            .store(in: &cancellables)
    }
    var hasTracks: Bool {
        return !tracks.isEmpty
    }
    
    var hasArtist: Bool {
        return artist != nil
    }
    
    var formattedDescription: String {
        return album?.description?.replacingOccurrences(of: "\\n", with: "\n") ?? ""
    }
    
    var trackCount: Int {
        return tracks.count
    }
    
    var totalDuration: TimeInterval {
        return tracks.reduce(0) { total, track in
            total + track.durationInSeconds
        }
    }
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d hr %d min", hours, minutes)
        } else {
            return String(format: "%d min", minutes)
        }
    }
    
    var releaseYear: String? {
        return album?.releaseDate
    }
    
    var albumRating: Double? {
        return album?.ratingPercentage
    }
    
    var formattedRating: String? {
        guard let rating = albumRating else { return nil }
        return String(format: "%.1f/10", rating * 10)
    }
    
    var albumGenre: String? {
        return album?.genre
    }
    
    var albumMood: String? {
        return album?.mood
    }
    
    var albumStyle: String? {
        return album?.style
    }
    
    var recordLabel: String? {
        return album?.label
    }
    func getTrackNumber(for track: Track) -> String {
        return track.trackNumber ?? "—"
    }
    
    func getTrackDuration(for track: Track) -> String {
        return track.formattedDuration
    }
    
    func isCurrentlyPlaying(_ track: Track) -> Bool {
        return musicPlayer.currentTrack?.id == track.id && musicPlayer.isPlaying
    }
    
    func isInQueue(_ track: Track) -> Bool {
        return QueueManager.shared.isInQueue(track)
    }
    
    func hasLyrics(_ track: Track) -> Bool {
        return track.hasLyrics
    }
    
    func hasMusicVideo(_ track: Track) -> Bool {
        return track.hasMusicVideo
    }
    func getRecommendations() -> AnyPublisher<[Track], APIError> {
        guard let album = album else {
            return Just([])
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        
        return musicSource.getRecommendations(basedOn: album)
    }
    
    func getTrackIndex(_ track: Track) -> Int? {
        return tracks.firstIndex(of: track)
    }
    
    func getTrackAt(index: Int) -> Track? {
        guard index >= 0 && index < tracks.count else { return nil }
        return tracks[index]
    }
    
    func getNextTrack(after track: Track) -> Track? {
        guard let currentIndex = getTrackIndex(track) else { return nil }
        let nextIndex = currentIndex + 1
        return getTrackAt(index: nextIndex)
    }
    
    func getPreviousTrack(before track: Track) -> Track? {
        guard let currentIndex = getTrackIndex(track) else { return nil }
        let previousIndex = currentIndex - 1
        return getTrackAt(index: previousIndex)
    }
    func filterTracks(by query: String) -> [Track] {
        guard !query.isEmpty else { return tracks }
        
        return tracks.filter { track in
            track.title.localizedCaseInsensitiveContains(query) ||
            track.artistName.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getTracksWithLyrics() -> [Track] {
        return tracks.filter { $0.hasLyrics }
    }
    
    func getTracksWithMusicVideos() -> [Track] {
        return tracks.filter { $0.hasMusicVideo }
    }
    var averageTrackRating: Double? {
        let tracksWithRatings = tracks.compactMap { $0.rating }
        guard !tracksWithRatings.isEmpty else { return nil }
        
        let sum = tracksWithRatings.reduce(0, +)
        return sum / Double(tracksWithRatings.count)
    }
    
    var mostPopularTrack: Track? {
        return tracks.max { track1, track2 in
            let rating1 = Double(track1.score ?? "0") ?? 0
            let rating2 = Double(track2.score ?? "0") ?? 0
            return rating1 < rating2
        }
    }
    
    var shortestTrack: Track? {
        return tracks.min { $0.durationInSeconds < $1.durationInSeconds }
    }
    
    var longestTrack: Track? {
        return tracks.max { $0.durationInSeconds < $1.durationInSeconds }
    }
}
