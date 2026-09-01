import Foundation

struct OtakuGifResponse: Decodable {
    let url: String
}

enum WaifuPicsAPI {
    static let reactions = [
        "hug", "kiss", "pat", "cuddle", "dance", "slap", 
        "poke", "smile", "blush", "wink", "happy", "cry", "pout", "smug"
    ]
    
    static let waifuCategories = [
        "waifu", "neko", "shinobu", "megumin", "cuddle", "hug",
        "kiss", "pat", "smug", "blush", "smile", "wave", "dance", "happy"
    ]
    
    static func fetch(orientation: OrientationMode = .any) async throws -> AnimeArtItem {
        if orientation == .vertical {
            let cat = waifuCategories.randomElement() ?? "waifu"
            guard let url = URL(string: "https://api.waifu.pics/sfw/\(cat)") else {
                throw URLError(.badURL)
            }
            let (data, response) = try await URLSession.custom.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            struct WaifuPicsResp: Decodable {
                let url: String
            }
            let decoded = try JSONDecoder().decode(WaifuPicsResp.self, from: data)
            guard let imageURL = URL(string: decoded.url) else {
                throw URLError(.cannotParseResponse)
            }
            let isGif = decoded.url.lowercased().hasSuffix(".gif")
            return AnimeArtItem(
                imageURL: imageURL,
                source: .waifupics,
                category: cat.capitalized + (isGif ? " GIF" : " Art"),
                artistName: nil,
                artistURL: nil,
                sourceURL: nil,
                tags: [cat, isGif ? "gif" : "anime"],
                isGIF: isGif
            )
        } else {
            let reaction = reactions.randomElement() ?? "hug"
            // Try OtakuGIFs first
            if let url = URL(string: "https://api.otakugifs.xyz/gif?reaction=\(reaction)") {
                do {
                    var request = URLRequest(url: url)
                    request.timeoutInterval = 4.0
                    let (data, response) = try await URLSession.custom.data(for: request)
                    if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
                       let decoded = try? JSONDecoder().decode(OtakuGifResponse.self, from: data),
                       let imageURL = URL(string: decoded.url) {
                        return AnimeArtItem(
                            imageURL: imageURL,
                            source: .waifupics,
                            category: reaction.capitalized + " GIF",
                            artistName: nil,
                            artistURL: nil,
                            sourceURL: nil,
                            tags: [reaction, "gif", "animation"],
                            isGIF: true
                        )
                    }
                } catch {
                    await DebugLogger.shared.log(tag: "OtakuGIFs", message: "OtakuGIFs proxy fallback -> NekosBest / WaifuPics: \(error.localizedDescription)")
                }
            }
            
            // Seamless fallback 1: waifu.pics sfw reaction
            if let url = URL(string: "https://api.waifu.pics/sfw/\(reaction)") {
                do {
                    let (data, response) = try await URLSession.custom.data(from: url)
                    if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                        struct WaifuPicsResp: Decodable { let url: String }
                        if let decoded = try? JSONDecoder().decode(WaifuPicsResp.self, from: data),
                           let imageURL = URL(string: decoded.url) {
                            let isGif = decoded.url.lowercased().hasSuffix(".gif")
                            return AnimeArtItem(
                                imageURL: imageURL,
                                source: .waifupics,
                                category: reaction.capitalized + (isGif ? " GIF" : " Art"),
                                artistName: nil,
                                artistURL: nil,
                                sourceURL: nil,
                                tags: [reaction, isGif ? "gif" : "anime"],
                                isGIF: isGif
                            )
                        }
                    }
                } catch {}
            }
            
            // Seamless fallback 2: NekosBest reaction
            return try await NekosBestAPI.fetch(orientation: orientation)
        }
    }
}

