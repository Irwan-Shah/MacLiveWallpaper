import Foundation

class BookmarkManager {
    private static let key = "lastVideoBookmark"
    
    // ✅ Save bookmark data from a security-scoped URL
    // Call this right after user picks a file and access is granted
    static func saveBookmark(for url: URL) {
        do {
            // .withSecurityScope = persistent access across launches
            // .securityScopeAllowOnlyReadAccess = we only need to read the video
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: key)
            print("✅ Bookmark saved for: \(url.lastPathComponent)")
        } catch {
            print("❌ Failed to save bookmark: \(error.localizedDescription)")
        }
    }
    
    // ✅ Load and resolve bookmark back into a usable URL
    // Returns nil if no bookmark saved, or if file was deleted/moved
    static func loadBookmark() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: key) else {
            print("ℹ️ No saved bookmark found")
            return nil
        }
        
        do {
            var isStale = false
            // isStale = true means file moved — we resolve it but should re-save
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                // File was moved — re-save with new location
                print("⚠️ Bookmark is stale, re-saving...")
                saveBookmark(for: url)
            }
            
            print("✅ Bookmark resolved: \(url.lastPathComponent)")
            return url
            
        } catch {
            // File was deleted or bookmark is corrupt — clear it
            print("❌ Failed to resolve bookmark: \(error.localizedDescription)")
            clearBookmark()
            return nil
        }
    }
    
    // ✅ Clear saved bookmark — call when user stops wallpaper intentionally
    static func clearBookmark() {
        UserDefaults.standard.removeObject(forKey: key)
        print("🗑️ Bookmark cleared")
    }
}