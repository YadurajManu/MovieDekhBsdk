import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    @StateObject private var loader: ImageLoader
    private let content: (Image) -> Content
    private let placeholder: Placeholder
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        _loader = StateObject(wrappedValue: ImageLoader(url: url ?? URL(string: "https://via.placeholder.com/500")!))
        self.content = content
        self.placeholder = placeholder()
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                content(Image(uiImage: image))
            } else {
                placeholder
            }
        }
        .onDisappear {
            loader.cancel()
        }
    }
}

// Convenience initializer for simple cases
extension CachedAsyncImage where Content == Image, Placeholder == Color {
    init(url: URL?) {
        self.init(
            url: url,
            content: { image in image.resizable() },
            placeholder: { Color.gray.opacity(0.3) }
        )
    }
}
