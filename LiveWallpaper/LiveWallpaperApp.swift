import SwiftUI

@main
struct LiveWallpaperApp: App {
    @StateObject private var manager = WallpaperManager.shared
    @State private var showMainWindow = false
    
    var body: some Scene {
        
        // ── Main Window ──
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        
        // ── Menu Bar ──
        MenuBarExtra("Live Wallpaper", systemImage: menuBarIcon) {
            
            if manager.isPlaying {
                Text("Now Playing")
                    .font(.headline)
                
                if let url = manager.currentVideoURL {
                    Text(url.lastPathComponent)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Divider()
                
                Button(manager.isPlaying ? "Pause" : "Resume") {
                    manager.togglePlayPause()
                }
                
                Button("Stop Wallpaper") {
                    manager.stopWallpaper()
                }
                .foregroundColor(.red)
                
            } else {
                Text("No wallpaper active")
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            Button("Open App") {
                NSApp.activate(ignoringOtherApps: true)
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    // Change icon based on state
    private var menuBarIcon: String {
        manager.isPlaying ? "play.desktopcomputer" : "desktopcomputer"
    }
}
