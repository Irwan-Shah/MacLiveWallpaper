import SwiftUI
import AVKit

struct MenuBarView: View {
    @EnvironmentObject private var manager: WallpaperManager
    @State private var selectedVideoURL: URL? = nil
    @State private var previewPlayer: AVPlayer? = nil
    @State private var showFilePicker = false
    @State private var errorMessage: String? = nil
    @State private var previewAccessURL: URL? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            
            // ── Header ──
            HStack {
                Image(systemName: "desktopcomputer")
                    .foregroundColor(.secondary)
                Text("Live Wallpaper")
                    .font(.headline)
                Spacer()
                
                // ✅ Quit button in header — standard for menu bar apps
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // ── Preview Area ──
            ZStack {
                Color.black
                    .cornerRadius(10)
                
                if let previewPlayer = previewPlayer {
                    VideoPlayer(player: previewPlayer)
                        .cornerRadius(10)
                        .onAppear { previewPlayer.play() }
                } else if manager.isPlaying, let url = manager.currentVideoURL {
                    // ✅ Show currently playing video name when no new file selected
                    VStack(spacing: 8) {
                        Image(systemName: "play.desktopcomputer")
                            .font(.system(size: 36))
                            .foregroundColor(.green)
                        Text(url.lastPathComponent)
                            .foregroundColor(.green)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 36))
                            .foregroundColor(.gray)
                        Text("Pick a video to preview")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
            .frame(height: 200)
            .padding(12)
            
            // ── Error Message ──
            if let error = errorMessage ?? manager.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }
            
            // ── Controls ──
            VStack(spacing: 8) {
                
                // File name display
                if let url = selectedVideoURL {
                    Text("📁 \(url.lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal)
                }
                
                // Choose + Set row
                HStack(spacing: 8) {
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("Choose", systemImage: "folder.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        applyWallpaper()
                    } label: {
                        Label("Set", systemImage: "desktopcomputer")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedVideoURL == nil)
                }
                .padding(.horizontal, 12)
                
                // Playback controls — only show when playing
                if manager.isPlaying {
                    Divider()
                        .padding(.horizontal, 12)
                    
                    HStack(spacing: 8) {
                        // Status dot
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Live")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        // Pause / Resume
                        Button {
                            manager.togglePlayPause()
                        } label: {
                            Image(systemName: manager.isPlaying ? "pause.fill" : "play.fill")
                        }
                        .buttonStyle(.bordered)
                        
                        // Stop
                        Button {
                            manager.stopWallpaper(clearSaved: true)
                            previewPlayer = nil
                            selectedVideoURL = nil
                        } label: {
                            Image(systemName: "stop.fill")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                    .padding(.horizontal, 12)
                }
            }
            .padding(.bottom, 12)
        }
        .frame(width: 320)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.movie, .video, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            handleFilePick(result)
        }
        .onAppear {
            // ✅ Restore wallpaper when menu bar first loads
            manager.restoreLastWallpaper()
        }
    }
    
    // MARK: - Handle File Pick
    private func handleFilePick(_ result: Result<[URL], Error>) {
        errorMessage = nil
        
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            previewAccessURL?.stopAccessingSecurityScopedResource()
            previewAccessURL = nil
            
            _ = url.startAccessingSecurityScopedResource()
            previewAccessURL = url
            
            selectedVideoURL = url
            previewPlayer?.pause()
            previewPlayer = nil
            
            let item = AVPlayerItem(asset: AVAsset(url: url))
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
        manager.errorMessage = nil
        manager.setWallpaper(url: url)
    }
}