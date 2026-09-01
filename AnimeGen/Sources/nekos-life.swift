//
//  nekos-life.swift
//  AnimeGen
//

import Foundation

struct NekosLifeResponse: Decodable {
    let url: String
}

enum NekosLifeAPI {
    static let categories = [
        "neko", "waifu", "hug", "kiss", "pat", "cuddle", 
        "slap", "poke", "feed", "tickle", "smug", "fox_girl", "wallpaper"
    ]
    
    static func fetch() async throws -> AnimeArtItem {
        let category = categories.randomElement() ?? "neko"
        guard let url = URL(string: "https://nekos.life/api/v2/img/\(category)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.custom.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(NekosLifeResponse.self, from: data)
        guard let imageURL = URL(string: decoded.url) else {
            throw URLError(.cannotParseResponse)
        }
        
        return AnimeArtItem(
            imageURL: imageURL,
            source: .nekosLife,
            category: category.capitalized,
            artistName: nil,
            artistURL: nil,
            sourceURL: nil,
            tags: [category, "nekos.life"],
            isGIF: imageURL.pathExtension.lowercased() == "gif"
        )
    }
}

