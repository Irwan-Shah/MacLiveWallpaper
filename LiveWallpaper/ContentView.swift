import SwiftUI
import AVKit

struct ContentView: View {
    @StateObject private var manager = WallpaperManager.shared
    @State private var selectedVideoURL: URL? = nil
    @State private var previewPlayer: AVPlayer? = nil
    @State private var showFilePicker = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            
            // ── Preview Area ──
            ZStack {
                Color.black
                    .cornerRadius(12)
                
                if let previewPlayer = previewPlayer {
                    VideoPlayer(player: previewPlayer)
                        .cornerRadius(12)
                        .onAppear {
                            previewPlayer.play()
                        }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 52))
                            .foregroundColor(.gray)
                        Text("Pick a video to preview")
                            .foregroundColor(.gray)
                            .font(.headline)
                    }
                }
            }
            .frame(width: 400, height: 280)
            .padding()
            
            // ── Error Message ──
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            // ── Controls ──
            VStack(spacing: 12) {
                
                if let url = selectedVideoURL {
                    Text("📁 \(url.lastPathComponent)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal)
                }
                
                // Pick Video
                Button {
                    showFilePicker = true
                } label: {
                    Label("Choose Video File", systemImage: "folder.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                
                // Set as Wallpaper
                Button {
                    applyWallpaper()
                } label: {
                    Label("Set as Wallpaper", systemImage: "desktopcomputer")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedVideoURL == nil)
                .padding(.horizontal)
                
                // Status + Stop
                if manager.isPlaying {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Wallpaper is live")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Button {
                        manager.stopWallpaper()
                    } label: {
                        Label("Stop Wallpaper", systemImage: "stop.circle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 24)
        }
        .frame(width: 440)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.movie, .video, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            handleFilePick(result)
        }
    }
    
    // MARK: - Handle File Pick
    private func handleFilePick(_ result: Result<[URL], Error>) {
        errorMessage = nil
        
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // ✅ IMPORTANT: Request security-scoped access
            let accessed = url.startAccessingSecurityScopedResource()
            print("Security scoped access: \(accessed)")
            print("Video URL: \(url)")
            
            selectedVideoURL = url
            
            // Stop old preview
            previewPlayer?.pause()
            previewPlayer = nil
            
            // Create fresh preview player
            let asset = AVAsset(url: url)
            let item = AVPlayerItem(asset: asset)
            let newPlayer = AVPlayer(playerItem: item)
            newPlayer.isMuted = true
            
            DispatchQueue.main.async {
                self.previewPlayer = newPlayer
                newPlayer.play()
            }
            
        case .failure(let error):
            errorMessage = "Failed to open file: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Apply Wallpaper
    private func applyWallpaper() {
        guard let url = selectedVideoURL else { return }
        errorMessage = nil
        manager.setWallpaper(url: url)
    }
}
