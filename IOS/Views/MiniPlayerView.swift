import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var musicPlayerService: MusicPlayerService
    @State private var isShowingNowPlaying = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDismissed = false
    
    var body: some View {
        HStack(spacing: 12) {
            albumArtView
            trackInfoView
            
            Spacer()
            controlsView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(blurBackground)
        .cornerRadius(12)
        .shadow(color: ThemeManager.shared.colors.shadow, radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
        .padding(.bottom, 100) // Account for tab bar
        .offset(y: dragOffset)
        .opacity(isDismissed ? 0 : 1)
        .gesture(dragGesture)
        .onTapGesture {
            isShowingNowPlaying = true
        }
        .fullScreenCover(isPresented: $isShowingNowPlaying) {
            NowPlayingView()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
        .animation(.easeInOut(duration: 0.3), value: isDismissed)
    }
    private var albumArtView: some View {
        AsyncImage(url: URL(string: musicPlayerService.currentTrack?.thumb ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            RoundedRectangle(cornerRadius: 6)
                .fill(ThemeManager.shared.colors.surface)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText)
                )
        }
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    private var trackInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(musicPlayerService.currentTrack?.title ?? "No Track")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ThemeManager.shared.colors.primaryText)
                .lineLimit(1)
            
            Text(musicPlayerService.currentTrack?.artistName ?? "Unknown Artist")
                .font(.caption)
                .foregroundColor(ThemeManager.shared.colors.secondaryText)
                .lineLimit(1)
        }
    }
    private var controlsView: some View {
        HStack(spacing: 20) {
            Button(action: {
                musicPlayerService.togglePlayPause()
                hapticFeedback()
            }) {
                ZStack {
                    if musicPlayerService.isBuffering {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: ThemeManager.shared.colors.primaryText))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: musicPlayerService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .foregroundColor(ThemeManager.shared.colors.primaryText)
                    }
                }
                .frame(width: 30, height: 30)
            }
            .buttonStyle(ScaleButtonStyle())
            Button(action: {
                musicPlayerService.playNext()
                hapticFeedback()
            }) {
                Image(systemName: "forward.fill")
                    .font(.title3)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
            }
            .buttonStyle(ScaleButtonStyle())
            .opacity(QueueManager.shared.hasNext ? 1.0 : 0.5)
            .disabled(!QueueManager.shared.hasNext)
        }
    }
    private var blurBackground: some View {
        ZStack {
            ThemeManager.shared.colors.surface
                .opacity(0.95)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            ThemeManager.shared.colors.primaryText.opacity(0.1),
                            ThemeManager.shared.colors.primaryText.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            VStack {
                Spacer()
                
                Rectangle()
                    .fill(ThemeManager.shared.colors.progress)
                    .frame(height: 2)
                    .frame(width: UIScreen.main.bounds.width * CGFloat(musicPlayerService.progress))
                    .animation(.linear(duration: 0.1), value: musicPlayerService.progress)
            }
        }
    }
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.y > 0 {
                    dragOffset = value.translation.y
                }
            }
            .onEnded { value in
                if value.translation.y > 80 {
                    withAnimation {
                        isDismissed = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        musicPlayerService.stop()
                        isDismissed = false
                        dragOffset = 0
                    }
                } else {
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
            }
    }
    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
struct WaveformVisualizer: View {
    @State private var animationPhase: Double = 0
    let isPlaying: Bool
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(ThemeManager.shared.colors.accent)
                    .frame(width: 2)
                    .frame(height: waveHeight(for: index))
                    .animation(
                        isPlaying 
                        ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(index) * 0.05)
                        : .easeOut(duration: 0.3),
                        value: isPlaying
                    )
            }
        }
        .frame(height: 20)
    }
    
    private func waveHeight(for index: Int) -> CGFloat {
        if !isPlaying {
            return 2
        }
        
        let baseHeight: CGFloat = 4
        let maxHeight: CGFloat = 20
        let phase = (animationPhase + Double(index) * 0.3).truncatingRemainder(dividingBy: 2 * .pi)
        let amplitude = sin(phase) * 0.5 + 0.5
        
        return baseHeight + (maxHeight - baseHeight) * amplitude
    }
}
struct MiniProgressIndicator: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(ThemeManager.shared.colors.secondaryText.opacity(0.3))
                    .frame(height: 2)
                
                Rectangle()
                    .fill(ThemeManager.shared.colors.accent)
                    .frame(width: geometry.size.width * progress, height: 2)
                    .animation(.linear(duration: 0.1), value: progress)
            }
        }
        .frame(height: 2)
    }
}

#Preview {
    ZStack {
        ThemeManager.shared.colors.background
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            MiniPlayerView()
        }
    }
    .environmentObject(MusicPlayerService.shared)
}
