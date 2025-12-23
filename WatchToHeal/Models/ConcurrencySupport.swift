import Foundation

// Mark models as Sendable to allow passing between MainActor ViewModels and background Tasks without strict concurrency checks triggering "Main actor-isolated" errors on computed properties.
// Since these are value types (structs), copying them is generally safe. The `var` properties are local state that should be managed carefully, but for this architecture, unchecked Sendable is the practical fix.

extension Movie: @unchecked Sendable {}
extension MovieDetail: @unchecked Sendable {}
extension Video: @unchecked Sendable {}
extension Genre: @unchecked Sendable {}
extension TMDBService.MovieTrailer: @unchecked Sendable {}
