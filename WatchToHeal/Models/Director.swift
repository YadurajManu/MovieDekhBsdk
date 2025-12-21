import Foundation

struct Director: Identifiable, Codable {
    let id: Int
    let name: String
    let biography: String?
    let profilePath: String?
    
    var profileURL: URL? {
        guard let profilePath = profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(profilePath)")
    }
}
