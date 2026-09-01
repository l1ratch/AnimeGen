//
//  neko-bot.swift
//  AnimeGen
//

import Foundation

struct NekoBotResponse: Decodable {
    let success: Bool
    let message: String
}

enum NekoBotAPI {
    static let categories = ["neko", "kemonomimi", "coffee", "food"]
    
    static func fetch() async throws -> AnimeArtItem {
        let category = categories.randomElement() ?? "neko"
        guard let url = URL(string: "https://nekobot.xyz/api/image?type=\(category)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.custom.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(NekoBotResponse.self, from: data)
        guard decoded.success, let imageURL = URL(string: decoded.message) else {
            throw URLError(.cannotParseResponse)
        }
        
        return AnimeArtItem(
            imageURL: imageURL,
            source: .nekoBot,
            category: category.capitalized,
            artistName: nil,
            artistURL: nil,
            sourceURL: nil,
            tags: [category, "nekobot"],
            isGIF: imageURL.pathExtension.lowercased() == "gif"
        )
    }
}

