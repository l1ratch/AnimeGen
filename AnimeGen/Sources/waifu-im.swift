//
//  waifu-im.swift
//  AnimeGen
//

import Foundation

struct WaifuImResponse: Decodable {
    struct ImageItem: Decodable {
        let url: String
        let signature: String?
        let extension_name: String?
        let artist: ArtistInfo?
        
        struct ArtistInfo: Decodable {
            let name: String?
            let patreon: String?
            let pixiv: String?
            let twitter: String?
        }
    }
    let images: [ImageItem]
}

enum WaifuImAPI {
    static func fetch() async throws -> AnimeArtItem {
        guard let url = URL(string: "https://api.waifu.im/search?is_nsfw=false") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.custom.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NSError(domain: "WaifuImAPI", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(statusCode)"])
        }
        
        let decoded = try JSONDecoder().decode(WaifuImResponse.self, from: data)
        guard let first = decoded.images.first, let imageURL = URL(string: first.url) else {
            throw URLError(.cannotParseResponse)
        }
        
        return AnimeArtItem(
            imageURL: imageURL,
            source: .waifuIm,
            category: "Waifu",
            artistName: first.artist?.name,
            artistURL: first.artist?.pixiv.flatMap(URL.init(string:)) ?? first.artist?.twitter.flatMap(URL.init(string:)),
            sourceURL: imageURL,
            tags: ["waifu", "waifu.im"],
            isGIF: imageURL.pathExtension.lowercased() == "gif"
        )
    }
}

