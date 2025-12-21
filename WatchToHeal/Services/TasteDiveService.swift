import Foundation

class TasteDiveService {
    static let shared = TasteDiveService()
    
    private let apiKey = "1064921-YadurajS-A24DE50C"
    private let baseURL = "https://tastedive.com/api/similar"
    
    private init() {}
    
    struct TasteDiveResponse: Codable {
        let similar: SimilarResults
        
        struct SimilarResults: Codable {
            let results: [TasteDiveItem]
            
            enum CodingKeys: String, CodingKey {
                case results = "Results"
            }
        }
        
        struct TasteDiveItem: Codable {
            let name: String
            let type: String
            
            enum CodingKeys: String, CodingKey {
                case name = "Name"
                case type = "Type"
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case similar = "Similar"
        }
    }
    
    func fetchRecommendations(for seeds: [String], limit: Int = 20) async throws -> [String] {
        guard !seeds.isEmpty else { return [] }
        
        let query = seeds.joined(separator: ",").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)?q=\(query)&type=movie&k=\(apiKey)&limit=\(limit)&info=0"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Use a more flexible decoder because TasteDive casing can be tricky
        let decoder = JSONDecoder()
        let response = try decoder.decode(TasteDiveResponse.self, from: data)
        
        return response.similar.results.map { $0.name }
    }
}
