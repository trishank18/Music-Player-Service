import SwiftUI
import Combine

struct WaveformVisualizer: View {
    @ObservedObject private var musicPlayerService = MusicPlayerService.shared
    
    let barCount: Int
    let barWidth: CGFloat
    let barSpacing: CGFloat
    let color: Color?
    let animationDuration: Double
    
    @State private var amplitudes: [CGFloat] = []
    @State private var timer: Timer?
    @State private var isAnimating = false
    
    init(
        barCount: Int = 50,
        barWidth: CGFloat = 3,
        barSpacing: CGFloat = 2,
        color: Color? = nil,
        animationDuration: Double = 0.1
    ) {
        self.barCount = barCount
        self.barWidth = barWidth
        self.barSpacing = barSpacing
        self.color = color
        self.animationDuration = animationDuration
        self._amplitudes = State(initialValue: Array(repeating: 0.1, count: barCount))
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    amplitude: amplitudes[safe: index] ?? 0.1,
                    width: barWidth,
                    color: waveformColor,
                    animationDelay: Double(index) * 0.02
                )
            }
        }
        .onAppear {
            setupWaveform()
        }
        .onDisappear {
            stopAnimation()
        }
        .onChange(of: musicPlayerService.isPlaying) { isPlaying in
            if isPlaying {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private var waveformColor: Color {
        color ?? ThemeManager.shared.colors.accent
    }
    
    private func setupWaveform() {
        amplitudes = Array(repeating: 0.1, count: barCount)
        
        if musicPlayerService.isPlaying {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        
        timer = Timer.scheduledTimer(withTimeInterval: animationDuration, repeats: true) { _ in
            updateAmplitudes()
        }
    }
    
    private func stopAnimation() {
        isAnimating = false
        timer?.invalidate()
        timer = nil
        withAnimation(.easeOut(duration: 1.0)) {
            for i in 0..<amplitudes.count {
                amplitudes[i] = CGFloat.random(in: 0.05...0.15)
            }
        }
    }
    
    private func updateAmplitudes() {
        withAnimation(.easeInOut(duration: animationDuration)) {
            for i in 0..<amplitudes.count {
                let baseAmplitude = CGFloat.random(in: 0.1...1.0)
                let frequency = Double(i) / Double(barCount) * 10 // 0-10 Hz equivalent
                let timeOffset = Date().timeIntervalSince1970
                let lowFreqMultiplier = frequency < 2 ? 1.5 : 1.0  // Bass boost
                let midFreqMultiplier = frequency >= 2 && frequency <= 6 ? 1.2 : 1.0  // Mid presence
                let highFreqMultiplier = frequency > 6 ? 0.8 : 1.0  // High roll-off
                let waveOffset = sin(timeOffset * 2 + Double(i) * 0.2) * 0.3
                
                amplitudes[i] = min(1.0, max(0.05, 
                    baseAmplitude * lowFreqMultiplier * midFreqMultiplier * highFreqMultiplier + waveOffset
                ))
            }
        }
    }
}
struct WaveformBar: View {
    let amplitude: CGFloat
    let width: CGFloat
    let color: Color
    let animationDelay: Double
    
    @State private var animatedAmplitude: CGFloat = 0.1
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        color,
                        color.opacity(0.7),
                        color.opacity(0.3)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: width, height: max(2, animatedAmplitude * 60))
            .animation(
                .easeInOut(duration: 0.1)
                .delay(animationDelay),
                value: animatedAmplitude
            )
            .onAppear {
                animatedAmplitude = amplitude
            }
            .onChange(of: amplitude) { newAmplitude in
                animatedAmplitude = newAmplitude
            }
    }
}
struct CircularWaveform: View {
    @ObservedObject private var musicPlayerService = MusicPlayerService.shared
    
    let radius: CGFloat
    let barCount: Int
    let barWidth: CGFloat
    let color: Color?
    
    @State private var amplitudes: [CGFloat] = []
    @State private var timer: Timer?
    @State private var rotation: Double = 0
    
    init(
        radius: CGFloat = 80,
        barCount: Int = 60,
        barWidth: CGFloat = 3,
        color: Color? = nil
    ) {
        self.radius = radius
        self.barCount = barCount
        self.barWidth = barWidth
        self.color = color
        
        self._amplitudes = State(initialValue: Array(repeating: 0.1, count: barCount))
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<barCount, id: \.self) { index in
                CircularWaveformBar(
                    amplitude: amplitudes[safe: index] ?? 0.1,
                    width: barWidth,
                    radius: radius,
                    angle: Double(index) * (360.0 / Double(barCount)),
                    color: waveformColor
                )
            }
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            setupWaveform()
        }
        .onDisappear {
            stopAnimation()
        }
        .onChange(of: musicPlayerService.isPlaying) { isPlaying in
            if isPlaying {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private var waveformColor: Color {
        color ?? ThemeManager.shared.colors.accent
    }
    
    private func setupWaveform() {
        amplitudes = Array(repeating: 0.1, count: barCount)
        
        if musicPlayerService.isPlaying {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateAmplitudes()
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
        
        withAnimation(.easeOut(duration: 1.0)) {
            rotation = 0
            for i in 0..<amplitudes.count {
                amplitudes[i] = 0.1
            }
        }
    }
    
    private func updateAmplitudes() {
        withAnimation(.easeInOut(duration: 0.1)) {
            for i in 0..<amplitudes.count {
                let angle = Double(i) * (360.0 / Double(barCount))
                let timeOffset = Date().timeIntervalSince1970
                let radialWave = sin(angle * .pi / 180 * 3 + timeOffset * 4) * 0.4
                let baseAmplitude = CGFloat.random(in: 0.2...0.8)
                
                amplitudes[i] = min(1.0, max(0.1, baseAmplitude + radialWave))
            }
        }
    }
}
struct CircularWaveformBar: View {
    let amplitude: CGFloat
    let width: CGFloat
    let radius: CGFloat
    let angle: Double
    let color: Color
    
    @State private var animatedAmplitude: CGFloat = 0.1
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(0.3),
                        color,
                        color.opacity(0.8)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: animatedAmplitude * 30)
            .offset(x: radius)
            .rotationEffect(.degrees(angle), anchor: .leading)
            .animation(.easeInOut(duration: 0.1), value: animatedAmplitude)
            .onAppear {
                animatedAmplitude = amplitude
            }
            .onChange(of: amplitude) { newAmplitude in
                animatedAmplitude = newAmplitude
            }
    }
}
struct CompactWaveform: View {
    @ObservedObject private var musicPlayerService = MusicPlayerService.shared
    
    let height: CGFloat
    let barCount: Int
    let color: Color?
    
    @State private var amplitudes: [CGFloat] = []
    @State private var timer: Timer?
    
    init(
        height: CGFloat = 20,
        barCount: Int = 20,
        color: Color? = nil
    ) {
        self.height = height
        self.barCount = barCount
        self.color = color
        
        self._amplitudes = State(initialValue: Array(repeating: 0.1, count: barCount))
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 1) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(waveformColor)
                    .frame(
                        width: 2,
                        height: max(2, (amplitudes[safe: index] ?? 0.1) * height)
                    )
                    .animation(
                        .easeInOut(duration: 0.1)
                        .delay(Double(index) * 0.01),
                        value: amplitudes[safe: index] ?? 0.1
                    )
            }
        }
        .frame(height: height)
        .onAppear {
            setupWaveform()
        }
        .onDisappear {
            stopAnimation()
        }
        .onChange(of: musicPlayerService.isPlaying) { isPlaying in
            if isPlaying {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private var waveformColor: Color {
        color ?? ThemeManager.shared.colors.accent
    }
    
    private func setupWaveform() {
        amplitudes = Array(repeating: 0.1, count: barCount)
        
        if musicPlayerService.isPlaying {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            updateAmplitudes()
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
        
        withAnimation(.easeOut(duration: 0.8)) {
            for i in 0..<amplitudes.count {
                amplitudes[i] = 0.1
            }
        }
    }
    
    private func updateAmplitudes() {
        withAnimation(.easeInOut(duration: 0.15)) {
            for i in 0..<amplitudes.count {
                amplitudes[i] = CGFloat.random(in: 0.1...1.0)
            }
        }
    }
}
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    VStack(spacing: 40) {
        WaveformVisualizer(
            barCount: 30,
            barWidth: 4,
            barSpacing: 3
        )
        .frame(height: 60)
        
        CircularWaveform(
            radius: 60,
            barCount: 40
        )
        .frame(width: 150, height: 150)
        
        CompactWaveform(
            height: 25,
            barCount: 15
        )
    }
    .padding()
    .background(ThemeManager.shared.colors.background)
}
