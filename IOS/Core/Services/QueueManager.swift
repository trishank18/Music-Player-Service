import Foundation
import Combine

class QueueManager: ObservableObject {
    static let shared = QueueManager()
    @Published var currentTrack: Track?
    @Published var queue: [Track] = []
    @Published var currentIndex: Int = 0
    @Published var originalQueue: [Track] = [] // For shuffle mode
    @Published var history: [Track] = []
    @Published var repeatMode: RepeatMode = .off
    @Published var shuffleMode: ShuffleMode = .off
    var hasNext: Bool {
        switch repeatMode {
        case .single:
            return true
        case .all:
            return true
        case .off:
            return currentIndex < queue.count - 1
        }
    }
    
    var hasPrevious: Bool {
        return currentIndex > 0 || !history.isEmpty
    }
    
    var upcomingTracks: [Track] {
        guard currentIndex < queue.count - 1 else { return [] }
        return Array(queue[(currentIndex + 1)...])
    }
    
    var queueCount: Int {
        return queue.count
    }
    private init() {}
    func addToQueue(_ track: Track) {
        queue.append(track)
        if shuffleMode == .off {
            originalQueue = queue
        }
    }
    
    func addToQueue(_ tracks: [Track]) {
        queue.append(contentsOf: tracks)
        if shuffleMode == .off {
            originalQueue = queue
        }
    }
    
    func insertNext(_ track: Track) {
        let insertIndex = currentIndex + 1
        if insertIndex < queue.count {
            queue.insert(track, at: insertIndex)
        } else {
            queue.append(track)
        }
        
        if shuffleMode == .off {
            originalQueue = queue
        }
    }
    
    func insertNext(_ tracks: [Track]) {
        let insertIndex = currentIndex + 1
        if insertIndex < queue.count {
            queue.insert(contentsOf: tracks, at: insertIndex)
        } else {
            queue.append(contentsOf: tracks)
        }
        
        if shuffleMode == .off {
            originalQueue = queue
        }
    }
    
    func removeFromQueue(at index: Int) {
        guard index < queue.count else { return }
        
        let removedTrack = queue.remove(at: index)
        if index < currentIndex {
            currentIndex -= 1
        } else if index == currentIndex {
            if currentIndex >= queue.count {
                currentIndex = max(0, queue.count - 1)
            }
            setCurrentTrack()
        }
        if shuffleMode == .off {
            originalQueue = queue
        } else {
            if let originalIndex = originalQueue.firstIndex(of: removedTrack) {
                originalQueue.remove(at: originalIndex)
            }
        }
    }
    
    func moveTrack(from source: Int, to destination: Int) {
        guard source < queue.count && destination < queue.count else { return }
        
        let track = queue.remove(at: source)
        queue.insert(track, at: destination)
        if source == currentIndex {
            currentIndex = destination
        } else if source < currentIndex && destination >= currentIndex {
            currentIndex -= 1
        } else if source > currentIndex && destination <= currentIndex {
            currentIndex += 1
        }
        
        if shuffleMode == .off {
            originalQueue = queue
        }
    }
    
    func clearQueue() {
        queue.removeAll()
        originalQueue.removeAll()
        history.removeAll()
        currentIndex = 0
        currentTrack = nil
    }
    func playTrack(_ track: Track) {
        if let index = queue.firstIndex(of: track) {
            playTrack(at: index)
        } else {
            queue.insert(track, at: 0)
            if shuffleMode == .off {
                originalQueue = queue
            }
            playTrack(at: 0)
        }
    }
    
    func playTrack(at index: Int) {
        guard index < queue.count else { return }
        if let current = currentTrack {
            addToHistory(current)
        }
        
        currentIndex = index
        setCurrentTrack()
    }
    
    func playTracks(_ tracks: [Track], startingAt index: Int = 0) {
        clearQueue()
        addToQueue(tracks)
        
        if shuffleMode == .on {
            shuffleQueue()
        }
        
        playTrack(at: index)
    }
    
    func playNext() {
        guard !queue.isEmpty else { return }
        
        switch repeatMode {
        case .single:
            setCurrentTrack()
            return
        case .all:
            if currentIndex >= queue.count - 1 {
                currentIndex = 0
            } else {
                currentIndex += 1
            }
        case .off:
            if currentIndex < queue.count - 1 {
                currentIndex += 1
            } else {
                return
            }
        }
        
        if let current = currentTrack {
            addToHistory(current)
        }
        
        setCurrentTrack()
    }
    
    func playPrevious() {
        if !history.isEmpty {
            let previousTrack = history.removeLast()
            if let index = queue.firstIndex(of: previousTrack) {
                currentIndex = index
                setCurrentTrack()
                return
            }
        }
        if currentIndex > 0 {
            currentIndex -= 1
            setCurrentTrack()
        } else if repeatMode == .all && !queue.isEmpty {
            currentIndex = queue.count - 1
            setCurrentTrack()
        }
    }
    
    private func setCurrentTrack() {
        guard currentIndex < queue.count else {
            currentTrack = nil
            return
        }
        
        currentTrack = queue[currentIndex]
    }
    func enableShuffle() {
        guard shuffleMode == .off else { return }
        
        shuffleMode = .on
        originalQueue = queue
        shuffleQueue()
    }
    
    func disableShuffle() {
        guard shuffleMode == .on else { return }
        
        shuffleMode = .off
        if let currentTrack = currentTrack,
           let originalIndex = originalQueue.firstIndex(of: currentTrack) {
            queue = originalQueue
            currentIndex = originalIndex
        } else {
            queue = originalQueue
            currentIndex = 0
        }
    }
    
    private func shuffleQueue() {
        guard shuffleMode == .on else { return }
        
        let currentTrack = self.currentTrack
        if let current = currentTrack,
           let currentIdx = queue.firstIndex(of: current) {
            queue.remove(at: currentIdx)
        }
        queue.shuffle()
        if let current = currentTrack {
            queue.insert(current, at: 0)
            currentIndex = 0
        }
    }
    private func addToHistory(_ track: Track) {
        history.append(track)
        if history.count > 50 {
            history.removeFirst()
        }
    }
    
    func clearHistory() {
        history.removeAll()
    }
    func getQueuePosition(for track: Track) -> Int? {
        return queue.firstIndex(of: track)
    }
    
    func getTrack(at index: Int) -> Track? {
        guard index < queue.count else { return nil }
        return queue[index]
    }
    
    func isCurrentTrack(_ track: Track) -> Bool {
        return currentTrack == track
    }
    
    func isInQueue(_ track: Track) -> Bool {
        return queue.contains(track)
    }
    func addSimilarTracks(to track: Track) {
        print("Adding similar tracks to queue for: \(track.title)")
    }
    
    func createRadioStation(from track: Track) {
        print("Creating radio station from: \(track.title)")
    }
}
