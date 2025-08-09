import SwiftUI

struct AlbumDetailView: View {
    let album: Album
    @StateObject private var viewModel = AlbumViewModel()
    @StateObject private var trackViewModel = TrackViewModel()
    @ObservedObject private var musicPlayerService = MusicPlayerService.shared
    
    @State private var scrollOffset: CGFloat = 0
    @State private var headerOpacity: Double = 0
    @State private var showingShareSheet = false
    @State private var isLoading = true
    
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
                        albumHeader
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
        .onAppear {
            loadAlbumDetails()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareText])
        }
    }
    private var backgroundBlur: some View {
        AsyncImage(url: URL(string: album.imageURL ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 20)
                .scaleEffect(1.1)
                .opacity(0.3)
        } placeholder: {
            ThemeManager.shared.colors.surface
                .opacity(0.1)
        }
        .ignoresSafeArea()
    }
    private var albumHeader: some View {
        VStack(spacing: 20) {
            Spacer()
            AlbumArtView(
                imageURL: album.imageURL,
                size: 220,
                isPlaying: musicPlayerService.currentTrack?.albumID == album.id && musicPlayerService.isPlaying
            )
            .shadow(color: ThemeManager.shared.colors.shadow, radius: 20, x: 0, y: 10)
            VStack(spacing: 8) {
                Text(album.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(album.artistName)
                    .font(.title3)
                    .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    .multilineTextAlignment(.center)
                
                if let releaseDate = album.releaseDate {
                    Text(releaseDate)
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.8))
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
    private var actionButtons: some View {
        HStack(spacing: 15) {
            Button(action: playAlbum) {
                HStack(spacing: 8) {
                    Image(systemName: musicPlayerService.currentTrack?.albumID == album.id && musicPlayerService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                    
                    Text(musicPlayerService.currentTrack?.albumID == album.id && musicPlayerService.isPlaying ? "Pause" : "Play")
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
            Button(action: shuffleAlbum) {
                Image(systemName: "shuffle")
                    .font(.title2)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                    .frame(width: 50, height: 50)
                    .background(ThemeManager.shared.colors.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
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
            HStack {
                Text("Tracks")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                
                Spacer()
                
                if !trackViewModel.tracks.isEmpty {
                    Text("\(trackViewModel.tracks.count) songs")
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(ThemeManager.shared.colors.background.opacity(0.95))
            if isLoading {
                loadingView
            } else if trackViewModel.tracks.isEmpty {
                emptyStateView
            } else {
                ForEach(Array(trackViewModel.tracks.enumerated()), id: \.element.id) { index, track in
                    TrackRowView(
                        track: track,
                        trackNumber: index + 1,
                        isCurrentTrack: musicPlayerService.currentTrack?.id == track.id,
                        isPlaying: musicPlayerService.currentTrack?.id == track.id && musicPlayerService.isPlaying
                    ) {
                        playTrack(track, at: index)
                    }
                    .background(ThemeManager.shared.colors.background.opacity(0.95))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(ThemeManager.shared.colors.background.opacity(0.95))
                .ignoresSafeArea(edges: .bottom)
        )
    }
    private var loadingView: some View {
        VStack(spacing: 15) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ThemeManager.shared.colors.accent))
                .scaleEffect(1.2)
            
            Text("Loading tracks...")
                .font(.caption)
                .foregroundColor(ThemeManager.shared.colors.secondaryText)
        }
        .frame(height: 100)
    }
    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Image(systemName: "music.note.list")
                .font(.system(size: 40))
                .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.6))
            
            Text("No tracks available")
                .font(.headline)
                .foregroundColor(ThemeManager.shared.colors.primaryText)
            
            Text("This album doesn't have any tracks to display.")
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
                AlbumArtView(
                    imageURL: album.smallImageURL,
                    size: 50,
                    showShadow: false
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(album.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                        .lineLimit(1)
                    
                    Text(album.artistName)
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                Button(action: playAlbum) {
                    Image(systemName: musicPlayerService.currentTrack?.albumID == album.id && musicPlayerService.isPlaying ? "pause.fill" : "play.fill")
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
        "\(album.name) by \(album.artistName)"
    }
    private func loadAlbumDetails() {
        Task {
            isLoading = true
            await trackViewModel.searchTracks(query: "\(album.artistName) \(album.name)")
            isLoading = false
        }
    }
    
    private func updateHeaderOpacity() {
        let progress = max(0, min(1, (scrollOffset + headerHeight - compactHeaderHeight) / (headerHeight - compactHeaderHeight)))
        headerOpacity = 1 - progress
    }
    
    private func playAlbum() {
        guard !trackViewModel.tracks.isEmpty else { return }
        
        if musicPlayerService.currentTrack?.albumID == album.id && musicPlayerService.isPlaying {
            musicPlayerService.pause()
        } else {
            playTrack(trackViewModel.tracks[0], at: 0)
        }
    }
    
    private func shuffleAlbum() {
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
struct TrackRowView: View {
    let track: Track
    let trackNumber: Int
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
                    
                    if let duration = track.duration {
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    }
                }
                
                Spacer()
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
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationView {
        AlbumDetailView(
            album: Album(
                id: "1",
                name: "Abbey Road",
                artistName: "The Beatles",
                artistID: "1",
                releaseDate: "1969",
                smallImageURL: "https://example.com/small.jpg",
                imageURL: "https://example.com/large.jpg",
                description: "Classic album"
            )
        )
    }
    .preferredColorScheme(.dark)
}
