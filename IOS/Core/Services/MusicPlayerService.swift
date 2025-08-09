import Foundation
import AVFoundation
import Combine
import MediaPlayer

class MusicPlayerService: NSObject, ObservableObject {
    static let shared = MusicPlayerService()
    @Published var currentTrack: Track?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 1.0
    @Published var repeatMode: RepeatMode = .off
    @Published var shuffleMode: ShuffleMode = .off
    @Published var playbackState: PlaybackState = .stopped
    @Published var isBuffering: Bool = false
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private let queueManager = QueueManager.shared
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
    override init() {
        super.init()
        setupPlayer()
        setupRemoteControl()
        setupNotifications()
        setupQueueObservation()
    }
    
    deinit {
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self)
    }
    private func setupPlayer() {
        player = AVPlayer()
        player?.volume = volume
        addTimeObserver()
    }
    
    private func setupRemoteControl() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: event.positionTime)
                return .success
            }
            return .commandFailed
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemFailedToPlay),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: nil
        )
    }
    
    private func setupQueueObservation() {
        queueManager.$currentTrack
            .sink { [weak self] track in
                if let track = track, track != self?.currentTrack {
                    self?.loadTrack(track)
                }
            }
            .store(in: &cancellables)
    }
    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }
    
    private func removeTimeObserver() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    func play() {
        guard let player = player else { return }
        
        if currentTrack == nil {
            queueManager.playNext()
            return
        }
        
        player.play()
        isPlaying = true
        playbackState = .playing
        updateNowPlayingInfo()
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        playbackState = .paused
        updateNowPlayingInfo()
    }
    
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        currentTime = 0
        playbackState = .stopped
        currentTrack = nil
        clearNowPlayingInfo()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func playNext() {
        queueManager.playNext()
    }
    
    func playPrevious() {
        queueManager.playPrevious()
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime) { [weak self] _ in
            self?.currentTime = time
        }
    }
    
    func setVolume(_ volume: Float) {
        self.volume = max(0.0, min(1.0, volume))
        player?.volume = self.volume
    }
    private func loadTrack(_ track: Track) {
        currentTrack = track
        isBuffering = true
        playbackState = .buffering
        guard let urlString = track.preview ?? generateMockAudioURL(for: track),
              let url = URL(string: urlString) else {
            playbackState = .error(.invalidURL)
            isBuffering = false
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: playerItem)
        playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .readyToPlay:
                        self?.isBuffering = false
                        self?.duration = playerItem.duration.seconds
                        self?.playbackState = .paused
                        self?.updateNowPlayingInfo()
                    case .failed:
                        self?.isBuffering = false
                        self?.playbackState = .error(.audioSessionError)
                    case .unknown:
                        break
                    @unknown default:
                        break
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func generateMockAudioURL(for track: Track) -> String? {
        return "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
    }
    func addToQueue(_ track: Track) {
        queueManager.addToQueue(track)
    }
    
    func addToQueue(_ tracks: [Track]) {
        queueManager.addToQueue(tracks)
    }
    
    func playTrack(_ track: Track) {
        queueManager.playTrack(track)
    }
    
    func playTracks(_ tracks: [Track], startingAt index: Int = 0) {
        queueManager.playTracks(tracks, startingAt: index)
    }
    
    func clearQueue() {
        queueManager.clearQueue()
    }
    
    func removeFromQueue(at index: Int) {
        queueManager.removeFromQueue(at: index)
    }
    
    func moveTrackInQueue(from source: Int, to destination: Int) {
        queueManager.moveTrack(from: source, to: destination)
    }
    func toggleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .single
        case .single:
            repeatMode = .off
        }
        queueManager.repeatMode = repeatMode
    }
    
    func toggleShuffleMode() {
        shuffleMode = shuffleMode == .off ? .on : .off
        queueManager.shuffleMode = shuffleMode
    }
    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            clearNowPlayingInfo()
            return
        }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.artistName
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = track.albumName ?? ""
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    @objc private func playerDidFinishPlaying() {
        switch repeatMode {
        case .single:
            seek(to: 0)
            play()
        case .all, .off:
            playNext()
        }
    }
    
    @objc private func playerItemFailedToPlay() {
        playbackState = .error(.audioSessionError)
        isBuffering = false
    }
    private func formatTime(_ time: TimeInterval) -> String {
        guard !time.isNaN && !time.isInfinite else { return "0:00" }
        
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
