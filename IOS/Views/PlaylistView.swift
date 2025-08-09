import SwiftUI

struct PlaylistView: View {
    @StateObject private var viewModel = PlaylistViewModel()
    @ObservedObject private var musicPlayerService = MusicPlayerService.shared
    
    @State private var showingCreatePlaylist = false
    @State private var showingEditMode = false
    @State private var selectedPlaylists: Set<String> = []
    @State private var searchText = ""
    @State private var sortOption: PlaylistSortOption = .recentlyPlayed
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 15)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeManager.shared.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    if viewModel.playlists.isEmpty && !viewModel.isLoading {
                        emptyStateView
                    } else {
                        playlistContent
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadPlaylists()
            }
            .sheet(isPresented: $showingCreatePlaylist) {
                CreatePlaylistView { playlist in
                    viewModel.addPlaylist(playlist)
                }
            }
        }
    }
    private var headerView: some View {
        VStack(spacing: 20) {
            HStack {
                if showingEditMode {
                    Button("Cancel") {
                        showingEditMode = false
                        selectedPlaylists.removeAll()
                    }
                    .foregroundColor(ThemeManager.shared.colors.secondaryText)
                } else {
                    Button(action: {}) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(ThemeManager.shared.colors.primaryText)
                    }
                }
                
                Spacer()
                
                Text("Your Library")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                
                Spacer()
                
                if !showingEditMode {
                    Button("Edit") {
                        showingEditMode = true
                    }
                    .foregroundColor(ThemeManager.shared.colors.accent)
                } else if !selectedPlaylists.isEmpty {
                    Button("Delete") {
                        deleteSelectedPlaylists()
                    }
                    .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            SearchBarView(text: $searchText, placeholder: "Find in Your Library")
                .padding(.horizontal, 20)
            HStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(title: "Recently Played", isSelected: sortOption == .recentlyPlayed) {
                            sortOption = .recentlyPlayed
                            sortPlaylists()
                        }
                        
                        FilterChip(title: "Recently Added", isSelected: sortOption == .recentlyAdded) {
                            sortOption = .recentlyAdded
                            sortPlaylists()
                        }
                        
                        FilterChip(title: "Alphabetical", isSelected: sortOption == .alphabetical) {
                            sortOption = .alphabetical
                            sortPlaylists()
                        }
                        
                        FilterChip(title: "Most Played", isSelected: sortOption == .mostPlayed) {
                            sortOption = .mostPlayed
                            sortPlaylists()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                Button(action: {}) {
                    Image(systemName: "rectangle.grid.2x2")
                        .font(.title3)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                }
            }
            .padding(.horizontal, 20)
            quickActionsView
        }
        .background(ThemeManager.shared.colors.background)
    }
    private var quickActionsView: some View {
        HStack(spacing: 15) {
            QuickActionCard(
                icon: "clock",
                title: "Recently Played",
                subtitle: "Jump back in",
                color: ThemeManager.shared.colors.accent
            ) {
            }
            QuickActionCard(
                icon: "plus",
                title: "Create Playlist",
                subtitle: "New collection",
                color: ThemeManager.shared.colors.accent.opacity(0.8)
            ) {
                showingCreatePlaylist = true
            }
        }
        .padding(.horizontal, 20)
    }
    private var playlistContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if !viewModel.recommendedPlaylists.isEmpty {
                    sectionHeader("Made for You")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 15) {
                            ForEach(viewModel.recommendedPlaylists) { playlist in
                                PlaylistCard(
                                    playlist: playlist,
                                    size: .medium,
                                    showingEditMode: $showingEditMode,
                                    selectedPlaylists: $selectedPlaylists
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                if !filteredPlaylists.isEmpty {
                    sectionHeader("Your Playlists")
                    
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(filteredPlaylists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                                PlaylistCard(
                                    playlist: playlist,
                                    size: .small,
                                    showingEditMode: $showingEditMode,
                                    selectedPlaylists: $selectedPlaylists
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ThemeManager.shared.colors.accent))
                        .frame(height: 100)
                }
            }
        }
    }
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 80))
                    .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.6))
                
                VStack(spacing: 8) {
                    Text("Your library is empty")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                    
                    Text("Create your first playlist to get started")
                        .font(.body)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: { showingCreatePlaylist = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.headline)
                        
                        Text("Create Playlist")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(ThemeManager.shared.colors.background)
                    .frame(width: 200, height: 50)
                    .background(ThemeManager.shared.colors.accent)
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ThemeManager.shared.colors.primaryText)
            
            Spacer()
            
            Button("See All") {
            }
            .font(.body)
            .foregroundColor(ThemeManager.shared.colors.accent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }
    private var filteredPlaylists: [Playlist] {
        if searchText.isEmpty {
            return viewModel.playlists
        } else {
            return viewModel.playlists.filter { playlist in
                playlist.name.localizedCaseInsensitiveContains(searchText) ||
                playlist.description?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    private func loadPlaylists() {
        Task {
            await viewModel.loadPlaylists()
        }
    }
    
    private func sortPlaylists() {
        viewModel.sortPlaylists(by: sortOption)
    }
    
    private func deleteSelectedPlaylists() {
        for playlistId in selectedPlaylists {
            viewModel.deletePlaylist(id: playlistId)
        }
        selectedPlaylists.removeAll()
        showingEditMode = false
    }
}
enum PlaylistSortOption {
    case recentlyPlayed
    case recentlyAdded
    case alphabetical
    case mostPlayed
}
struct PlaylistCard: View {
    let playlist: Playlist
    let size: CardSize
    @Binding var showingEditMode: Bool
    @Binding var selectedPlaylists: Set<String>
    
    @State private var isPressed = false
    
    enum CardSize {
        case small, medium, large
        
        var dimensions: CGFloat {
            switch self {
            case .small: return 160
            case .medium: return 200
            case .large: return 250
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                if playlist.tracks.isEmpty {
                    placeholderArtwork
                } else {
                    GridAlbumArtView(
                        albums: playlist.albums,
                        size: size.dimensions
                    )
                }
                if showingEditMode {
                    selectionOverlay
                }
                if !showingEditMode {
                    playButtonOverlay
                }
            }
            .frame(width: size.dimensions, height: size.dimensions)
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let description = playlist.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        .lineLimit(2)
                } else {
                    Text("\(playlist.tracks.count) songs")
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                }
            }
            .frame(width: size.dimensions, alignment: .leading)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            if showingEditMode {
                toggleSelection()
            }
        }
        .onLongPressGesture(
            minimumDuration: 0.1,
            maximumDistance: 50,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
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
            .overlay(
                Image(systemName: "music.note.list")
                    .font(.system(size: size.dimensions * 0.3))
                    .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.6))
            )
    }
    private var selectionOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black.opacity(0.4))
            .overlay(
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundColor(isSelected ? ThemeManager.shared.colors.accent : .white)
            )
    }
    private var playButtonOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: playPlaylist) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundColor(ThemeManager.shared.colors.background)
                        .frame(width: 40, height: 40)
                        .background(ThemeManager.shared.colors.accent)
                        .clipShape(Circle())
                        .shadow(color: ThemeManager.shared.colors.shadow, radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .opacity(0.9)
            }
        }
        .padding(12)
    }
    private var isSelected: Bool {
        selectedPlaylists.contains(playlist.id)
    }
    private func toggleSelection() {
        if isSelected {
            selectedPlaylists.remove(playlist.id)
        } else {
            selectedPlaylists.insert(playlist.id)
        }
    }
    
    private func playPlaylist() {
        guard !playlist.tracks.isEmpty else { return }
        
        MusicPlayerService.shared.setQueue(playlist.tracks)
        MusicPlayerService.shared.play(playlist.tracks[0])
    }
}
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                }
                
                Spacer()
            }
            .padding(15)
            .background(ThemeManager.shared.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(
                    isSelected 
                    ? ThemeManager.shared.colors.background 
                    : ThemeManager.shared.colors.secondaryText
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected 
                    ? ThemeManager.shared.colors.accent 
                    : ThemeManager.shared.colors.surface
                )
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
struct SearchBarView: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundColor(ThemeManager.shared.colors.secondaryText)
            
            TextField(placeholder, text: $text)
                .font(.body)
                .foregroundColor(ThemeManager.shared.colors.primaryText)
                .tint(ThemeManager.shared.colors.accent)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ThemeManager.shared.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    PlaylistView()
        .preferredColorScheme(.dark)
}
