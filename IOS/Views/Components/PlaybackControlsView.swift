import SwiftUI

struct PlaybackControlsView: View {
    @EnvironmentObject var musicPlayerService: MusicPlayerService
    let size: ControlSize = .large
    let showSecondaryControls: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            primaryControlsView
            if showSecondaryControls {
                secondaryControlsView
            }
        }
    }
    private var primaryControlsView: some View {
        HStack(spacing: controlSpacing) {
            ControlButton(
                icon: "backward.fill",
                size: secondaryButtonSize,
                isEnabled: QueueManager.shared.hasPrevious,
                action: {
                    musicPlayerService.playPrevious()
                    hapticFeedback(.light)
                }
            )
            PlayPauseButton(
                isPlaying: musicPlayerService.isPlaying,
                isBuffering: musicPlayerService.isBuffering,
                size: primaryButtonSize,
                action: {
                    musicPlayerService.togglePlayPause()
                    hapticFeedback(.medium)
                }
            )
            ControlButton(
                icon: "forward.fill",
                size: secondaryButtonSize,
                isEnabled: QueueManager.shared.hasNext,
                action: {
                    musicPlayerService.playNext()
                    hapticFeedback(.light)
                }
            )
        }
    }
    private var secondaryControlsView: some View {
        HStack(spacing: 40) {
            ControlButton(
                icon: musicPlayerService.shuffleMode.iconName,
                size: .small,
                isActive: musicPlayerService.shuffleMode == .on,
                action: {
                    musicPlayerService.toggleShuffleMode()
                    hapticFeedback(.light)
                }
            )
            ControlButton(
                icon: musicPlayerService.repeatMode.iconName,
                size: .small,
                isActive: musicPlayerService.repeatMode != .off,
                action: {
                    musicPlayerService.toggleRepeatMode()
                    hapticFeedback(.light)
                }
            )
            ControlButton(
                icon: "list.bullet",
                size: .small,
                badge: QueueManager.shared.queueCount > 0 ? "\(QueueManager.shared.queueCount)" : nil,
                action: {
                    hapticFeedback(.light)
                }
            )
            ControlButton(
                icon: "ellipsis",
                size: .small,
                action: {
                    hapticFeedback(.light)
                }
            )
        }
    }
    private var controlSpacing: CGFloat {
        switch size {
        case .small: return 20
        case .medium: return 30
        case .large: return 40
        }
    }
    
    private var primaryButtonSize: CGFloat {
        switch size {
        case .small: return 50
        case .medium: return 60
        case .large: return 70
        }
    }
    
    private var secondaryButtonSize: CGFloat {
        switch size {
        case .small: return 35
        case .medium: return 40
        case .large: return 45
        }
    }
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
}
struct ControlButton: View {
    let icon: String
    let size: ControlButtonSize
    let isEnabled: Bool
    let isActive: Bool
    let badge: String?
    let action: () -> Void
    
    init(
        icon: String,
        size: ControlButtonSize = .medium,
        isEnabled: Bool = true,
        isActive: Bool = false,
        badge: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.isEnabled = isEnabled
        self.isActive = isActive
        self.badge = badge
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isActive {
                    Circle()
                        .fill(ThemeManager.shared.colors.accent.opacity(0.2))
                        .frame(width: backgroundSize, height: backgroundSize)
                }
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(foregroundColor)
                if let badge = badge {
                    VStack {
                        HStack {
                            Spacer()
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(ThemeManager.shared.colors.background)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ThemeManager.shared.colors.accent)
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                    .frame(width: backgroundSize, height: backgroundSize)
                }
            }
        }
        .disabled(!isEnabled)
        .scaleEffect(isEnabled ? 1.0 : 0.8)
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
    
    private var iconSize: CGFloat {
        switch size {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }
    
    private var backgroundSize: CGFloat {
        switch size {
        case .small: return 35
        case .medium: return 45
        case .large: return 55
        }
    }
    
    private var foregroundColor: Color {
        if !isEnabled {
            return ThemeManager.shared.colors.secondaryText.opacity(0.5)
        } else if isActive {
            return ThemeManager.shared.colors.accent
        } else {
            return ThemeManager.shared.colors.primaryText
        }
    }
}
struct PlayPauseButton: View {
    let isPlaying: Bool
    let isBuffering: Bool
    let size: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                ThemeManager.shared.colors.accent,
                                ThemeManager.shared.colors.accent.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(
                        color: ThemeManager.shared.colors.shadow,
                        radius: isPressed ? 3 : 8,
                        x: 0,
                        y: isPressed ? 1 : 4
                    )
                if isBuffering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ThemeManager.shared.colors.background))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: iconSize, weight: .bold))
                        .foregroundColor(ThemeManager.shared.colors.background)
                        .offset(x: isPlaying ? 0 : 2) // Slight offset for play icon centering
                }
            }
        }
        .scaleEffect(isPressed ? 0.95 : (isPlaying ? 1.1 : 1.0))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            action()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPlaying)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
    }
    
    private var iconSize: CGFloat {
        return size * 0.35
    }
}
struct VolumeControlView: View {
    @Binding var volume: Float
    let onVolumeChange: (Float) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.caption)
                .foregroundColor(ThemeManager.shared.colors.secondaryText)
            
            Slider(
                value: $volume,
                in: 0...1,
                onEditingChanged: { _ in
                    onVolumeChange(volume)
                }
            )
            .accentColor(ThemeManager.shared.colors.accent)
            
            Image(systemName: "speaker.3.fill")
                .font(.caption)
                .foregroundColor(ThemeManager.shared.colors.secondaryText)
        }
    }
}
struct CompactPlaybackControls: View {
    @EnvironmentObject var musicPlayerService: MusicPlayerService
    
    var body: some View {
        HStack(spacing: 20) {
            ControlButton(
                icon: "backward.fill",
                size: .small,
                isEnabled: QueueManager.shared.hasPrevious,
                action: {
                    musicPlayerService.playPrevious()
                }
            )
            
            PlayPauseButton(
                isPlaying: musicPlayerService.isPlaying,
                isBuffering: musicPlayerService.isBuffering,
                size: 45,
                action: {
                    musicPlayerService.togglePlayPause()
                }
            )
            
            ControlButton(
                icon: "forward.fill",
                size: .small,
                isEnabled: QueueManager.shared.hasNext,
                action: {
                    musicPlayerService.playNext()
                }
            )
        }
    }
}
enum ControlSize {
    case small, medium, large
}

enum ControlButtonSize {
    case small, medium, large
}

#Preview {
    VStack(spacing: 40) {
        PlaybackControlsView()
            .environmentObject(MusicPlayerService.shared)
        
        CompactPlaybackControls()
            .environmentObject(MusicPlayerService.shared)
        
        VolumeControlView(volume: .constant(0.7)) { volume in
            print("Volume changed to: \(volume)")
        }
    }
    .padding()
    .background(ThemeManager.shared.colors.background)
}
