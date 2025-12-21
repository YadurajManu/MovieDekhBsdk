import SwiftUI
import Combine

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private let url: URL
    private var cancellable: AnyCancellable?
    private static let cache = NSCache<NSURL, UIImage>()
    private static let fileManager = FileManager.default
    
    // Create a dedicated cache directory
    private static let cacheDirectory: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = urls[0].appendingPathComponent("ImageCache")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }()
    
    init(url: URL) {
        self.url = url
        load()
    }
    
    func load() {
        // 1. Check Memory Cache
        if let cachedImage = Self.cache.object(forKey: url as NSURL) {
            self.image = cachedImage
            return
        }
        
        // 2. Check Disk Cache
        let filename = url.lastPathComponent
        let fileURL = Self.cacheDirectory.appendingPathComponent(filename)
        
        if let data = try? Data(contentsOf: fileURL), let diskImage = UIImage(data: data) {
            Self.cache.setObject(diskImage, forKey: url as NSURL)
            self.image = diskImage
            return
        }
        
        // 3. Network Fetch
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                guard let self = self, let image = image else { return }
                
                // Save to memory cache
                Self.cache.setObject(image, forKey: self.url as NSURL)
                self.image = image
                
                // Save to disk cache background
                DispatchQueue.global(qos: .background).async {
                    if let data = image.jpegData(compressionQuality: 0.8) {
                        try? data.write(to: fileURL)
                    }
                }
            }
    }
    
    func cancel() {
        cancellable?.cancel()
    }
    
    // MARK: - Cache Management
    
    static func clearCache() {
        // Clear memory cache
        cache.removeAllObjects()
        
        // Clear disk cache
        let files = (try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }
    
    static func getCacheSize() -> String {
        let files = (try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        var totalSize: Int64 = 0
        
        for file in files {
            if let resources = try? file.resourceValues(forKeys: [.fileSizeKey]),
               let size = resources.fileSize {
                totalSize += Int64(size)
            }
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
}
