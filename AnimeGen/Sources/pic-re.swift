//
//  pic-re.swift
//  AnimeGen
//

import Foundation

struct PicReResponse: Decodable {
    let file_url: String
    let author: String?
    let source: String?
    let tags: [String]?
}

enum PicReAPI {
    static func fetch() async throws -> AnimeArtItem {
        guard let url = URL(string: "https://pic.re/image.json") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.custom.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(PicReResponse.self, from: data)
        let fullURLString = decoded.file_url.hasPrefix("http") ? decoded.file_url : "https://" + decoded.file_url
        guard let imageURL = URL(string: fullURLString) else {
            throw URLError(.cannotParseResponse)
        }
        
        return AnimeArtItem(
            imageURL: imageURL,
            source: .picRe,
            category: "Illustration",
            artistName: decoded.author,
            artistURL: nil,
            sourceURL: decoded.source.flatMap(URL.init(string:)),
            tags: decoded.tags ?? ["anime", "pic.re"],
            isGIF: imageURL.pathExtension.lowercased() == "gif"
        )
    }
}

