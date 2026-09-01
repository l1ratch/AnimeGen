//
//  URLSession.swift
//  AnimeGen
//

import Foundation

extension URLSession {
    static let custom: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5.0
        configuration.timeoutIntervalForResource = 15.0
        configuration.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Safari/604.1",
            "Accept": "application/json, image/*, */*"
        ]
        return URLSession(configuration: configuration)
    }()
}

