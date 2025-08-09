import SwiftUI

struct PlaylistDetailView: View {
    let playlist: Playlist
    @StateObject private var viewModel = PlaylistViewModel()
    @ObservedObject private var musicPlayerService = MusicPlayerService.shared
    
    @State private var scrollOffset: CGFloat = 0
    @State private var headerOpacity: Double = 0
    @State private var showingEditMode = false
    @State private var showingAddTracks = false
    @State private var showingShareSheet = false
    @State private var selectedTracks: Set<String> = []
    
    @Environment(\.presentationMode) var presentationMode
    
    private let headerHeight: CGFloat = 350
    private let compactHeaderHeight: CGFloat = 120
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ThemeManager.shared.colors.background
                    .ignoresSafeArea()
                backgroundBlur
                ScrollView {
                    LazyVStack(spacing: 0) {
                        playlistHeader
                            .frame(height: headerHeight)
                        trackListSection
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    updateHeaderOpacity()
                }
                compactHeader
                    .opacity(headerOpacity)
                customNavigationBar
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddTracks) {
            AddTracksToPlaylistView(playlist: playlist) { tracks in
                viewModel.addTracks(tracks, to: playlist)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareText])
        }
    }
    private var backgroundBlur: some View {
        AsyncImage(url: URL(string: playlist.imageURL ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 20)
                .scaleEffect(1.1)
                .opacity(0.3)
        } placeholder: {
            LinearGradient(
                colors: [
                    ThemeManager.shared.colors.accent.opacity(0.2),
                    ThemeManager.shared.colors.surface.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
    private var playlistHeader: some View {
        VStack(spacing: 20) {
            Spacer()
            if playlist.tracks.isEmpty {
                placeholderArtwork
            } else {
                GridAlbumArtView(
                    albums: playlist.albums,
                    size: 220
                )
            }
            VStack(spacing: 8) {
                Text(playlist.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if let description = playlist.description {
                    Text(description)
                        .font(.body)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
                HStack(spacing: 15) {
                    Text("By \(playlist.creator)")
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    
                    if !playlist.tracks.isEmpty {
                        Text("•")
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        
                        Text("\(playlist.tracks.count) songs")
                            .font(.caption)
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    }
                    
                    if let duration = playlist.totalDuration {
                        Text("•")
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    }
                }
            }
            actionButtons
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geo.frame(in: .named("scroll")).minY
                    )
            }
        )
    }
    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        ThemeManager.shared.colors.surface,
                        ThemeManager.shared.colors.surface.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 220, height: 220)
            .overlay(
                Image(systemName: "music.note.list")
                    .font(.system(size: 60))
                    .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.6))
            )
            .themeShadow(style: .dramatic)
    }
    private var actionButtons: some View {
        HStack(spacing: 15) {
            if !playlist.tracks.isEmpty {
                Button(action: playPlaylist) {
                    HStack(spacing: 8) {
                        Image(systemName: isPlaylistPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                        
                        Text(isPlaylistPlaying ? "Pause" : "Play")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(ThemeManager.shared.colors.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(ThemeManager.shared.colors.accent)
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                Button(action: shufflePlaylist) {
                    Image(systemName: "shuffle")
                        .font(.title2)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                        .frame(width: 50, height: 50)
                        .background(ThemeManager.shared.colors.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
            } else {
                Button(action: { showingAddTracks = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.title3)
                        
                        Text("Add Songs")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(ThemeManager.shared.colors.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(ThemeManager.shared.colors.accent)
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
            }
            Button(action: { showingShareSheet = true }) {
                Image(systemName: "ellipsis")
                    .font(.title2)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                    .frame(width: 50, height: 50)
                    .background(ThemeManager.shared.colors.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 20)
    }
    private var trackListSection: some View {
        LazyVStack(spacing: 0) {
            if !playlist.tracks.isEmpty {
                HStack {
                    if showingEditMode {
                        Button("Done") {
                            showingEditMode = false
                            selectedTracks.removeAll()
                        }
                        .foregroundColor(ThemeManager.shared.colors.accent)
                    } else {
                        Button("Edit") {
                            showingEditMode = true
                        }
                        .foregroundColor(ThemeManager.shared.colors.accent)
                    }
                    
                    Spacer()
                    
                    if showingEditMode && !selectedTracks.isEmpty {
                        Button("Remove Selected") {
                            removeSelectedTracks()
                        }
                        .foregroundColor(.red)
                    } else if !showingEditMode {
                        Button(action: { showingAddTracks = true }) {
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(ThemeManager.shared.colors.accent)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(ThemeManager.shared.colors.background.opacity(0.95))
                ForEach(Array(playlist.tracks.enumerated()), id: \.element.id) { index, track in
                    PlaylistTrackRowView(
                        track: track,
                        trackNumber: index + 1,
                        isCurrentTrack: musicPlayerService.currentTrack?.id == track.id,
                        isPlaying: musicPlayerService.currentTrack?.id == track.id && musicPlayerService.isPlaying,
                        isEditMode: showingEditMode,
                        isSelected: selectedTracks.contains(track.id),
                        onTap: {
                            if showingEditMode {
                                toggleTrackSelection(track.id)
                            } else {
                                playTrack(track, at: index)
                            }
                        },
                        onRemove: {
                            removeTrack(track)
                        }
                    )
                    .background(ThemeManager.shared.colors.background.opacity(0.95))
                }
            } else {
                emptyStateView
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(ThemeManager.shared.colors.background.opacity(0.95))
                .ignoresSafeArea(edges: .bottom)
        )
    }
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No songs in this playlist")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                
                Text("Add some songs to get started")
                    .font(.body)
                    .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddTracks = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.headline)
                    
                    Text("Add Songs")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(ThemeManager.shared.colors.background)
                .frame(width: 150, height: 44)
                .background(ThemeManager.shared.colors.accent)
                .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(height: 250)
        .padding(.horizontal, 40)
    }
    private var compactHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if playlist.tracks.isEmpty {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ThemeManager.shared.colors.surface)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "music.note.list")
                                .font(.title3)
                                .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        )
                } else {
                    GridAlbumArtView(
                        albums: playlist.albums,
                        size: 50
                    )
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(playlist.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                        .lineLimit(1)
                    
                    Text("\(playlist.tracks.count) songs")
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                if !playlist.tracks.isEmpty {
                    Button(action: playPlaylist) {
                        Image(systemName: isPlaylistPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(ThemeManager.shared.colors.background)
                            .frame(width: 40, height: 40)
                            .background(ThemeManager.shared.colors.accent)
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                ThemeManager.shared.colors.background.opacity(0.95)
                    .background(.ultraThinMaterial)
            )
            
            Divider()
                .background(ThemeManager.shared.colors.surface)
        }
        .frame(maxWidth: .infinity)
        .frame(height: compactHeaderHeight)
    }
    private var customNavigationBar: some View {
        VStack {
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(ThemeManager.shared.colors.surface.opacity(0.8))
                                .background(.ultraThinMaterial, in: Circle())
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                
                Spacer()
                
                HStack(spacing: 15) {
                    Button(action: { showingAddTracks = true }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(ThemeManager.shared.colors.primaryText)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(ThemeManager.shared.colors.surface.opacity(0.8))
                                    .background(.ultraThinMaterial, in: Circle())
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(ThemeManager.shared.colors.primaryText)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(ThemeManager.shared.colors.surface.opacity(0.8))
                                    .background(.ultraThinMaterial, in: Circle())
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Spacer()
        }
    }
    private var shareText: String {
        "Check out \(playlist.name) playlist"
    }
    
    private var isPlaylistPlaying: Bool {
        playlist.tracks.contains { track in
            musicPlayerService.currentTrack?.id == track.id && musicPlayerService.isPlaying
        }
    }
    private func updateHeaderOpacity() {
        let progress = max(0, min(1, (scrollOffset + headerHeight - compactHeaderHeight) / (headerHeight - compactHeaderHeight)))
        headerOpacity = 1 - progress
    }
    
    private func playPlaylist() {
        guard !playlist.tracks.isEmpty else { return }
        
        if isPlaylistPlaying {
            musicPlayerService.pause()
        } else {
            musicPlayerService.setQueue(playlist.tracks)
            musicPlayerService.play(playlist.tracks[0])
        }
    }
    
    private func shufflePlaylist() {
        guard !playlist.tracks.isEmpty else { return }
        
        let shuffledTracks = playlist.tracks.shuffled()
        musicPlayerService.setQueue(shuffledTracks)
        musicPlayerService.play(shuffledTracks[0])
    }
    
    private func playTrack(_ track: Track, at index: Int) {
        musicPlayerService.setQueue(Array(playlist.tracks[index...]))
        musicPlayerService.play(track)
    }
    
    private func toggleTrackSelection(_ trackId: String) {
        if selectedTracks.contains(trackId) {
            selectedTracks.remove(trackId)
        } else {
            selectedTracks.insert(trackId)
        }
    }
    
    private func removeTrack(_ track: Track) {
        viewModel.removeTrack(track, from: playlist)
    }
    
    private func removeSelectedTracks() {
        let tracksToRemove = playlist.tracks.filter { selectedTracks.contains($0.id) }
        for track in tracksToRemove {
            viewModel.removeTrack(track, from: playlist)
        }
        selectedTracks.removeAll()
        showingEditMode = false
    }
    
    private func formatDuration(_ duration: Int) -> String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        
        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }
}
struct PlaylistTrackRowView: View {
    let track: Track
    let trackNumber: Int
    let isCurrentTrack: Bool
    let isPlaying: Bool
    let isEditMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                ZStack {
                    if isEditMode {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(isSelected ? ThemeManager.shared.colors.accent : ThemeManager.shared.colors.secondaryText)
                    } else if isCurrentTrack && isPlaying {
                        CompactWaveform(
                            height: 20,
                            barCount: 3,
                            color: ThemeManager.shared.colors.accent
                        )
                    } else {
                        Text("\(trackNumber)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(
                                isCurrentTrack 
                                ? ThemeManager.shared.colors.accent 
                                : ThemeManager.shared.colors.secondaryText
                            )
                    }
                }
                .frame(width: 30)
                AlbumArtView(
                    imageURL: track.albumArtURL,
                    size: 50,
                    cornerRadius: 6,
                    showShadow: false
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(
                            isCurrentTrack 
                            ? ThemeManager.shared.colors.accent 
                            : ThemeManager.shared.colors.primaryText
                        )
                        .lineLimit(1)
                    
                    Text(track.artistName)
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                if isEditMode {
                    Button(action: onRemove) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    if let duration = track.duration {
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                isCurrentTrack && !isEditMode
                ? ThemeManager.shared.colors.surface.opacity(0.5)
                : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
struct AddTracksToPlaylistView: View {
    let playlist: Playlist
    let onTracksAdded: ([Track]) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var trackViewModel = TrackViewModel()
    @State private var searchText = ""
    @State private var selectedTracks: Set<String> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBarView(text: $searchText, placeholder: "Search for songs")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredTracks) { track in
                            AddTrackRowView(
                                track: track,
                                isSelected: selectedTracks.contains(track.id)
                            ) {
                                toggleTrackSelection(track.id)
                            }
                        }
                    }
                }
            }
            .background(ThemeManager.shared.colors.background)
            .navigationTitle("Add Songs")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addSelectedTracks()
                    }
                    .disabled(selectedTracks.isEmpty)
                }
            }
        }
        .onAppear {
            Task {
                await trackViewModel.loadUserTracks()
            }
        }
    }
    
    private var filteredTracks: [Track] {
        if searchText.isEmpty {
            return trackViewModel.tracks.filter { track in
                !playlist.tracks.contains { $0.id == track.id }
            }
        } else {
            return trackViewModel.tracks.filter { track in
                !playlist.tracks.contains { $0.id == track.id } &&
                (track.title.localizedCaseInsensitiveContains(searchText) ||
                 track.artistName.localizedCaseInsensitiveContains(searchText))
            }
        }
    }
    
    private func toggleTrackSelection(_ trackId: String) {
        if selectedTracks.contains(trackId) {
            selectedTracks.remove(trackId)
        } else {
            selectedTracks.insert(trackId)
        }
    }
    
    private func addSelectedTracks() {
        let tracksToAdd = trackViewModel.tracks.filter { selectedTracks.contains($0.id) }
        onTracksAdded(tracksToAdd)
        presentationMode.wrappedValue.dismiss()
    }
}
struct AddTrackRowView: View {
    let track: Track
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? ThemeManager.shared.colors.accent : ThemeManager.shared.colors.secondaryText)
                AlbumArtView(
                    imageURL: track.albumArtURL,
                    size: 50,
                    cornerRadius: 6,
                    showShadow: false
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                        .lineLimit(1)
                    
                    Text(track.artistName)
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                isSelected 
                ? ThemeManager.shared.colors.surface.opacity(0.5)
                : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PlaylistDetailView(
        playlist: Playlist(
            id: "1",
            name: "My Awesome Playlist",
            description: "A collection of my favorite songs",
            imageURL: nil,
            isPublic: false,
            createdDate: Date(),
            tracks: [],
            creator: "User"
        )
    )
    .preferredColorScheme(.dark)
}
