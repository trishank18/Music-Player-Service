import Foundation
import Combine
import AVFoundation

class NowPlayingViewModel: ObservableObject {
    @Published var currentTrack: Track?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 1.0
    @Published var isBuffering = false
    @Published var playbackState: PlaybackState = .stopped
    @Published var queue: [Track] = []
    @Published var currentIndex = 0
    @Published var repeatMode: RepeatMode = .off
    @Published var shuffleMode: ShuffleMode = .off
    @Published var isShowingQueue = false
    @Published var isShowingLyrics = false
    @Published var isShowingDetails = false
    @Published var albumArtRotation: Double = 0
    @Published var lyrics: String?
    @Published var currentLyricLine: String?
    private let musicPlayer = MusicPlayerService.shared
    private let queueManager = QueueManager.shared
    private let audioSessionManager = AudioSessionManager()
    private var cancellables = Set<AnyCancellable>()
    init() {
        setupObservers()
        setupAudioSessionObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    private func setupObservers() {
        musicPlayer.$currentTrack
            .assign(to: \.currentTrack, on: self)
            .store(in: &cancellables)
        
        musicPlayer.$isPlaying
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)
        
        musicPlayer.$currentTime
            .assign(to: \.currentTime, on: self)
            .store(in: &cancellables)
        
        musicPlayer.$duration
            .assign(to: \.duration, on: self)
            .store(in: &cancellables)
        
        musicPlayer.$volume
            .assign(to: \.volume, on: self)
            .store(in: &cancellables)
        
        musicPlayer.$isBuffering
            .assign(to: \.isBuffering, on: self)
            .store(in: &cancellables)
        
        musicPlayer.$playbackState
            .assign(to: \.playbackState, on: self)
            .store(in: &cancellables)
        
        musicPlayer.$repeatMode
            .assign(to: \.repeatMode, on: self)
            .store(in: &cancellables)
        
        musicPlayer.$shuffleMode
            .assign(to: \.shuffleMode, on: self)
            .store(in: &cancellables)
        queueManager.$queue
            .assign(to: \.queue, on: self)
            .store(in: &cancellables)
        
        queueManager.$currentIndex
            .assign(to: \.currentIndex, on: self)
            .store(in: &cancellables)
        musicPlayer.$isPlaying
            .sink { [weak self] isPlaying in
                if isPlaying {
                    self?.startAlbumArtRotation()
                } else {
                    self?.stopAlbumArtRotation()
                }
            }
            .store(in: &cancellables)
        musicPlayer.$currentTrack
            .sink { [weak self] track in
                if let track = track {
                    self?.loadLyrics(for: track)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupAudioSessionObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(headphonesDisconnected),
            name: .headphonesDisconnected,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioInterrupted),
            name: .audioInterrupted,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioInterruptionEnded),
            name: .audioInterruptionEnded,
            object: nil
        )
    }
    func play() {
        musicPlayer.play()
    }
    
    func pause() {
        musicPlayer.pause()
    }
    
    func togglePlayPause() {
        musicPlayer.togglePlayPause()
    }
    
    func playNext() {
        musicPlayer.playNext()
    }
    
    func playPrevious() {
        musicPlayer.playPrevious()
    }
    
    func seek(to time: TimeInterval) {
        musicPlayer.seek(to: time)
    }
    
    func setVolume(_ volume: Float) {
        musicPlayer.setVolume(volume)
    }
    
    func toggleRepeatMode() {
        musicPlayer.toggleRepeatMode()
    }
    
    func toggleShuffleMode() {
        musicPlayer.toggleShuffleMode()
    }
    func removeFromQueue(at index: Int) {
        queueManager.removeFromQueue(at: index)
    }
    
    func moveTrackInQueue(from source: Int, to destination: Int) {
        queueManager.moveTrack(from: source, to: destination)
    }
    
    func playTrackFromQueue(at index: Int) {
        queueManager.playTrack(at: index)
    }
    
    func clearQueue() {
        queueManager.clearQueue()
    }
    func toggleQueueVisibility() {
        isShowingQueue.toggle()
    }
    
    func toggleLyricsVisibility() {
        isShowingLyrics.toggle()
    }
    
    func toggleDetailsVisibility() {
        isShowingDetails.toggle()
    }
    
    func shareCurrentTrack() {
        print("Share track: \(currentTrack?.title ?? "Unknown")")
    }
    
    func addCurrentTrackToPlaylist() {
        print("Add to playlist: \(currentTrack?.title ?? "Unknown")")
    }
    
    func likeCurrentTrack() {
        print("Like track: \(currentTrack?.title ?? "Unknown")")
    }
    private func startAlbumArtRotation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, self.isPlaying else {
                timer.invalidate()
                return
            }
            
            DispatchQueue.main.async {
                self.albumArtRotation += 1
                if self.albumArtRotation >= 360 {
                    self.albumArtRotation = 0
                }
            }
        }
    }
    
    private func stopAlbumArtRotation() {
    }
    private func loadLyrics(for track: Track) {
        lyrics = track.lyrics
        currentLyricLine = nil
    }
    
    func getCurrentLyricLine() -> String? {
        return currentLyricLine
    }
    @objc private func headphonesDisconnected() {
        if isPlaying {
            pause()
        }
    }
    
    @objc private func audioInterrupted() {
        if isPlaying {
            pause()
        }
    }
    
    @objc private func audioInterruptionEnded() {
    }
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    var formattedCurrentTime: String {
        return formatTime(currentTime)
    }
    
    var formattedDuration: String {
        return formatTime(duration)
    }
    
    var formattedRemainingTime: String {
        let remaining = max(0, duration - currentTime)
        return "-" + formatTime(remaining)
    }
    
    var hasNext: Bool {
        return queueManager.hasNext
    }
    
    var hasPrevious: Bool {
        return queueManager.hasPrevious
    }
    
    var queueCount: Int {
        return queue.count
    }
    
    var currentTrackIndex: Int {
        return currentIndex + 1 // 1-based for display
    }
    
    var albumArtURL: String? {
        return currentTrack?.thumb
    }
    
    var trackTitle: String {
        return currentTrack?.title ?? "No Track"
    }
    
    var artistName: String {
        return currentTrack?.artistName ?? "Unknown Artist"
    }
    
    var albumName: String? {
        return currentTrack?.albumName
    }
    
    var hasLyrics: Bool {
        return currentTrack?.hasLyrics ?? false
    }
    
    var hasMusicVideo: Bool {
        return currentTrack?.hasMusicVideo ?? false
    }
    
    var upcomingTracks: [Track] {
        return queueManager.upcomingTracks
    }
    
    var playbackRate: Float {
        return isPlaying ? 1.0 : 0.0
    }
    
    var isCurrentTrackLiked: Bool {
        return false
    }
    private func formatTime(_ time: TimeInterval) -> String {
        guard !time.isNaN && !time.isInfinite else { return "0:00" }
        
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func getTrackAtQueueIndex(_ index: Int) -> Track? {
        guard index >= 0 && index < queue.count else { return nil }
        return queue[index]
    }
    
    func isTrackCurrentlyPlaying(_ track: Track) -> Bool {
        return currentTrack?.id == track.id
    }
    var playPauseAccessibilityLabel: String {
        return isPlaying ? "Pause" : "Play"
    }
    
    var playPauseAccessibilityHint: String {
        if let trackTitle = currentTrack?.title {
            return isPlaying ? "Pauses \(trackTitle)" : "Plays \(trackTitle)"
        } else {
            return isPlaying ? "Pauses current track" : "Plays current track"
        }
    }
    
    var progressAccessibilityLabel: String {
        return "Playback progress: \(formattedCurrentTime) of \(formattedDuration)"
    }
    
    var volumeAccessibilityLabel: String {
        let percentage = Int(volume * 100)
        return "Volume: \(percentage)%"
    }
}
