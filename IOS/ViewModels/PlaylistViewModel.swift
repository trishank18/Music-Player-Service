import Foundation
import Combine

class PlaylistViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var currentPlaylist: Playlist?
    @Published var playlistTracks: [Track] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var sortOption: PlaylistSortOption = .dateCreated
    @Published var isEditing = false
    private let musicPlayer = MusicPlayerService.shared
    private let queueManager = QueueManager.shared
    private var cancellables = Set<AnyCancellable>()
    init() {
        setupObservers()
        loadPlaylists()
    }
    private func setupObservers() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.filterPlaylists()
            }
            .store(in: &cancellables)
        $sortOption
            .sink { [weak self] _ in
                self?.sortPlaylists()
            }
            .store(in: &cancellables)
    }
    func loadPlaylists() {
        isLoading = true
        errorMessage = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.playlists = self?.createSamplePlaylists() ?? []
            self?.isLoading = false
            self?.sortPlaylists()
        }
    }
    
    func createPlaylist(name: String, description: String? = nil) {
        let newPlaylist = Playlist(
            id: UUID().uuidString,
            name: name,
            description: description,
            trackIds: [],
            createdDate: Date(),
            modifiedDate: Date(),
            duration: 0,
            trackCount: 0,
            isUserCreated: true,
            coverImageURL: nil
        )
        
        playlists.append(newPlaylist)
        sortPlaylists()
        savePlaylistsToStorage()
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        if currentPlaylist?.id == playlist.id {
            currentPlaylist = nil
            playlistTracks = []
        }
        savePlaylistsToStorage()
    }
    
    func editPlaylist(_ playlist: Playlist, name: String, description: String?) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].name = name
            playlists[index].description = description
            playlists[index].modifiedDate = Date()
            
            if currentPlaylist?.id == playlist.id {
                currentPlaylist = playlists[index]
            }
            
            savePlaylistsToStorage()
        }
    }
    
    func duplicatePlaylist(_ playlist: Playlist) {
        let duplicatedPlaylist = Playlist(
            id: UUID().uuidString,
            name: "\(playlist.name) Copy",
            description: playlist.description,
            trackIds: playlist.trackIds,
            createdDate: Date(),
            modifiedDate: Date(),
            duration: playlist.duration,
            trackCount: playlist.trackCount,
            isUserCreated: true,
            coverImageURL: playlist.coverImageURL
        )
        
        playlists.append(duplicatedPlaylist)
        sortPlaylists()
        savePlaylistsToStorage()
    }
    func selectPlaylist(_ playlist: Playlist) {
        currentPlaylist = playlist
        loadPlaylistTracks(playlist)
    }
    
    func loadPlaylistTracks(_ playlist: Playlist) {
        playlistTracks = []
        print("Loading tracks for playlist: \(playlist.name)")
    }
    
    func addTrackToPlaylist(_ track: Track, playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].trackIds.append(track.id)
            playlists[index].trackCount += 1
            playlists[index].duration += track.durationInSeconds
            playlists[index].modifiedDate = Date()
            
            if currentPlaylist?.id == playlist.id {
                currentPlaylist = playlists[index]
                playlistTracks.append(track)
            }
            
            savePlaylistsToStorage()
        }
    }
    
    func removeTrackFromPlaylist(_ track: Track, playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].trackIds.removeAll { $0 == track.id }
            playlists[index].trackCount -= 1
            playlists[index].duration -= track.durationInSeconds
            playlists[index].modifiedDate = Date()
            
            if currentPlaylist?.id == playlist.id {
                currentPlaylist = playlists[index]
                playlistTracks.removeAll { $0.id == track.id }
            }
            
            savePlaylistsToStorage()
        }
    }
    
    func moveTrackInPlaylist(from source: Int, to destination: Int) {
        guard let playlist = currentPlaylist,
              let playlistIndex = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[playlistIndex].trackIds.move(fromOffsets: IndexSet(integer: source), toOffset: destination)
        playlists[playlistIndex].modifiedDate = Date()
        playlistTracks.move(fromOffsets: IndexSet(integer: source), toOffset: destination)
        
        currentPlaylist = playlists[playlistIndex]
        savePlaylistsToStorage()
    }
    func playPlaylist(_ playlist: Playlist) {
        print("Playing playlist: \(playlist.name)")
    }
    
    func shufflePlayPlaylist(_ playlist: Playlist) {
        print("Shuffle playing playlist: \(playlist.name)")
    }
    
    func addPlaylistToQueue(_ playlist: Playlist) {
        print("Adding playlist to queue: \(playlist.name)")
    }
    
    func playTrackFromPlaylist(_ track: Track, at index: Int) {
        let startIndex = index
        musicPlayer.playTracks(playlistTracks, startingAt: startIndex)
    }
    private func filterPlaylists() {
        objectWillChange.send()
    }
    
    private func sortPlaylists() {
        switch sortOption {
        case .name:
            playlists.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .dateCreated:
            playlists.sort { $0.createdDate > $1.createdDate }
        case .dateModified:
            playlists.sort { $0.modifiedDate > $1.modifiedDate }
        case .trackCount:
            playlists.sort { $0.trackCount > $1.trackCount }
        case .duration:
            playlists.sort { $0.duration > $1.duration }
        }
    }
    private func savePlaylistsToStorage() {
        print("Saving playlists to storage")
    }
    
    private func loadPlaylistsFromStorage() {
        print("Loading playlists from storage")
    }
    private func createSamplePlaylists() -> [Playlist] {
        return [
            Playlist(
                id: "favorites",
                name: "Favorites",
                description: "Your favorite tracks",
                trackIds: [],
                createdDate: Date().addingTimeInterval(-86400 * 30), // 30 days ago
                modifiedDate: Date().addingTimeInterval(-86400 * 7), // 7 days ago
                duration: 3600, // 1 hour
                trackCount: 15,
                isUserCreated: false,
                coverImageURL: nil
            ),
            Playlist(
                id: "recently_played",
                name: "Recently Played",
                description: "Tracks you've played recently",
                trackIds: [],
                createdDate: Date().addingTimeInterval(-86400 * 7), // 7 days ago
                modifiedDate: Date(),
                duration: 2400, // 40 minutes
                trackCount: 12,
                isUserCreated: false,
                coverImageURL: nil
            ),
            Playlist(
                id: "workout",
                name: "Workout Mix",
                description: "High energy tracks for your workout",
                trackIds: [],
                createdDate: Date().addingTimeInterval(-86400 * 14), // 14 days ago
                modifiedDate: Date().addingTimeInterval(-86400 * 2), // 2 days ago
                duration: 4200, // 70 minutes
                trackCount: 20,
                isUserCreated: true,
                coverImageURL: nil
            )
        ]
    }
    var filteredPlaylists: [Playlist] {
        if searchText.isEmpty {
            return playlists
        } else {
            return playlists.filter { playlist in
                playlist.name.localizedCaseInsensitiveContains(searchText) ||
                (playlist.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var userCreatedPlaylists: [Playlist] {
        return playlists.filter { $0.isUserCreated }
    }
    
    var systemPlaylists: [Playlist] {
        return playlists.filter { !$0.isUserCreated }
    }
    
    var totalPlaylistCount: Int {
        return playlists.count
    }
    
    var totalTrackCount: Int {
        return playlists.reduce(0) { $0 + $1.trackCount }
    }
    
    var totalDuration: TimeInterval {
        return playlists.reduce(0) { $0 + $1.duration }
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
    func isTrackInPlaylist(_ track: Track, playlist: Playlist) -> Bool {
        return playlist.trackIds.contains(track.id)
    }
    
    func canDeletePlaylist(_ playlist: Playlist) -> Bool {
        return playlist.isUserCreated
    }
    
    func getPlaylistForTrack(_ track: Track) -> [Playlist] {
        return playlists.filter { $0.trackIds.contains(track.id) }
    }
    
    func formattedDuration(for playlist: Playlist) -> String {
        let hours = Int(playlist.duration) / 3600
        let minutes = (Int(playlist.duration) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d hr %d min", hours, minutes)
        } else {
            return String(format: "%d min", minutes)
        }
    }
    
    func formattedTrackCount(for playlist: Playlist) -> String {
        return "\(playlist.trackCount) \(playlist.trackCount == 1 ? "track" : "tracks")"
    }
}
struct Playlist: Identifiable, Codable {
    let id: String
    var name: String
    var description: String?
    var trackIds: [String]
    let createdDate: Date
    var modifiedDate: Date
    var duration: TimeInterval
    var trackCount: Int
    let isUserCreated: Bool
    var coverImageURL: String?
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdDate)
    }
    
    var formattedModifiedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: modifiedDate)
    }
}

enum PlaylistSortOption: String, CaseIterable {
    case name = "Name"
    case dateCreated = "Date Created"
    case dateModified = "Recently Modified"
    case trackCount = "Track Count"
    case duration = "Duration"
    
    var displayName: String {
        return rawValue
    }
}
extension Array {
    mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        let reversedSource = source.sorted().reversed()
        
        for index in reversedSource {
            let element = self.remove(at: index)
            let destinationIndex = index < destination ? destination - 1 : destination
            self.insert(element, at: destinationIndex)
        }
    }
}
