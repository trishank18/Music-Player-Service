import Foundation
import Combine

class TrackViewModel: ObservableObject {
    @Published var track: Track?
    @Published var album: Album?
    @Published var artist: Artist?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lyrics: String?
    @Published var recommendations: [Track] = []
    @Published var albumLoadingState: LoadingState<Album?> = .idle
    @Published var artistLoadingState: LoadingState<Artist?> = .idle
    @Published var lyricsLoadingState: LoadingState<String?> = .idle
    @Published var recommendationsLoadingState: LoadingState<[Track]> = .idle
    private let musicSource: MusicSourceProtocol
    private let musicPlayer = MusicPlayerService.shared
    private var cancellables = Set<AnyCancellable>()
    init(musicSource: MusicSourceProtocol = MusicSourceManager.shared.currentSource) {
        self.musicSource = musicSource
        observePlaybackState()
    }
    func loadTrack(_ track: Track) {
        self.track = track
        loadTrackDetails()
    }
    
    func loadTrack(byId trackId: String) {
        isLoading = true
        errorMessage = nil
        
        musicSource.getTrack(id: trackId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] track in
                    if let track = track {
                        self?.track = track
                        self?.loadTrackDetails()
                    } else {
                        self?.errorMessage = "Track not found"
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func refresh() {
        guard let track = track else { return }
        loadTrackDetails()
    }
    func playTrack() {
        guard let track = track else { return }
        musicPlayer.playTrack(track)
    }
    
    func pauseTrack() {
        musicPlayer.pause()
    }
    
    func togglePlayPause() {
        if isCurrentlyPlaying {
            pauseTrack()
        } else {
            playTrack()
        }
    }
    
    func addToQueue() {
        guard let track = track else { return }
        musicPlayer.addToQueue(track)
    }
    
    func playNext() {
        guard let track = track else { return }
        QueueManager.shared.insertNext(track)
    }
    
    func addToPlaylist() {
        print("Add to playlist functionality to be implemented")
    }
    
    func downloadTrack() {
        print("Download functionality to be implemented")
    }
    
    func shareTrack() {
        print("Share functionality to be implemented")
    }
    private func loadTrackDetails() {
        guard let track = track else { return }
        
        loadAlbum(for: track.albumId)
        loadArtist(for: track.artistId)
        loadLyrics()
        loadRecommendations()
    }
    
    private func loadAlbum(for albumId: String?) {
        guard let albumId = albumId, !albumId.isEmpty else { return }
        
        albumLoadingState = .loading
        
        musicSource.getAlbum(id: albumId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.albumLoadingState = .error(error)
                    }
                },
                receiveValue: { [weak self] album in
                    self?.album = album
                    self?.albumLoadingState = .loaded(album)
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadArtist(for artistId: String?) {
        guard let artistId = artistId, !artistId.isEmpty else { return }
        
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
    
    private func loadLyrics() {
        guard let track = track, track.hasLyrics else { return }
        
        lyricsLoadingState = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.lyrics = track.lyrics
            self?.lyricsLoadingState = .loaded(track.lyrics)
        }
    }
    
    private func loadRecommendations() {
        guard let track = track else { return }
        
        recommendationsLoadingState = .loading
        
        musicSource.getRecommendations(basedOn: track)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.recommendationsLoadingState = .error(error)
                    }
                },
                receiveValue: { [weak self] tracks in
                    self?.recommendations = tracks
                    self?.recommendationsLoadingState = .loaded(tracks)
                }
            )
            .store(in: &cancellables)
    }
    
    private func observePlaybackState() {
        musicPlayer.$currentTrack
            .sink { [weak self] currentTrack in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        musicPlayer.$isPlaying
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    var isCurrentlyPlaying: Bool {
        guard let track = track else { return false }
        return musicPlayer.currentTrack?.id == track.id && musicPlayer.isPlaying
    }
    
    var isCurrentTrack: Bool {
        guard let track = track else { return false }
        return musicPlayer.currentTrack?.id == track.id
    }
    
    var isInQueue: Bool {
        guard let track = track else { return false }
        return QueueManager.shared.isInQueue(track)
    }
    
    var hasAlbum: Bool {
        return album != nil
    }
    
    var hasArtist: Bool {
        return artist != nil
    }
    
    var hasLyrics: Bool {
        return track?.hasLyrics ?? false
    }
    
    var hasMusicVideo: Bool {
        return track?.hasMusicVideo ?? false
    }
    
    var hasRecommendations: Bool {
        return !recommendations.isEmpty
    }
    
    var formattedDuration: String {
        return track?.formattedDuration ?? "0:00"
    }
    
    var trackNumber: String? {
        return track?.trackNumber
    }
    
    var trackRating: Double? {
        return track?.rating
    }
    
    var formattedRating: String? {
        guard let rating = trackRating else { return nil }
        return String(format: "%.1f/10", rating * 10)
    }
    
    var trackGenre: String? {
        return track?.genre
    }
    
    var trackMood: String? {
        return track?.mood
    }
    
    var trackStyle: String? {
        return track?.style
    }
    
    var trackTheme: String? {
        return track?.theme
    }
    
    var formattedLyrics: String {
        return lyrics?.replacingOccurrences(of: "\\n", with: "\n") ?? ""
    }
    
    var albumTitle: String? {
        return album?.title ?? track?.albumName
    }
    
    var artistName: String {
        return artist?.name ?? track?.artistName ?? "Unknown Artist"
    }
    
    var trackTitle: String {
        return track?.title ?? "Unknown Track"
    }
    
    var albumArtURL: String? {
        return album?.imageURL ?? track?.thumb
    }
    func navigateToArtist() -> Artist? {
        return artist
    }
    
    func navigateToAlbum() -> Album? {
        return album
    }
    var currentPlaybackTime: TimeInterval {
        return musicPlayer.currentTime
    }
    
    var totalDuration: TimeInterval {
        return musicPlayer.duration
    }
    
    var playbackProgress: Double {
        return musicPlayer.progress
    }
    
    var formattedCurrentTime: String {
        return musicPlayer.formattedCurrentTime
    }
    
    var formattedTotalDuration: String {
        return musicPlayer.formattedDuration
    }
    
    var formattedRemainingTime: String {
        return musicPlayer.formattedRemainingTime
    }
    var queuePosition: Int? {
        guard let track = track else { return nil }
        return QueueManager.shared.getQueuePosition(for: track)
    }
    
    var nextTrackInQueue: Track? {
        let queueManager = QueueManager.shared
        let nextIndex = queueManager.currentIndex + 1
        return queueManager.getTrack(at: nextIndex)
    }
    
    var previousTrackInQueue: Track? {
        let queueManager = QueueManager.shared
        let previousIndex = queueManager.currentIndex - 1
        return queueManager.getTrack(at: previousIndex)
    }
    func playRecommendation(_ recommendedTrack: Track) {
        musicPlayer.playTrack(recommendedTrack)
    }
    
    func addRecommendationToQueue(_ recommendedTrack: Track) {
        musicPlayer.addToQueue(recommendedTrack)
    }
    
    func playAllRecommendations() {
        guard !recommendations.isEmpty else { return }
        musicPlayer.playTracks(recommendations)
    }
    
    func addAllRecommendationsToQueue() {
        musicPlayer.addToQueue(recommendations)
    }
    
    func isRecommendationPlaying(_ recommendedTrack: Track) -> Bool {
        return musicPlayer.currentTrack?.id == recommendedTrack.id && musicPlayer.isPlaying
    }
    
    func isRecommendationInQueue(_ recommendedTrack: Track) -> Bool {
        return QueueManager.shared.isInQueue(recommendedTrack)
    }
}
