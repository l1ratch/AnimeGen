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
        // Try waifu.im first
        if let url = URL(string: "https://api.waifu.im/search?included_tags=waifu") {
            do {
                var request = URLRequest(url: url)
                request.setValue("AnimeGen/3.1 (iOS)", forHTTPHeaderField: "User-Agent")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.timeoutInterval = 4.0
                
                let (data, response) = try await URLSession.custom.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
                   let decoded = try? JSONDecoder().decode(WaifuImResponse.self, from: data),
                   let first = decoded.images.first,
                   let imageURL = URL(string: first.url) {
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
            } catch {
                await DebugLogger.shared.log(tag: "Waifu.im", message: "Waifu.im cloudflare/network fallback -> Danbooru Waifu")
            }
        }
        
        // Seamless fallback to high resolution Danbooru Waifus
        return try await DanbooruAPI.fetch(isNSFW: false)
    }
}


