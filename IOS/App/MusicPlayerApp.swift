import SwiftUI
import Combine

@main
struct MusicPlayerApp: App {
    @StateObject private var musicPlayerService = MusicPlayerService.shared
    @StateObject private var audioSessionManager = AudioSessionManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(musicPlayerService)
                .environmentObject(audioSessionManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        audioSessionManager.configureAudioSession()
        ThemeManager.shared.applyTheme()
    }
}

struct ContentView: View {
    @EnvironmentObject var musicPlayerService: MusicPlayerService
    @StateObject private var mainViewModel = MainViewModel()
    
    var body: some View {
        ZStack {
            TabView {
                SearchView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
                
                PlaylistView()
                    .tabItem {
                        Image(systemName: "music.note.list")
                        Text("Playlists")
                    }
                
                LibraryView()
                    .tabItem {
                        Image(systemName: "music.note")
                        Text("Library")
                    }
            }
            .accentColor(ThemeManager.shared.colors.accent)
            VStack {
                Spacer()
                if musicPlayerService.isPlaying || musicPlayerService.currentTrack != nil {
                    MiniPlayerView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: musicPlayerService.currentTrack)
                }
            }
        }
        .background(ThemeManager.shared.colors.background)
    }
}
