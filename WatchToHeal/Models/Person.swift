import Foundation

struct Person: Identifiable, Codable {
    let id: Int
    let name: String
    let profilePath: String?
    let knownForDepartment: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case profilePath = "profile_path"
        case knownForDepartment = "known_for_department"
    }
    
    var profileURL: URL? {
        guard let profilePath = profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(profilePath)")
    }
}

struct PersonResponse: Codable {
    let results: [Person]
    let page: Int
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case results, page
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}
