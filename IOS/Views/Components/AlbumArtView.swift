import SwiftUI

struct AlbumArtView: View {
    let imageURL: String?
    let size: CGFloat
    let cornerRadius: CGFloat?
    let showShadow: Bool
    let isPlaying: Bool
    
    @State private var rotation: Double = 0
    @State private var isLoaded = false
    @State private var hasError = false
    
    init(
        imageURL: String?,
        size: CGFloat = 200,
        cornerRadius: CGFloat? = nil,
        showShadow: Bool = true,
        isPlaying: Bool = false
    ) {
        self.imageURL = imageURL
        self.size = size
        self.cornerRadius = cornerRadius ?? (size * 0.1)
        self.showShadow = showShadow
        self.isPlaying = isPlaying
    }
    
    var body: some View {
        ZStack {
            if showShadow {
                RoundedRectangle(cornerRadius: cornerRadius!)
                    .fill(ThemeManager.shared.colors.shadow)
                    .frame(width: size + 10, height: size + 10)
                    .blur(radius: 15)
                    .offset(y: 5)
            }
            albumArtContainer
        }
        .onAppear {
            if isPlaying {
                startRotation()
            }
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                startRotation()
            } else {
                stopRotation()
            }
        }
    }
    private var albumArtContainer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius!)
                .fill(ThemeManager.shared.colors.surface)
                .frame(width: size, height: size)
            AsyncImage(url: URL(string: imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius!))
                        .onAppear {
                            isLoaded = true
                            hasError = false
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        
                case .failure(_):
                    placeholderView
                        .onAppear {
                            hasError = true
                            isLoaded = false
                        }
                        
                case .empty:
                    loadingView
                        
                @unknown default:
                    placeholderView
                }
            }
            if isPlaying && isLoaded {
                vinylOverlay
            }
            if isLoaded {
                reflectionOverlay
            }
        }
        .rotationEffect(.degrees(isPlaying ? rotation : 0))
        .scaleEffect(isLoaded ? 1.0 : 0.8)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isLoaded)
        .animation(.linear(duration: 0.1), value: rotation)
    }
    private var loadingView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius!)
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
                .frame(width: size, height: size)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ThemeManager.shared.colors.secondaryText))
                .scaleEffect(0.8)
        }
    }
    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius!)
                .fill(ThemeManager.shared.colors.surface)
                .frame(width: size, height: size)
            
            VStack(spacing: 8) {
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.25))
                    .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.6))
                
                if hasError {
                    Text("Failed to load")
                        .font(.caption2)
                        .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.5))
                }
            }
        }
    }
    private var vinylOverlay: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            ThemeManager.shared.colors.accent.opacity(0.3),
                            ThemeManager.shared.colors.accent.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: size * 0.9, height: size * 0.9)
            Circle()
                .stroke(
                    ThemeManager.shared.colors.accent.opacity(0.2),
                    lineWidth: 1
                )
                .frame(width: size * 0.7, height: size * 0.7)
            Circle()
                .fill(ThemeManager.shared.colors.accent.opacity(0.4))
                .frame(width: size * 0.1, height: size * 0.1)
        }
        .rotationEffect(.degrees(rotation * 2)) // Faster rotation for effect
    }
    private var reflectionOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius!)
            .fill(
                LinearGradient(
                    colors: [
                        ThemeManager.shared.colors.primaryText.opacity(0.1),
                        Color.clear,
                        Color.clear,
                        ThemeManager.shared.colors.primaryText.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
    }
    private func startRotation() {
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
    
    private func stopRotation() {
        withAnimation(.easeOut(duration: 2)) {
            rotation = 0
        }
    }
}
struct GridAlbumArtView: View {
    let albums: [Album]
    let size: CGFloat
    
    var body: some View {
        if albums.count >= 4 {
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    AlbumArtView(
                        imageURL: albums[0].smallImageURL,
                        size: size / 2 - 1,
                        cornerRadius: 4,
                        showShadow: false
                    )
                    
                    AlbumArtView(
                        imageURL: albums[1].smallImageURL,
                        size: size / 2 - 1,
                        cornerRadius: 4,
                        showShadow: false
                    )
                }
                
                HStack(spacing: 2) {
                    AlbumArtView(
                        imageURL: albums[2].smallImageURL,
                        size: size / 2 - 1,
                        cornerRadius: 4,
                        showShadow: false
                    )
                    
                    AlbumArtView(
                        imageURL: albums[3].smallImageURL,
                        size: size / 2 - 1,
                        cornerRadius: 4,
                        showShadow: false
                    )
                }
            }
            .frame(width: size, height: size)
        } else if albums.count == 3 {
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    AlbumArtView(
                        imageURL: albums[0].smallImageURL,
                        size: size / 2 - 1,
                        cornerRadius: 4,
                        showShadow: false
                    )
                    
                    AlbumArtView(
                        imageURL: albums[1].smallImageURL,
                        size: size / 2 - 1,
                        cornerRadius: 4,
                        showShadow: false
                    )
                }
                
                HStack(spacing: 2) {
                    AlbumArtView(
                        imageURL: albums[2].smallImageURL,
                        size: size / 2 - 1,
                        cornerRadius: 4,
                        showShadow: false
                    )
                    
                    placeholderView(size: size / 2 - 1)
                }
            }
            .frame(width: size, height: size)
        } else if albums.count >= 1 {
            AlbumArtView(
                imageURL: albums[0].imageURL,
                size: size,
                showShadow: false
            )
        } else {
            placeholderView(size: size)
        }
    }
    
    private func placeholderView(size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(ThemeManager.shared.colors.surface.opacity(0.5))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.3))
                    .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.3))
            )
    }
}
struct AnimatedAlbumArt: View {
    let imageURL: String?
    let size: CGFloat
    let isPlaying: Bool
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        ZStack {
            if isPlaying {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ThemeManager.shared.colors.accent.opacity(glowOpacity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size * 0.3,
                            endRadius: size * 0.7
                        )
                    )
                    .frame(width: size * 1.4, height: size * 1.4)
                    .opacity(glowOpacity)
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                        value: glowOpacity
                    )
            }
            AlbumArtView(
                imageURL: imageURL,
                size: size,
                isPlaying: isPlaying
            )
            .scaleEffect(pulseScale)
        }
        .onAppear {
            if isPlaying {
                startAnimations()
            }
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                startAnimations()
            } else {
                stopAnimations()
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowOpacity = 0.8
        }
    }
    
    private func stopAnimations() {
        withAnimation(.easeOut(duration: 0.5)) {
            pulseScale = 1.0
            glowOpacity = 0.3
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        AlbumArtView(
            imageURL: "https://example.com/album.jpg",
            size: 200,
            isPlaying: true
        )
        
        AnimatedAlbumArt(
            imageURL: "https://example.com/album.jpg",
            size: 150,
            isPlaying: true
        )
        
        GridAlbumArtView(
            albums: [],
            size: 120
        )
    }
    .padding()
    .background(ThemeManager.shared.colors.background)
}
