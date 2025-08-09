import SwiftUI

struct ContentView: View {
    @StateObject private var musicPlayerService = MusicPlayerService.shared
    @StateObject private var audioSessionManager = AudioSessionManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var selectedTab: MainTab = .home
    @State private var showingNowPlaying = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                themeManager.colors.background
                    .ignoresSafeArea()
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(MainTab.home)
                    SearchView()
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .tag(MainTab.search)
                    LibraryView()
                        .tabItem {
                            Label("Your Library", systemImage: "books.vertical.fill")
                        }
                        .tag(MainTab.library)
                    PlaylistView()
                        .tabItem {
                            Label("Playlists", systemImage: "music.note.list")
                        }
                        .tag(MainTab.playlists)
                }
                .tint(themeManager.colors.accent)
                .onAppear {
                    setupTabBarAppearance()
                }
                if musicPlayerService.currentTrack != nil && !showingNowPlaying {
                    miniPlayerView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                if showingNowPlaying {
                    NowPlayingView(isPresented: $showingNowPlaying)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingNowPlaying)
        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: musicPlayerService.currentTrack)
        .onAppear {
            setupAudioSession()
        }
    }
    private var miniPlayerView: some View {
        MiniPlayerView(
            showingNowPlaying: $showingNowPlaying,
            dragOffset: $dragOffset,
            isDragging: $isDragging
        )
        .padding(.horizontal, 10)
        .padding(.bottom, 90) // Account for tab bar
        .offset(y: dragOffset.height)
        .opacity(isDragging ? 0.8 : 1.0)
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        AudioServicesPlaySystemSound(1519) // Peek feedback
                    }
                    if value.translation.y < 0 {
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    isDragging = false
                    if value.translation.y < -50 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showingNowPlaying = true
                            dragOffset = .zero
                        }
                        AudioServicesPlaySystemSound(1520) // Pop feedback
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = .zero
                        }
                    }
                }
        )
    }
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(themeManager.colors.surface)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(themeManager.colors.secondaryText)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(themeManager.colors.secondaryText)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(themeManager.colors.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(themeManager.colors.accent)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func setupAudioSession() {
        audioSessionManager.configureAudioSession()
    }
}
struct HomeView: View {
    @StateObject private var artistViewModel = ArtistViewModel()
    @StateObject private var albumViewModel = AlbumViewModel()
    @StateObject private var trackViewModel = TrackViewModel()
    @StateObject private var playlistViewModel = PlaylistViewModel()
    
    @State private var scrollOffset: CGFloat = 0
    @State private var isLoading = true
    
    private let headerHeight: CGFloat = 200
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeManager.shared.colors.background
                    .ignoresSafeArea()
                backgroundGradient
                ScrollView {
                    LazyVStack(spacing: 0) {
                        headerView
                            .frame(height: headerHeight)
                        contentSections
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
                .refreshable {
                    await loadHomeContent()
                }
                customNavigationBar
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await loadHomeContent()
            }
        }
    }
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                ThemeManager.shared.colors.accent.opacity(0.1),
                ThemeManager.shared.colors.background.opacity(0.8),
                ThemeManager.shared.colors.background
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    private var headerView: some View {
        VStack(spacing: 20) {
            Spacer()
            VStack(spacing: 8) {
                Text(greetingMessage)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                
                Text("What would you like to listen to?")
                    .font(.body)
                    .foregroundColor(ThemeManager.shared.colors.secondaryText)
            }
            
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
    private var contentSections: some View {
        VStack(spacing: 30) {
            quickActionsSection
            if !trackViewModel.recentlyPlayed.isEmpty {
                homeSection(
                    title: "Jump back in",
                    subtitle: "Pick up where you left off"
                ) {
                    recentlyPlayedGrid
                }
            }
            homeSection(
                title: "Trending Now",
                subtitle: "What's hot right now"
            ) {
                trendingTracksCarousel
            }
            if !albumViewModel.newReleases.isEmpty {
                homeSection(
                    title: "New Releases",
                    subtitle: "Fresh music for you"
                ) {
                    newReleasesCarousel
                }
            }
            if !artistViewModel.recommendedArtists.isEmpty {
                homeSection(
                    title: "Artists You Might Like",
                    subtitle: "Discover new favorites"
                ) {
                    recommendedArtistsCarousel
                }
            }
            homeSection(
                title: "Made for You",
                subtitle: "Personalized playlists"
            ) {
                madeForYouSection
            }
            if !playlistViewModel.popularPlaylists.isEmpty {
                homeSection(
                    title: "Popular Playlists",
                    subtitle: "What everyone's listening to"
                ) {
                    popularPlaylistsCarousel
                }
            }
            Rectangle()
                .fill(Color.clear)
                .frame(height: 100)
        }
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(ThemeManager.shared.colors.background)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    private var quickActionsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            QuickActionTile(
                icon: "heart.fill",
                title: "Liked Songs",
                color: ThemeManager.shared.colors.accent
            ) {
            }
            
            QuickActionTile(
                icon: "shuffle",
                title: "Shuffle Play",
                color: .green
            ) {
                shuffleAllTracks()
            }
            
            QuickActionTile(
                icon: "arrow.down.circle.fill",
                title: "Downloaded",
                color: .blue
            ) {
            }
            
            QuickActionTile(
                icon: "clock.fill",
                title: "Recently Played",
                color: .orange
            ) {
            }
            
            QuickActionTile(
                icon: "radio",
                title: "Radio",
                color: .purple
            ) {
            }
            
            QuickActionTile(
                icon: "music.note.list",
                title: "Queue",
                color: .pink
            ) {
            }
        }
        .padding(.horizontal, 20)
    }
    private var recentlyPlayedGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(Array(trackViewModel.recentlyPlayed.prefix(6).enumerated()), id: \.element.id) { index, track in
                RecentlyPlayedTile(track: track)
            }
        }
        .padding(.horizontal, 20)
    }
    private var trendingTracksCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
                ForEach(Array(trackViewModel.trendingTracks.prefix(10).enumerated()), id: \.element.id) { index, track in
                    TrendingTrackCard(track: track, rank: index + 1)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    private var newReleasesCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
                ForEach(albumViewModel.newReleases.prefix(10)) { album in
                    NavigationLink(destination: AlbumDetailView(album: album)) {
                        AlbumCard(album: album, size: .medium)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }
    private var recommendedArtistsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
                ForEach(artistViewModel.recommendedArtists.prefix(10)) { artist in
                    NavigationLink(destination: ArtistDetailView(artist: artist)) {
                        RecommendedArtistCard(artist: artist)
                    }
                    .buttonStyle(PlainButtonStyle())
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
                    subtitle: "Your weekly mixtape of fresh music",
                    imageName: "sparkles",
                    gradient: [ThemeManager.shared.colors.accent, .purple]
                )
                
                MadeForYouCard(
                    title: "Daily Mix 1",
                    subtitle: "Made for you",
                    imageName: "music.mic",
                    gradient: [.blue, .cyan]
                )
                
                MadeForYouCard(
                    title: "Release Radar",
                    subtitle: "New music from artists you follow",
                    imageName: "antenna.radiowaves.left.and.right",
                    gradient: [.green, .mint]
                )
                
                MadeForYouCard(
                    title: "On Repeat",
                    subtitle: "Songs you can't stop playing",
                    imageName: "repeat",
                    gradient: [.orange, .yellow]
                )
            }
            .padding(.horizontal, 20)
        }
    }
    private var popularPlaylistsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
                ForEach(playlistViewModel.popularPlaylists.prefix(10)) { playlist in
                    NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                        PlaylistCard(
                            playlist: playlist,
                            size: .medium,
                            showingEditMode: .constant(false),
                            selectedPlaylists: .constant([])
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }
    private var customNavigationBar: some View {
        VStack {
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
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                }
                
                Spacer()
                Button(action: {}) {
                    Image(systemName: "bell")
                        .font(.title3)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                        .frame(width: 32, height: 32)
                }
                Button(action: {}) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .background(
                ThemeManager.shared.colors.background.opacity(
                    max(0, min(1, 1 - (scrollOffset / headerHeight)))
                )
                .background(.ultraThinMaterial)
            )
            
            Spacer()
        }
    }
    private func homeSection<Content: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    }
                }
                
                Spacer()
                
                Button("See All") {
                }
                .font(.body)
                .foregroundColor(ThemeManager.shared.colors.accent)
            }
            .padding(.horizontal, 20)
            
            content()
        }
    }
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Good night"
        }
    }
    
    private func shuffleAllTracks() {
        let allTracks = trackViewModel.tracks
        guard !allTracks.isEmpty else { return }
        
        let shuffledTracks = allTracks.shuffled()
        MusicPlayerService.shared.setQueue(shuffledTracks)
        MusicPlayerService.shared.play(shuffledTracks[0])
    }
    
    private func loadHomeContent() async {
        isLoading = true
        
        async let trendingTracks = trackViewModel.loadTrendingTracks()
        async let newReleases = albumViewModel.loadNewReleases()
        async let recommendedArtists = artistViewModel.loadRecommendedArtists()
        async let popularPlaylists = playlistViewModel.loadPopularPlaylists()
        async let recentlyPlayed = trackViewModel.loadRecentlyPlayed()
        
        await trendingTracks
        await newReleases
        await recommendedArtists
        await popularPlaylists
        await recentlyPlayed
        
        isLoading = false
    }
}
enum MainTab: CaseIterable {
    case home, search, library, playlists
}
struct QuickActionTile: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(12)
            .background(ThemeManager.shared.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
struct RecentlyPlayedTile: View {
    let track: Track
    @ObservedObject private var musicPlayerService = MusicPlayerService.shared
    
    var body: some View {
        Button(action: playTrack) {
            HStack(spacing: 12) {
                AlbumArtView(
                    imageURL: track.albumArtURL,
                    size: 50,
                    cornerRadius: 6,
                    showShadow: false
                )
                
                VStack(alignment: .leading, spacing: 2) {
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
            .padding(8)
            .background(ThemeManager.shared.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func playTrack() {
        musicPlayerService.play(track)
    }
}
struct TrendingTrackCard: View {
    let track: Track
    let rank: Int
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                AlbumArtView(
                    imageURL: track.albumArtURL,
                    size: 140,
                    cornerRadius: 8
                )
                VStack {
                    HStack {
                        Text("#\(rank)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ThemeManager.shared.colors.accent)
                            .clipShape(Capsule())
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(8)
            }
            
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
            .frame(width: 140)
        }
    }
}
struct RecommendedArtistCard: View {
    let artist: Artist
    
    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: URL(string: artist.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(ThemeManager.shared.colors.surface)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    )
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            
            VStack(spacing: 4) {
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
            .frame(width: 120)
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
