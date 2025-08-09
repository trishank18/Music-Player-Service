import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject var musicPlayerService: MusicPlayerService
    @State private var selectedCategory: SearchCategory = .all
    @State private var isShowingFilters = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeManager.shared.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    searchHeader
                    categorySelector
                    searchResults
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadTrendingContent()
            }
        }
    }
    private var searchHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ThemeManager.shared.colors.secondaryText)
                
                TextField("Search artists, albums, tracks...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                    .onChange(of: viewModel.searchText) { _ in
                        viewModel.performSearch()
                    }
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    }
                }
            }
            .padding()
            .background(ThemeManager.shared.colors.surface)
            .cornerRadius(12)
            .shadow(color: ThemeManager.shared.colors.shadow, radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal)
    }
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SearchCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        viewModel.filterResults(by: category)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    private var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.searchText.isEmpty {
                    trendingSection
                } else {
                    resultsSection
                }
            }
            .padding()
        }
    }
    private var trendingSection: some View {
        VStack(spacing: 20) {
            if !viewModel.trendingArtists.isEmpty {
                TrendingSectionView(
                    title: "Trending Artists",
                    items: viewModel.trendingArtists.map { .artist($0) }
                ) { item in
                    if case .artist(let artist) = item {
                    }
                }
            }
            if !viewModel.trendingAlbums.isEmpty {
                TrendingSectionView(
                    title: "Trending Albums",
                    items: viewModel.trendingAlbums.map { .album($0) }
                ) { item in
                    if case .album(let album) = item {
                    }
                }
            }
            if !viewModel.trendingTracks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Trending Tracks")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.trendingTracks) { track in
                            TrackRowView(track: track) {
                                musicPlayerService.playTrack(track)
                            }
                        }
                    }
                }
            }
        }
    }
    private var resultsSection: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
                    .frame(height: 200)
            } else if viewModel.searchResults.isEmpty {
                EmptyStateView(
                    title: "No Results Found",
                    subtitle: "Try adjusting your search terms",
                    systemImage: "magnifyingglass"
                )
                .frame(height: 200)
            } else {
                VStack(spacing: 20) {
                    if !viewModel.searchResults.artists.isEmpty && (selectedCategory == .all || selectedCategory == .artists) {
                        SearchResultsSection(
                            title: "Artists",
                            items: viewModel.searchResults.artists.map { .artist($0) }
                        ) { item in
                            if case .artist(let artist) = item {
                            }
                        }
                    }
                    if !viewModel.searchResults.albums.isEmpty && (selectedCategory == .all || selectedCategory == .albums) {
                        SearchResultsSection(
                            title: "Albums",
                            items: viewModel.searchResults.albums.map { .album($0) }
                        ) { item in
                            if case .album(let album) = item {
                            }
                        }
                    }
                    if !viewModel.searchResults.tracks.isEmpty && (selectedCategory == .all || selectedCategory == .tracks) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tracks")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(ThemeManager.shared.colors.primaryText)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.searchResults.tracks) { track in
                                    TrackRowView(track: track) {
                                        musicPlayerService.playTrack(track)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
struct CategoryButton: View {
    let category: SearchCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.caption)
                
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? ThemeManager.shared.colors.accent : ThemeManager.shared.colors.surface
            )
            .foregroundColor(
                isSelected ? ThemeManager.shared.colors.background : ThemeManager.shared.colors.primaryText
            )
            .cornerRadius(20)
            .shadow(color: ThemeManager.shared.colors.shadow, radius: isSelected ? 3 : 1, x: 0, y: 1)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults = SearchResults(artists: [], albums: [], tracks: [])
    @Published var trendingArtists: [Artist] = []
    @Published var trendingAlbums: [Album] = []
    @Published var trendingTracks: [Track] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let musicSource = MusicSourceManager.shared.currentSource
    private var searchCancellable: AnyCancellable?
    
    func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = SearchResults(artists: [], albums: [], tracks: [])
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        searchCancellable?.cancel()
        searchCancellable = musicSource.searchAll(query: searchText)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] results in
                    self?.searchResults = results
                }
            )
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = SearchResults(artists: [], albums: [], tracks: [])
    }
    
    func filterResults(by category: SearchCategory) {
    }
    
    func loadTrendingContent() {
        musicSource.getTrendingArtists()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] artists in
                    self?.trendingArtists = Array(artists.prefix(10))
                }
            )
            .store(in: &cancellables)
        musicSource.getTrendingAlbums()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] albums in
                    self?.trendingAlbums = Array(albums.prefix(10))
                }
            )
            .store(in: &cancellables)
        musicSource.getTrendingTracks()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] tracks in
                    self?.trendingTracks = Array(tracks.prefix(20))
                }
            )
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}

#Preview {
    SearchView()
        .environmentObject(MusicPlayerService.shared)
}
