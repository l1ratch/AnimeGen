//
//  purr.swift
//  AnimeGen
//

import Foundation

struct PurrResponse: Decodable {
    let link: String
    let error: Bool?
}

enum PurrAPI {
    static let categories = [
        "background/img", "eevee/img", "holo/img", "kitsune/img", "neko/img", 
        "okami/img", "senko/img", "shiro/img", "dance/gif", "hug/gif", 
        "kiss/gif", "pat/gif", "smile/gif", "cuddle/gif", "fluff/gif"
    ]
    
    static func fetch() async throws -> AnimeArtItem {
        let category = categories.randomElement() ?? "neko/img"
        guard let url = URL(string: "https://api.purrbot.site/v2/img/sfw/\(category)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.custom.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(PurrResponse.self, from: data)
        guard let imageURL = URL(string: decoded.link) else {
            throw URLError(.cannotParseResponse)
        }
        
        let name = category.components(separatedBy: "/").first?.capitalized ?? "Purr"
        return AnimeArtItem(
            imageURL: imageURL,
            source: .purr,
            category: name,
            artistName: nil,
            artistURL: nil,
            sourceURL: nil,
            tags: [name, "purrbot"],
            isGIF: imageURL.pathExtension.lowercased() == "gif"
        )
    }
}

