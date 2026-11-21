import UIKit

// Downloads a picture once and remembers it in memory, so scrolling back is instant.
enum ImageLoader {
    private static let cache = NSCache<NSURL, UIImage>()

    static func cachedImage(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }

    // Returns nil when the picture cannot be downloaded or read.
    static func load(_ url: URL) async -> UIImage? {
        if let cached = cachedImage(for: url) {
            return cached
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            cache.setObject(image, forKey: url as NSURL)
            return image
        } catch {
            return nil
        }
    }
}
