import SwiftUI

struct CreatePlaylistView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var playlistName = ""
    @State private var playlistDescription = ""
    @State private var isPublic = false
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingImageOptions = false
    
    let onPlaylistCreated: (Playlist) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeManager.shared.colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        headerView
                        formView
                        createButtonView
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(ThemeManager.shared.colors.secondaryText)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("New Playlist")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ThemeManager.shared.colors.primaryText)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .actionSheet(isPresented: $showingImageOptions) {
            ActionSheet(
                title: Text("Choose Playlist Image"),
                buttons: [
                    .default(Text("Photo Library")) {
                        showingImagePicker = true
                    },
                    .default(Text("Use Default")) {
                        selectedImage = nil
                    },
                    .cancel()
                ]
            )
        }
    }
    private var headerView: some View {
        VStack(spacing: 20) {
            Button(action: { showingImageOptions = true }) {
                ZStack {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
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
                            .frame(width: 200, height: 200)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.6))
                                    
                                    Text("Add Image")
                                        .font(.caption)
                                        .foregroundColor(ThemeManager.shared.colors.secondaryText.opacity(0.8))
                                }
                            )
                    }
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .foregroundColor(ThemeManager.shared.colors.accent)
                                .background(
                                    Circle()
                                        .fill(ThemeManager.shared.colors.background)
                                        .frame(width: 25, height: 25)
                                )
                        }
                    }
                    .padding(12)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .themeShadow(style: .card)
        }
    }
    private var formView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Playlist Name")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                
                TextField("Enter playlist name", text: $playlistName)
                    .font(.body)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(ThemeManager.shared.colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                playlistName.isEmpty 
                                ? Color.clear 
                                : ThemeManager.shared.colors.accent.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                
                TextField("Add a description", text: $playlistDescription, axis: .vertical)
                    .font(.body)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 80, alignment: .topLeading)
                    .background(ThemeManager.shared.colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .lineLimit(3...6)
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("Privacy")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.colors.primaryText)
                
                Toggle(isOn: $isPublic) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Make Public")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(ThemeManager.shared.colors.primaryText)
                        
                        Text("Anyone can find and listen to this playlist")
                            .font(.caption)
                            .foregroundColor(ThemeManager.shared.colors.secondaryText)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: ThemeManager.shared.colors.accent))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(ThemeManager.shared.colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    private var createButtonView: some View {
        Button(action: createPlaylist) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Create Playlist")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(
                canCreatePlaylist 
                ? ThemeManager.shared.colors.background 
                : ThemeManager.shared.colors.secondaryText
            )
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                canCreatePlaylist 
                ? ThemeManager.shared.colors.accent 
                : ThemeManager.shared.colors.surface
            )
            .clipShape(Capsule())
            .themeShadow(style: canCreatePlaylist ? .elevated : .subtle)
        }
        .disabled(!canCreatePlaylist)
        .buttonStyle(ScaleButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: canCreatePlaylist)
    }
    private var canCreatePlaylist: Bool {
        !playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private func createPlaylist() {
        guard canCreatePlaylist else { return }
        
        let playlist = Playlist(
            id: UUID().uuidString,
            name: playlistName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: playlistDescription.isEmpty ? nil : playlistDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: nil, // Will be set if image is uploaded
            isPublic: isPublic,
            createdDate: Date(),
            tracks: [],
            creator: "Current User" // Replace with actual user
        )
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        onPlaylistCreated(playlist)
        presentationMode.wrappedValue.dismiss()
    }
}
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    CreatePlaylistView { playlist in
        print("Created playlist: \(playlist.name)")
    }
    .preferredColorScheme(.dark)
}
