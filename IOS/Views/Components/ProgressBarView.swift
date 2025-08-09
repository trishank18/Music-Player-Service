import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void
    
    @State private var isDragging = false
    @State private var dragProgress: Double = 0
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(ThemeManager.shared.colors.secondaryText.opacity(0.3))
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                ThemeManager.shared.colors.accent,
                                ThemeManager.shared.colors.progress
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: progressWidth(geometry: geometry), height: 4)
                    .animation(.linear(duration: isDragging ? 0 : 0.1), value: isDragging ? dragProgress : progress)
                Circle()
                    .fill(ThemeManager.shared.colors.accent)
                    .frame(width: isDragging ? 16 : 12, height: isDragging ? 16 : 12)
                    .shadow(color: ThemeManager.shared.colors.shadow, radius: isDragging ? 4 : 2, x: 0, y: 1)
                    .offset(x: handleOffset(geometry: geometry))
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                    .gesture(dragGesture(geometry: geometry))
            }
        }
        .frame(height: 20)
        .contentShape(Rectangle())
        .onTapGesture { location in
            seekToLocation(location, geometry: nil)
        }
    }
    private func progressWidth(geometry: GeometryProxy) -> CGFloat {
        let currentProgress = isDragging ? dragProgress : progress
        return geometry.size.width * currentProgress
    }
    
    private func handleOffset(geometry: GeometryProxy) -> CGFloat {
        let currentProgress = isDragging ? dragProgress : progress
        return (geometry.size.width * currentProgress) - 6 // Center the handle
    }
    
    private func seekToLocation(_ location: CGPoint, geometry: GeometryProxy?) -> Void {
        guard let geometry = geometry ?? getCurrentGeometry() else { return }
        
        let newProgress = min(max(location.x / geometry.size.width, 0), 1)
        let newTime = newProgress * duration
        onSeek(newTime)
        hapticFeedback()
    }
    
    private func getCurrentGeometry() -> GeometryProxy? {
        return nil
    }
    
    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    private func dragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragOffset) { value, state, _ in
                state = value.translation.x
            }
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                }
                
                let newProgress = min(max((value.location.x) / geometry.size.width, 0), 1)
                dragProgress = newProgress
            }
            .onEnded { value in
                let finalProgress = min(max((value.location.x) / geometry.size.width, 0), 1)
                let newTime = finalProgress * duration
                onSeek(newTime)
                
                isDragging = false
                hapticFeedback()
            }
    }
}
struct WaveformProgressBar: View {
    let progress: Double
    let waveformData: [Float] // Audio waveform data
    let onSeek: (TimeInterval) -> Void
    
    @State private var isDragging = false
    @State private var dragProgress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                waveformView(geometry: geometry, isProgress: false)
                waveformView(geometry: geometry, isProgress: true)
                    .clipShape(
                        Rectangle()
                            .size(width: progressWidth(geometry: geometry), height: geometry.size.height)
                    )
                Circle()
                    .fill(ThemeManager.shared.colors.accent)
                    .frame(width: isDragging ? 16 : 12, height: isDragging ? 16 : 12)
                    .shadow(color: ThemeManager.shared.colors.shadow, radius: 3, x: 0, y: 1)
                    .offset(x: handleOffset(geometry: geometry), y: 0)
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
            }
        }
        .frame(height: 40)
        .gesture(dragGesture)
        .onTapGesture { location in
            seekToTapLocation(location)
        }
    }
    
    private func waveformView(geometry: GeometryProxy, isProgress: Bool) -> some View {
        HStack(spacing: 1) {
            ForEach(0..<waveformData.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(isProgress ? ThemeManager.shared.colors.accent : ThemeManager.shared.colors.secondaryText.opacity(0.3))
                    .frame(
                        width: max(geometry.size.width / CGFloat(waveformData.count) - 1, 1),
                        height: CGFloat(waveformData[index]) * geometry.size.height
                    )
            }
        }
    }
    
    private func progressWidth(geometry: GeometryProxy) -> CGFloat {
        let currentProgress = isDragging ? dragProgress : progress
        return geometry.size.width * currentProgress
    }
    
    private func handleOffset(geometry: GeometryProxy) -> CGFloat {
        let currentProgress = isDragging ? dragProgress : progress
        return (geometry.size.width * currentProgress) - 6
    }
    
    private func seekToTapLocation(_ location: CGPoint) {
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = true
            }
            .onEnded { value in
                isDragging = false
            }
    }
}
struct CircularProgressBar: View {
    let progress: Double
    let lineWidth: CGFloat = 4
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    ThemeManager.shared.colors.secondaryText.opacity(0.3),
                    lineWidth: lineWidth
                )
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [
                            ThemeManager.shared.colors.accent,
                            ThemeManager.shared.colors.progress
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
            Circle()
                .fill(ThemeManager.shared.colors.accent)
                .frame(width: 8, height: 8)
        }
    }
}
struct AnimatedProgressDots: View {
    let progress: Double
    let dotCount: Int = 50
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: 3, height: 3)
                    .scaleEffect(dotScale(for: index))
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.02),
                        value: progress
                    )
            }
        }
    }
    
    private func dotColor(for index: Int) -> Color {
        let dotProgress = Double(index) / Double(dotCount - 1)
        if dotProgress <= progress {
            return ThemeManager.shared.colors.accent
        } else {
            return ThemeManager.shared.colors.secondaryText.opacity(0.3)
        }
    }
    
    private func dotScale(for index: Int) -> CGFloat {
        let dotProgress = Double(index) / Double(dotCount - 1)
        if abs(dotProgress - progress) < 0.05 {
            return 1.5
        } else {
            return 1.0
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        ProgressBarView(
            progress: 0.3,
            currentTime: 90,
            duration: 300
        ) { time in
            print("Seek to: \(time)")
        }
        
        CircularProgressBar(progress: 0.3)
            .frame(width: 100, height: 100)
        
        AnimatedProgressDots(progress: 0.3)
    }
    .padding()
    .background(ThemeManager.shared.colors.background)
}
