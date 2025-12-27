import Foundation

struct PersonDetail: Codable {
    let id: Int
    let name: String
    let biography: String?
    let profilePath: String?
    let knownForDepartment: String?
    let birthday: String?
    let deathday: String?
    let placeOfBirth: String?
    let imdbId: String?
    let homepage: String?
    let images: PersonImages?
    
    enum CodingKeys: String, CodingKey {
        case id, name, biography, birthday, deathday, homepage, images
        case profilePath = "profile_path"
        case knownForDepartment = "known_for_department"
        case placeOfBirth = "place_of_birth"
        case imdbId = "imdb_id"
    }
    
    struct PersonImages: Codable {
        let profiles: [PersonImage]
    }
    
    struct PersonImage: Codable, Identifiable {
        let filePath: String
        let height: Int
        let width: Int
        let voteAverage: Double
        
        var id: String { filePath }
        
        var url: URL? {
            URL(string: "https://image.tmdb.org/t/p/original\(filePath)")
        }
        
        enum CodingKeys: String, CodingKey {
            case filePath = "file_path"
            case height, width
            case voteAverage = "vote_average"
        }
    }
    
    var profileURL: URL? {
        guard let path = profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/h632\(path)")
    }
    
    var personalInfo: [(title: String, detail: String)] {
        var info: [(String, String)] = []
        
        if let department = knownForDepartment {
            info.append(("Known For", department))
        }
        
        if let birth = birthday {
            info.append(("Birthday", birth))
        }
        
        if let place = placeOfBirth {
            info.append(("Place of Birth", place))
        }
        
        return info
    }
}

struct PersonMovieCreditsResponse: Codable {
    let cast: [Movie]
    let crew: [CrewMember]
}

struct CrewMember: Codable {
    let id: Int
    let title: String
    let posterPath: String?
    let voteAverage: Double
    let releaseDate: String?
    let job: String
    let department: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, job, department
        case posterPath = "poster_path"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
    }
}
struct IdentifiableInt: Identifiable {
    let id: Int
}

struct CombinedCreditsResponse: Codable {
    let cast: [CombinedCredit]
    let crew: [CombinedCredit]
}

struct CombinedCredit: Codable, Identifiable {
    let id: Int
    let title: String?
    let name: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double
    let mediaType: MediaType
    let character: String?
    let job: String?
    
    enum MediaType: String, Codable {
        case movie, tv
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, name, character, job
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case mediaType = "media_type"
    }
    
    var displayTitle: String {
        title ?? name ?? "Unknown"
    }
    
    var displayDate: String {
        releaseDate ?? firstAirDate ?? ""
    }
    
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w342\(path)")
    }
}
