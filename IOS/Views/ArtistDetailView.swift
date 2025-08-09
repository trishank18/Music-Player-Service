import SwiftUI

struct ArtistDetailView: View {
    let artist: Artist
    @StateObject private var viewModel = ArtistViewModel()
    @StateObject private var albumViewModel = AlbumViewModel()
    @StateObject private var trackViewModel = TrackViewModel()
    @ObservedObject private var musicPlayerService = MusicPlayerService.shared
    
    @State private var scrollOffset: CGFloat = 0
    @State private var headerOpacity: Double = 0
    @State private var selectedSegment = 0
    @State private var showingShareSheet = false
    @State private var isLoading = true
    
    @Environment(\.presentationMode) var presentationMode
    
    private let headerHeight: CGFloat = 400
    private let compactHeaderHeight: CGFloat = 120
    private let segments = ["Popular", "Albums", "About"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ThemeManager.shared.colors.background
                    .ignoresSafeArea()
                backgroundBlur
                ScrollView {
                    LazyVStack(spacing: 0) {
                        artistHeader
                            .frame(height: headerHeight)
                        segmentControl
                        contentView
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
        .onAppear {
            loadArtistDetails()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareText])
        }
    }
    private var backgroundBlur: some View {
        AsyncImage(url: URL(string: artist.imageURL ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 25)
                .scaleEffect(1.2)
                .opacity(0.2)
        } placeholder: {
            ThemeManager.shared.colors.surface
                .opacity(0.1)
        }
        .ignoresSafeArea()
    }
    private var artistHeader: some View {
        VStack(spacing: 20) {
            Spacer()
            AsyncImage(url: URL(string: artist.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        ThemeManager.shared.colors.accent.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
            } placeholder: {
                Circle()
                    .fill(ThemeManager.shared.colors.surface)
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 60))
                            .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.6))
                    )
            }
            .shadow(color: ThemeManager.shared.colors.shadow, radius: 20, x: 0, y: 10)
            VStack(spacing: 8) {
                Text(artist.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if let genre = artist.genre {
                    Text(genre)
                        .font(.title3)
                        .foregroundColor(ThemeManager.shared.colors.accent)
                        .multilineTextAlignment(.center)
                }
                
                if let country = artist.country {
                    Text(country)
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.8))
                }
            }
            if let formedYear = artist.formedYear {
                HStack(spacing: 30) {
                    VStack(spacing: 4) {
                        Text("Formed")
                            .font(.caption)
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        Text(formedYear)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(ThemeManager.shared.colors.primaryText)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Albums")
                            .font(.caption)
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        Text("\(albumViewModel.albums.count)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(ThemeManager.shared.colors.primaryText)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Genre")
                            .font(.caption)
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        Text(artist.genre?.components(separatedBy: " ").first ?? "Music")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(ThemeManager.shared.colors.primaryText)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 40)
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
    private var actionButtons: some View {
        HStack(spacing: 15) {
            Button(action: playTopTracks) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.title3)
                    
                    Text("Play")
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
            Button(action: shuffleTopTracks) {
                Image(systemName: "shuffle")
                    .font(.title2)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                    .frame(width: 50, height: 50)
                    .background(ThemeManager.shared.colors.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
            Button(action: {}) {
                Image(systemName: "heart")
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
    private var segmentControl: some View {
        HStack(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedSegment = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(segment)
                            .font(.headline)
                            .fontWeight(selectedSegment == index ? .bold : .medium)
                            .foregroundColor(
                                selectedSegment == index 
                                ? ThemeManager.shared.colors.accent 
                                : ThemeManager.shared.colors.secondaryText
                            )
                        
                        Rectangle()
                            .fill(ThemeManager.shared.colors.accent)
                            .frame(height: 2)
                            .opacity(selectedSegment == index ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            ThemeManager.shared.colors.background.opacity(0.95)
                .background(.ultraThinMaterial)
        )
    }
    private var contentView: some View {
        Group {
            switch selectedSegment {
            case 0:
                popularTracksView
            case 1:
                albumsView
            case 2:
                aboutView
            default:
                popularTracksView
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(ThemeManager.shared.colors.background.opacity(0.95))
                .ignoresSafeArea(edges: .bottom)
        )
    }
    private var popularTracksView: some View {
        LazyVStack(spacing: 0) {
            if isLoading {
                loadingView
            } else if trackViewModel.tracks.isEmpty {
                emptyStateView(
                    icon: "music.note",
                    title: "No popular tracks",
                    subtitle: "Check back later for top tracks."
                )
            } else {
                ForEach(Array(trackViewModel.tracks.prefix(10).enumerated()), id: \.element.id) { index, track in
                    PopularTrackRowView(
                        track: track,
                        rank: index + 1,
                        isCurrentTrack: musicPlayerService.currentTrack?.id == track.id,
                        isPlaying: musicPlayerService.currentTrack?.id == track.id && musicPlayerService.isPlaying
                    ) {
                        playTrack(track, at: index)
                    }
                }
            }
        }
    }
    private var albumsView: some View {
        LazyVStack(spacing: 0) {
            if albumViewModel.albums.isEmpty {
                emptyStateView(
                    icon: "square.stack",
                    title: "No albums found",
                    subtitle: "This artist doesn't have any albums available."
                )
            } else {
                ForEach(albumViewModel.albums) { album in
                    NavigationLink(destination: AlbumDetailView(album: album)) {
                        AlbumRowView(album: album)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    private var aboutView: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let biography = artist.biography, !biography.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Biography")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                    
                    Text(biography)
                        .font(.body)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        .lineSpacing(4)
                }
            }
            VStack(alignment: .leading, spacing: 15) {
                Text("Details")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                
                if let genre = artist.genre {
                    DetailRow(title: "Genre", value: genre)
                }
                
                if let country = artist.country {
                    DetailRow(title: "Origin", value: country)
                }
                
                if let formedYear = artist.formedYear {
                    DetailRow(title: "Formed", value: formedYear)
                }
                
                if let style = artist.style {
                    DetailRow(title: "Style", value: style)
                }
            }
            if artist.hasWebsite || artist.hasFacebook || artist.hasTwitter {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Links")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                    
                    HStack(spacing: 20) {
                        if artist.hasWebsite {
                            SocialLinkButton(
                                icon: "globe",
                                title: "Website",
                                url: artist.website
                            )
                        }
                        
                        if artist.hasFacebook {
                            SocialLinkButton(
                                icon: "f.circle",
                                title: "Facebook",
                                url: artist.facebook
                            )
                        }
                        
                        if artist.hasTwitter {
                            SocialLinkButton(
                                icon: "t.circle",
                                title: "Twitter",
                                url: artist.twitter
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    private var loadingView: some View {
        VStack(spacing: 15) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ThemeManager.shared.colors.accent))
                .scaleEffect(1.2)
            
            Text("Loading...")
                .font(.caption)
                .foregroundColor(ThemeManager.shared.colors.secondaryText)
        }
        .frame(height: 100)
    }
    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.6))
            
            Text(title)
                .font(.headline)
                .foregroundColor(ThemeManager.shared.colors.primaryText)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(ThemeManager.shared.colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(height: 150)
        .padding(.horizontal, 40)
    }
    private var compactHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: artist.smallImageURL ?? artist.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(ThemeManager.shared.colors.surface)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.title3)
                                .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        )
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(artist.name)
                        .font(.headline)
                        .fontWeight(.semibold)
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
                Button(action: playTopTracks) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundColor(ThemeManager.shared.colors.background)
                        .frame(width: 40, height: 40)
                        .background(ThemeManager.shared.colors.accent)
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
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
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Spacer()
        }
    }
    private var shareText: String {
        "Check out \(artist.name) on MusicPlayer"
    }
    private func loadArtistDetails() {
        Task {
            isLoading = true
            
            async let albums = albumViewModel.searchAlbums(query: artist.name)
            async let tracks = trackViewModel.searchTracks(query: artist.name)
            
            await albums
            await tracks
            
            isLoading = false
        }
    }
    
    private func updateHeaderOpacity() {
        let progress = max(0, min(1, (scrollOffset + headerHeight - compactHeaderHeight) / (headerHeight - compactHeaderHeight)))
        headerOpacity = 1 - progress
    }
    
    private func playTopTracks() {
        guard !trackViewModel.tracks.isEmpty else { return }
        playTrack(trackViewModel.tracks[0], at: 0)
    }
    
    private func shuffleTopTracks() {
        guard !trackViewModel.tracks.isEmpty else { return }
        
        let shuffledTracks = trackViewModel.tracks.shuffled()
        musicPlayerService.setQueue(shuffledTracks)
        musicPlayerService.play(shuffledTracks[0])
    }
    
    private func playTrack(_ track: Track, at index: Int) {
        musicPlayerService.setQueue(Array(trackViewModel.tracks[index...]))
        musicPlayerService.play(track)
    }
}
struct PopularTrackRowView: View {
    let track: Track
    let rank: Int
    let isCurrentTrack: Bool
    let isPlaying: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                ZStack {
                    if isCurrentTrack && isPlaying {
                        CompactWaveform(
                            height: 20,
                            barCount: 3,
                            color: ThemeManager.shared.colors.accent
                        )
                    } else {
                        Text("\(rank)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(
                                rank <= 3 
                                ? ThemeManager.shared.colors.accent 
                                : ThemeManager.shared.colors.secondaryText
                            )
                    }
                }
                .frame(width: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(
                            isCurrentTrack 
                            ? ThemeManager.shared.colors.accent 
                            : ThemeManager.shared.colors.primaryText
                        )
                        .lineLimit(1)
                    
                    if let album = track.albumName {
                        Text(album)
                            .font(.caption)
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
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
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                isCurrentTrack 
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
struct AlbumRowView: View {
    let album: Album
    
    var body: some View {
        HStack(spacing: 15) {
            AlbumArtView(
                imageURL: album.smallImageURL,
                size: 60,
                showShadow: false
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                    .lineLimit(1)
                
                if let releaseDate = album.releaseDate {
                    Text(releaseDate)
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(ThemeManager.shared.colors.secondaryText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(ThemeManager.shared.colors.secondaryText)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(ThemeManager.shared.colors.primaryText)
            
            Spacer()
        }
    }
}
struct SocialLinkButton: View {
    let icon: String
    let title: String
    let url: String?
    
    var body: some View {
        Button(action: {
            guard let url = url, let validURL = URL(string: url) else { return }
            if UIApplication.shared.canOpenURL(validURL) {
                UIApplication.shared.open(validURL)
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(ThemeManager.shared.colors.accent)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.colors.secondaryText)
            }
            .frame(width: 60, height: 60)
            .background(ThemeManager.shared.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    NavigationView {
        ArtistDetailView(
            artist: Artist(
                id: "1",
                name: "The Beatles",
                biography: "The Beatles were an English rock band formed in Liverpool in 1960.",
                genre: "Rock",
                country: "United Kingdom",
                formedYear: "1960",
                website: "https://thebeatles.com",
                facebook: "https://facebook.com/thebeatles",
                twitter: "https://twitter.com/thebeatles",
                smallImageURL: "https://example.com/small.jpg",
                imageURL: "https://example.com/large.jpg"
            )
        )
    }
    .preferredColorScheme(.dark)
}
