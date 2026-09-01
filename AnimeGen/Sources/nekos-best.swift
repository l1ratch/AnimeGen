//
//  nekos-best.swift
//  AnimeGen
//

import Foundation

struct NekosBestResponse: Decodable {
    struct ResultItem: Decodable {
        let artist_name: String?
        let artist_href: String?
        let source_url: String?
        let url: String
    }
    let results: [ResultItem]
}

enum NekosBestAPI {
    static let categories = [
        "neko", "waifu", "kitsune", "husbando", "smile", "hug", "pat", 
        "blush", "wink", "dance", "poke", "happy", "cuddle", "smug"
    ]
    
    static func fetch() async throws -> AnimeArtItem {
        let category = categories.randomElement() ?? "neko"
        guard let url = URL(string: "https://nekos.best/api/v2/\(category)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.custom.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(NekosBestResponse.self, from: data)
        guard let first = decoded.results.first, let imageURL = URL(string: first.url) else {
            throw URLError(.cannotParseResponse)
        }
        
        return AnimeArtItem(
            imageURL: imageURL,
            source: .nekosBest,
            category: category.capitalized,
            artistName: first.artist_name,
            artistURL: first.artist_href.flatMap(URL.init(string:)),
            sourceURL: first.source_url.flatMap(URL.init(string:)),
            tags: [category, "nekos.best"],
            isGIF: imageURL.pathExtension.lowercased() == "gif"
        )
    }
}

