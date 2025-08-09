import SwiftUI

struct LibraryView: View {
    @StateObject private var artistViewModel = ArtistViewModel()
    @StateObject private var albumViewModel = AlbumViewModel()
    @StateObject private var trackViewModel = TrackViewModel()
    @StateObject private var playlistViewModel = PlaylistViewModel()
    
    @State private var selectedTab: LibraryTab = .all
    @State private var searchText = ""
    @State private var sortOption: LibrarySortOption = .recentlyAdded
    @State private var showingSearchView = false
    @State private var showingFilterMenu = false
    
    private let tabs: [LibraryTab] = [.all, .artists, .albums, .tracks, .playlists]
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeManager.shared.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    tabSelector
                    contentView
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadLibraryContent()
            }
            .sheet(isPresented: $showingSearchView) {
                SearchView()
            }
        }
    }
    private var headerView: some View {
        VStack(spacing: 15) {
            HStack {
                Button(action: {}) {
                    AsyncImage(url: URL(string: "https://example.com/profile.jpg")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(ThemeManager.shared.colors.surface)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(ThemeManager.shared.colors.secondaryText)
                            )
                    }
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
                }
                
                Spacer()
                
                Text("Your Library")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                
                Spacer()
                
                HStack(spacing: 15) {
                    Button(action: { showingSearchView = true }) {
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                            .foregroundColor(ThemeManager.shared.colors.primaryText)
                    }
                    
                    Button(action: { showingFilterMenu = true }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.title3)
                            .foregroundColor(ThemeManager.shared.colors.primaryText)
                    }
                    .confirmationDialog("Sort by", isPresented: $showingFilterMenu) {
                        Button("Recently Added") { sortOption = .recentlyAdded }
                        Button("Recently Played") { sortOption = .recentlyPlayed }
                        Button("Alphabetical") { sortOption = .alphabetical }
                        Button("Most Played") { sortOption = .mostPlayed }
                        Button("Cancel", role: .cancel) { }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            if !searchText.isEmpty || showingSearchView {
                SearchBarView(text: $searchText, placeholder: "Find in Your Library")
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(ThemeManager.shared.colors.background)
    }
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tabs, id: \.self) { tab in
                    TabButton(
                        title: tab.title,
                        icon: tab.icon,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 15)
        .background(ThemeManager.shared.colors.background)
    }
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                switch selectedTab {
                case .all:
                    allContentView
                case .artists:
                    artistsContentView
                case .albums:
                    albumsContentView
                case .tracks:
                    tracksContentView
                case .playlists:
                    playlistsContentView
                }
            }
        }
        .refreshable {
            await loadLibraryContent()
        }
    }
    private var allContentView: some View {
        VStack(spacing: 0) {
            quickAccessSection
            if !trackViewModel.recentlyPlayed.isEmpty {
                sectionHeader("Recently Played", showSeeAll: true)
                recentlyPlayedSection
            }
            sectionHeader("Made for You", showSeeAll: false)
            madeForYouSection
            if !albumViewModel.recentlyAdded.isEmpty {
                sectionHeader("Recently Added", showSeeAll: true)
                recentlyAddedSection
            }
        }
    }
    private var quickAccessSection: some View {
        VStack(spacing: 15) {
            sectionHeader("Quick Access", showSeeAll: false)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                QuickAccessRow(
                    icon: "heart.fill",
                    title: "Liked Songs",
                    subtitle: "\(trackViewModel.likedTracks.count) songs",
                    color: ThemeManager.shared.colors.accent
                ) {
                }
                
                QuickAccessRow(
                    icon: "arrow.down.circle.fill",
                    title: "Downloaded",
                    subtitle: "\(trackViewModel.downloadedTracks.count) songs",
                    color: .green
                ) {
                }
                
                QuickAccessRow(
                    icon: "clock.fill",
                    title: "Recently Played",
                    subtitle: "Jump back in",
                    color: .orange
                ) {
                }
                
                QuickAccessRow(
                    icon: "music.note.list",
                    title: "Queue",
                    subtitle: "Up next",
                    color: .purple
                ) {
                }
            }
            .padding(.horizontal, 20)
        }
    }
    private var recentlyPlayedSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
                ForEach(Array(trackViewModel.recentlyPlayed.prefix(10).enumerated()), id: \.element.id) { index, track in
                    RecentlyPlayedCard(track: track, rank: index + 1)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    private var madeForYouSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
                MadeForYouCard(
                    title: "Discover Weekly",
                    subtitle: "Your weekly mixtape",
                    imageName: "sparkles",
                    gradient: [ThemeManager.shared.colors.accent, .purple]
                )
                MadeForYouCard(
                    title: "Release Radar",
                    subtitle: "New music from artists you follow",
                    imageName: "antenna.radiowaves.left.and.right",
                    gradient: [.green, .blue]
                )
                MadeForYouCard(
                    title: "Daily Mix",
                    subtitle: "Made for you",
                    imageName: "music.mic",
                    gradient: [.orange, .red]
                )
            }
            .padding(.horizontal, 20)
        }
    }
    private var recentlyAddedSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
                ForEach(albumViewModel.recentlyAdded.prefix(10)) { album in
                    NavigationLink(destination: AlbumDetailView(album: album)) {
                        AlbumCard(album: album, size: .medium)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }
    private var artistsContentView: some View {
        LazyVStack(spacing: 0) {
            ForEach(filteredArtists) { artist in
                NavigationLink(destination: ArtistDetailView(artist: artist)) {
                    ArtistRow(artist: artist)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if artistViewModel.isLoading {
                ProgressView()
                    .frame(height: 50)
            }
        }
    }
    private var albumsContentView: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 160), spacing: 15)
        ], spacing: 15) {
            ForEach(filteredAlbums) { album in
                NavigationLink(destination: AlbumDetailView(album: album)) {
                    AlbumCard(album: album, size: .small)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }
    private var tracksContentView: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(filteredTracks.enumerated()), id: \.element.id) { index, track in
                TrackRow(track: track, index: index + 1)
            }
            
            if trackViewModel.isLoading {
                ProgressView()
                    .frame(height: 50)
            }
        }
    }
    private var playlistsContentView: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 160), spacing: 15)
        ], spacing: 15) {
            ForEach(filteredPlaylists) { playlist in
                NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                    PlaylistCard(
                        playlist: playlist,
                        size: .small,
                        showingEditMode: .constant(false),
                        selectedPlaylists: .constant([])
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }
    private func sectionHeader(_ title: String, showSeeAll: Bool) -> some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ThemeManager.shared.colors.primaryText)
            
            Spacer()
            
            if showSeeAll {
                Button("See All") {
                }
                .font(.body)
                .foregroundColor(ThemeManager.shared.colors.accent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }
    private var filteredArtists: [Artist] {
        if searchText.isEmpty {
            return artistViewModel.artists
        } else {
            return artistViewModel.artists.filter { artist in
                artist.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var filteredAlbums: [Album] {
        if searchText.isEmpty {
            return albumViewModel.albums
        } else {
            return albumViewModel.albums.filter { album in
                album.name.localizedCaseInsensitiveContains(searchText) ||
                album.artistName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var filteredTracks: [Track] {
        if searchText.isEmpty {
            return trackViewModel.tracks
        } else {
            return trackViewModel.tracks.filter { track in
                track.title.localizedCaseInsensitiveContains(searchText) ||
                track.artistName.localizedCaseInsensitiveContains(searchText) ||
                track.albumName?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    private var filteredPlaylists: [Playlist] {
        if searchText.isEmpty {
            return playlistViewModel.playlists
        } else {
            return playlistViewModel.playlists.filter { playlist in
                playlist.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    private func loadLibraryContent() async {
        async let artists = artistViewModel.loadFavoriteArtists()
        async let albums = albumViewModel.loadUserAlbums()
        async let tracks = trackViewModel.loadUserTracks()
        async let playlists = playlistViewModel.loadPlaylists()
        
        await artists
        await albums
        await tracks
        await playlists
    }
}
enum LibraryTab: CaseIterable {
    case all, artists, albums, tracks, playlists
    
    var title: String {
        switch self {
        case .all: return "All"
        case .artists: return "Artists"
        case .albums: return "Albums"
        case .tracks: return "Songs"
        case .playlists: return "Playlists"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .artists: return "person.fill"
        case .albums: return "square.stack"
        case .tracks: return "music.note"
        case .playlists: return "music.note.list"
        }
    }
}
enum LibrarySortOption {
    case recentlyAdded, recentlyPlayed, alphabetical, mostPlayed
}
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
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
struct QuickAccessRow: View {
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
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.colors.secondaryText)
            }
            .padding(12)
            .background(ThemeManager.shared.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
struct RecentlyPlayedCard: View {
    let track: Track
    let rank: Int
    
    var body: some View {
        VStack(spacing: 8) {
            AlbumArtView(
                imageURL: track.albumArtURL,
                size: 120,
                cornerRadius: 8
            )
            VStack(spacing: 4) {
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
            .frame(width: 120)
        }
    }
}
struct MadeForYouCard: View {
    let title: String
    let subtitle: String
    let imageName: String
    let gradient: [Color]
    
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 160, height: 160)
                .overlay(
                    Image(systemName: imageName)
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.8))
                )
            VStack(spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 160)
        }
    }
}
struct AlbumCard: View {
    let album: Album
    let size: CardSize
    
    enum CardSize {
        case small, medium
        
        var dimensions: CGFloat {
            switch self {
            case .small: return 160
            case .medium: return 180
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            AlbumArtView(
                imageURL: album.imageURL,
                size: size.dimensions,
                cornerRadius: 8
            )
            
            VStack(spacing: 4) {
                Text(album.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                    .lineLimit(1)
                
                Text(album.artistName)
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    .lineLimit(1)
            }
            .frame(width: size.dimensions)
        }
    }
}
struct ArtistRow: View {
    let artist: Artist
    
    var body: some View {
        HStack(spacing: 15) {
            AsyncImage(url: URL(string: artist.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(ThemeManager.shared.colors.surface)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    )
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                    .lineLimit(1)
                
                if let genre = artist.genre {
                    Text(genre)
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(ThemeManager.shared.colors.secondaryText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}
struct TrackRow: View {
    let track: Track
    let index: Int
    @ObservedObject private var musicPlayerService = MusicPlayerService.shared
    
    var body: some View {
        Button(action: playTrack) {
            HStack(spacing: 15) {
                ZStack {
                    if isCurrentTrack && musicPlayerService.isPlaying {
                        CompactWaveform(height: 20, barCount: 3)
                    } else {
                        Text("\(index)")
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
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.body)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var isCurrentTrack: Bool {
        musicPlayerService.currentTrack?.id == track.id
    }
    
    private func playTrack() {
        musicPlayerService.play(track)
    }
}

#Preview {
    LibraryView()
        .preferredColorScheme(.dark)
}
