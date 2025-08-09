import SwiftUI

struct NowPlayingView: View {
    @StateObject private var viewModel = NowPlayingViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var isDragging = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                VStack(spacing: 0) {
                    dragIndicator
                    headerView
                    mainContentView(geometry: geometry)
                    bottomControlsView
                }
                .offset(y: dragOffset)
                .gesture(dragGesture)
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .sheet(isPresented: $viewModel.isShowingQueue) {
            QueueView()
        }
        .sheet(isPresented: $viewModel.isShowingLyrics) {
            LyricsView(track: viewModel.currentTrack)
        }
    }
    private var backgroundView: some View {
        ZStack {
            ThemeManager.shared.colors.background
                .ignoresSafeArea()
            if let imageURL = viewModel.albumArtURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 50)
                        .opacity(0.3)
                } placeholder: {
                    Rectangle()
                        .fill(ThemeManager.shared.colors.surface)
                }
                .ignoresSafeArea()
            }
            LinearGradient(
                colors: [
                    ThemeManager.shared.colors.background.opacity(0.8),
                    ThemeManager.shared.colors.background.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(ThemeManager.shared.colors.secondaryText.opacity(0.5))
            .frame(width: 40, height: 4)
            .padding(.top, 8)
    }
    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.down")
                    .font(.title2)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("NOW PLAYING")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(ThemeManager.shared.colors.secondaryText)
                
                if viewModel.queueCount > 0 {
                    Text("\(viewModel.currentTrackIndex) of \(viewModel.queueCount)")
                        .font(.caption2)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.7))
                }
            }
            
            Spacer()
            
            Button(action: {
            }) {
                Image(systemName: "ellipsis")
                    .font(.title2)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    private func mainContentView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 40) {
            Spacer()
            albumArtView(size: min(geometry.size.width * 0.8, 350))
            trackInfoView
            progressBarView
            playbackControlsView
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    private func albumArtView(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(ThemeManager.shared.colors.shadow)
                .frame(width: size + 20, height: size + 20)
                .blur(radius: 10)
                .offset(y: 5)
            AsyncImage(url: URL(string: viewModel.albumArtURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: size * 0.1)
                    .fill(ThemeManager.shared.colors.surface)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: size * 0.3))
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    )
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.1))
            .rotationEffect(.degrees(viewModel.albumArtRotation))
            .animation(.linear(duration: 0.1), value: viewModel.albumArtRotation)
            if viewModel.isPlaying {
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
                        lineWidth: 2
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(viewModel.albumArtRotation))
                    .animation(.linear(duration: 0.1), value: viewModel.albumArtRotation)
            }
        }
        .onTapGesture {
            if viewModel.hasLyrics {
                viewModel.toggleLyricsVisibility()
            }
        }
    }
    private var trackInfoView: some View {
        VStack(spacing: 8) {
            Text(viewModel.trackTitle)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ThemeManager.shared.colors.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(viewModel.artistName)
                .font(.headline)
                .foregroundColor(ThemeManager.shared.colors.secondaryText)
                .multilineTextAlignment(.center)
            
            if let albumName = viewModel.albumName {
                Text(albumName)
                    .font(.subheadline)
                    .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
    private var progressBarView: some View {
        VStack(spacing: 8) {
            ProgressBarView(
                progress: viewModel.progress,
                currentTime: viewModel.currentTime,
                duration: viewModel.duration,
                onSeek: { time in
                    viewModel.seek(to: time)
                }
            )
            
            HStack {
                Text(viewModel.formattedCurrentTime)
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.colors.secondaryText)
                
                Spacer()
                
                Text(viewModel.formattedRemainingTime)
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.colors.secondaryText)
            }
        }
    }
    private var playbackControlsView: some View {
        HStack(spacing: 40) {
            Button(action: viewModel.playPrevious) {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.hasPrevious ? ThemeManager.shared.colors.primaryText : ThemeManager.shared.colors.secondaryText.opacity(0.5))
            }
            .disabled(!viewModel.hasPrevious)
            Button(action: viewModel.togglePlayPause) {
                ZStack {
                    Circle()
                        .fill(ThemeManager.shared.colors.accent)
                        .frame(width: 70, height: 70)
                        .shadow(color: ThemeManager.shared.colors.shadow, radius: 5, x: 0, y: 2)
                    
                    if viewModel.isBuffering {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: ThemeManager.shared.colors.background))
                    } else {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(ThemeManager.shared.colors.background)
                    }
                }
            }
            .scaleEffect(viewModel.isPlaying ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isPlaying)
            Button(action: viewModel.playNext) {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.hasNext ? ThemeManager.shared.colors.primaryText : ThemeManager.shared.colors.secondaryText.opacity(0.5))
            }
            .disabled(!viewModel.hasNext)
        }
    }
    private var bottomControlsView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    
                    Slider(value: Binding(
                        get: { viewModel.volume },
                        set: { viewModel.setVolume($0) }
                    ), in: 0...1)
                    .accentColor(ThemeManager.shared.colors.accent)
                    
                    Image(systemName: "speaker.3.fill")
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                }
                .padding(.horizontal, 20)
            }
            HStack(spacing: 40) {
                Button(action: viewModel.toggleShuffleMode) {
                    Image(systemName: viewModel.shuffleMode.iconName)
                        .font(.title3)
                        .foregroundColor(viewModel.shuffleMode == .on ? ThemeManager.shared.colors.accent : ThemeManager.shared.colors.secondaryText)
                }
                Button(action: viewModel.toggleLyricsVisibility) {
                    Image(systemName: "quote.bubble")
                        .font(.title3)
                        .foregroundColor(viewModel.hasLyrics ? ThemeManager.shared.colors.primaryText : ThemeManager.shared.colors.secondaryText.opacity(0.5))
                }
                .disabled(!viewModel.hasLyrics)
                Button(action: viewModel.toggleQueueVisibility) {
                    ZStack {
                        Image(systemName: "list.bullet")
                            .font(.title3)
                            .foregroundColor(ThemeManager.shared.colors.primaryText)
                        
                        if viewModel.queueCount > 0 {
                            Circle()
                                .fill(ThemeManager.shared.colors.accent)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                        }
                    }
                }
                Button(action: viewModel.toggleRepeatMode) {
                    Image(systemName: viewModel.repeatMode.iconName)
                        .font(.title3)
                        .foregroundColor(viewModel.repeatMode == .off ? ThemeManager.shared.colors.secondaryText : ThemeManager.shared.colors.accent)
                }
                Button(action: viewModel.shareCurrentTrack) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.y > 0 {
                    dragOffset = value.translation.y
                    isDragging = true
                }
            }
            .onEnded { value in
                if value.translation.y > 100 {
                    presentationMode.wrappedValue.dismiss()
                } else {
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
                isDragging = false
            }
    }
}

#Preview {
    NowPlayingView()
}
