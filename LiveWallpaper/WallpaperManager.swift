import Foundation
import AVFoundation
import AppKit
import Combine

class WallpaperManager: NSObject, ObservableObject {
    static let shared = WallpaperManager()
    
    private var playerWindows: [NSWindow] = []
    private var player: AVPlayer?
    
    @Published var isPlaying: Bool = false
    @Published var currentVideoURL: URL? = nil
    
    private override init() {
        super.init()
    }
    
    // MARK: - Set Video as Wallpaper
    func setWallpaper(url: URL) {
        stopWallpaper()
        currentVideoURL = url
        
        // ✅ Must access security scoped resource
        _ = url.startAccessingSecurityScopedResource()
        
        let asset = AVAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        self.player = player
        
        // Loop forever
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
        
        // Wait for asset to be ready before showing
        item.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        
        for screen in NSScreen.screens {
            createWallpaperWindow(for: screen, player: player)
        }
        
        player.play()
        isPlaying = true
    }
    
    // ✅ Observe player item status
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let item = object as? AVPlayerItem {
                switch item.status {
                case .readyToPlay:
                    print("✅ Player ready to play")
                    DispatchQueue.main.async {
                        self.player?.play()
                    }
                case .failed:
                    print("❌ Player failed: \(item.error?.localizedDescription ?? "unknown")")
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Create Wallpaper Window
    private func createWallpaperWindow(for screen: NSScreen, player: AVPlayer) {
        // ✅ Use screen.frame for position, bounds for layer
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isOpaque = true
        window.hasShadow = false
        window.backgroundColor = .black
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        
        // ✅ Content view with correct frame
        let contentView = NSView(frame: CGRect(origin: .zero, size: screen.frame.size))
        contentView.wantsLayer = true
        
        // ✅ Player layer using bounds not screen.frame
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = contentView.bounds
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = NSColor.black.cgColor
        
        contentView.layer?.addSublayer(playerLayer)
        window.contentView = contentView
        window.setFrame(screen.frame, display: true)
        window.orderFront(nil)
        
        print("✅ Wallpaper window created for screen: \(screen.localizedName)")
        print("   Frame: \(screen.frame)")
        
        playerWindows.append(window)
    }
    
    // MARK: - Controls
    func pauseWallpaper() {
        player?.pause()
        isPlaying = false
    }
    
    func resumeWallpaper() {
        player?.play()
        isPlaying = true
    }
    
    func stopWallpaper() {
        player?.pause()
        player = nil
        playerWindows.forEach { $0.close() }
        playerWindows.removeAll()
        isPlaying = false
        currentVideoURL = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    func togglePlayPause() {
        isPlaying ? pauseWallpaper() : resumeWallpaper()
    }
}
