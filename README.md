# iOS Music Player

A fully-featured iOS Music Player built with SwiftUI, MVVM architecture, and Combine framework, featuring a cinematic black & white "Neo Noir Elegance" theme.

## 🎵 Features

### Core Functionality
- **Full Music Playback** - Play, pause, skip, shuffle, repeat
- **Queue Management** - Advanced queue system with reordering
- **Search & Discovery** - Real-time search with trending content
- **Library Management** - Organize your music collection
- **Playlist Creation** - Create and manage custom playlists

### Premium UI/UX
- **Neo Noir Elegance Theme** - Cinematic black & white design
- **Glassmorphism Effects** - Modern blur and transparency effects
- **Advanced Animations** - Smooth transitions and micro-interactions
- **Gesture Navigation** - Drag-to-expand mini player
- **Haptic Feedback** - Enhanced user experience

### Technical Features
- **MVVM Architecture** - Clean separation of concerns
- **Combine Framework** - Reactive programming for real-time updates
- **TheAudioDB API** - Rich music metadata and artwork
- **Strategy Pattern** - Multiple music sources (Local, API, Mock)
- **Audio Visualization** - Real-time waveform displays

## 🛠 Requirements

- **Xcode 15.0+**
- **iOS 17.0+**
- **macOS 14.0+** (for development)
- **Apple Developer Account** (for device testing)

## 🚀 Getting Started

### 1. Clone or Set Up Project

If you haven't already, ensure all the Swift files are in the correct directory structure:

```
IOS/
├── App/
│   └── MusicPlayerApp.swift
├── Core/
│   ├── Models/
│   │   ├── Artist.swift
│   │   ├── Album.swift
│   │   ├── Track.swift
│   │   └── Enums.swift
│   ├── Networking/
│   │   └── AudioDBService.swift
│   └── Services/
│       ├── MusicPlayerService.swift
│       ├── QueueManager.swift
│       └── AudioSessionManager.swift
├── Sources/
│   ├── MusicSourceProtocol.swift
│   ├── LocalMusicSource.swift
│   ├── SpotifyMockSource.swift
│   └── AudioDBMusicSource.swift
├── ViewModels/
│   ├── ArtistViewModel.swift
│   ├── AlbumViewModel.swift
│   ├── TrackViewModel.swift
│   ├── NowPlayingViewModel.swift
│   └── PlaylistViewModel.swift
├── Views/
│   ├── Components/
│   │   ├── ProgressBarView.swift
│   │   ├── PlaybackControlsView.swift
│   │   ├── AlbumArtView.swift
│   │   └── WaveformVisualizer.swift
│   ├── SearchView.swift
│   ├── NowPlayingView.swift
│   ├── MiniPlayerView.swift
│   ├── AlbumDetailView.swift
│   ├── ArtistDetailView.swift
│   ├── PlaylistView.swift
│   ├── LibraryView.swift
│   └── ContentView.swift
└── Utilities/
    ├── ThemeManager.swift
    ├── View+Shadow.swift
    └── CombineHelpers.swift
```

### 2. Create Xcode Project

1. **Open Xcode**
2. **Create a new project**:
   - Choose "iOS" → "App"
   - Product Name: `MusicPlayer`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Use Core Data: `No`
   - Include Tests: `Yes` (optional)

3. **Set minimum deployment target** to iOS 17.0 in project settings

### 3. Add Source Files

1. **Delete the default** `ContentView.swift` and `MusicPlayerApp.swift` files
2. **Add all the Swift files** from our project structure to the Xcode project
3. **Organize files** into groups matching the folder structure

### 4. Configure Info.plist

Add the following permissions to your `Info.plist`:

```xml
<key>NSAppleMusicUsageDescription</key>
<string>This app needs access to your music library to play your songs.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app uses the microphone for audio visualization features.</string>
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### 5. Add Required Frameworks

In your project target settings, add these frameworks:
- `AVFoundation`
- `MediaPlayer`
- `Combine` (included in iOS 13+)
- `SwiftUI` (included in iOS 13+)

### 6. Build and Run

1. **Select your target device** (iPhone simulator or physical device)
2. **Press Cmd+R** to build and run
3. **Grant permissions** when prompted

## 📱 Usage Guide

### First Launch
1. **Grant music library access** when prompted
2. **Explore the app** using the tab navigation
3. **Search for music** using TheAudioDB integration
4. **Create playlists** and organize your library

### Navigation
- **Home Tab**: Discover trending music and quick access
- **Search Tab**: Find artists, albums, and tracks
- **Library Tab**: Your personal music collection
- **Playlists Tab**: Manage and create playlists

### Playback Controls
- **Tap to play**: Single tap on any track
- **Mini player**: Appears at bottom when music is playing
- **Drag up**: Expand mini player to full-screen view
- **Gestures**: Swipe for next/previous tracks

## 🔧 Configuration

### API Configuration
The app uses TheAudioDB API. No API key required for basic usage, but you can upgrade to a premium plan for higher limits.

### Theme Customization
Modify `ThemeManager.swift` to customize the color scheme:

```swift
// Example: Change accent color
static let accent = Color(hex: "#YOUR_COLOR_HEX")
```

### Audio Settings
Configure audio behavior in `AudioSessionManager.swift`:

```swift
// Example: Enable background playback
try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth])
```

## 🚨 Troubleshooting

### Common Issues

1. **Build Errors**
   - Ensure all files are properly added to the target
   - Check minimum deployment target is iOS 17.0+
   - Verify all imports are correct

2. **Music Library Access**
   - Check Info.plist permissions are correctly set
   - Test on a physical device with music library
   - Grant permissions in iOS Settings if needed

3. **API Requests Failing**
   - Check internet connection
   - Verify TheAudioDB API is accessible
   - Check for rate limiting

4. **Audio Not Playing**
   - Test on physical device (simulator has audio limitations)
   - Check audio session configuration
   - Verify background modes are enabled

### Debug Mode
Enable debug logging by setting the scheme build configuration to "Debug". This will show detailed logs for:
- Network requests
- Audio playback events
- Combine publisher flows

## 🧪 Testing

### Unit Tests
Run unit tests with `Cmd+U` to test:
- View model logic
- Service layer functionality
- Data model parsing

### UI Tests
Test user interactions and navigation flows:
- Search functionality
- Playback controls
- Playlist management

### Device Testing
Test on various devices:
- Different screen sizes (iPhone SE to iPhone Pro Max)
- Audio output (speakers, headphones, AirPods)
- Background playback scenarios

## 📖 Architecture

### MVVM Pattern
- **Models**: Data structures and business logic
- **Views**: SwiftUI user interface components
- **ViewModels**: Reactive state management with Combine

### Services
- **MusicPlayerService**: Core audio playback functionality
- **AudioDBService**: API communication and data fetching
- **QueueManager**: Playlist and queue management

### Strategy Pattern
- **MusicSourceProtocol**: Abstraction for different music sources
- **LocalMusicSource**: Device music library access
- **AudioDBMusicSource**: Online music database
- **SpotifyMockSource**: Mock data for development

## 🎨 Design System

### Colors
- **Jet Black**: `#121212` - Primary background
- **Charcoal**: `#1E1E1E` - Secondary surfaces
- **Pure White**: `#FFFFFF` - Primary text
- **Light Gray**: `#B3B3B3` - Secondary text
- **Accent**: `#1DB954` - Interactive elements

### Typography
- **Primary**: System font with various weights
- **Emphasis**: Bold for headlines and important text
- **Subtle**: Light weight for secondary information

### Animations
- **Spring animations** for natural feeling interactions
- **Easing curves** optimized for iOS feel
- **Micro-interactions** with haptic feedback

## 🔮 Future Enhancements

- **iCloud sync** for playlists and preferences
- **Social features** for sharing music
- **Advanced audio effects** and equalizer
- **CarPlay integration** for automotive use
- **Apple Watch companion app**
- **Lyrics display** with synchronized scrolling

## 📄 License

This project is created for educational purposes. Please respect music licensing and API terms of service.

## 🤝 Contributing

This is a demonstration project, but feel free to:
- Report issues
- Suggest improvements
- Fork for your own projects
- Share your enhancements

---

**Built with ❤️ using SwiftUI and the power of declarative UI programming.**
