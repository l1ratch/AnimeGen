//
//  URLSession.swift
//  AnimeGen
//

import Foundation
import CFNetwork
import CoreFoundation

public struct ProxyConfig: Codable, Equatable {
    public var isEnabled: Bool = false
    public var host: String = ""
    public var port: Int = 8080
    public var isSOCKS: Bool = false
    public var username: String = ""
    public var password: String = ""
    
    public init(
        isEnabled: Bool = false,
        host: String = "",
        port: Int = 8080,
        isSOCKS: Bool = false,
        username: String = "",
        password: String = ""
    ) {
        self.isEnabled = isEnabled
        self.host = host
        self.port = port
        self.isSOCKS = isSOCKS
        self.username = username
        self.password = password
    }
}

public enum AppNetworkManager {
    public static var currentProxy: ProxyConfig = {
        if let data = UserDefaults.standard.data(forKey: "app_proxy_config_v1"),
           let decoded = try? JSONDecoder().decode(ProxyConfig.self, from: data) {
            return decoded
        }
        return ProxyConfig()
    }()
    
    public static func saveProxy(_ config: ProxyConfig) {
        currentProxy = config
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: "app_proxy_config_v1")
        }
    }
    
    public static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 6.0
        configuration.timeoutIntervalForResource = 15.0
        configuration.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Safari/604.1",
            "Accept": "application/json, image/*, */*"
        ]
        
        if currentProxy.isEnabled && !currentProxy.host.isEmpty && currentProxy.port > 0 {
            var proxyDict: [AnyHashable: Any] = [:]
            
            if currentProxy.isSOCKS {
                proxyDict[kCFStreamPropertySOCKSProxyHost as String] = currentProxy.host
                proxyDict[kCFStreamPropertySOCKSProxyPort as String] = currentProxy.port
                if !currentProxy.username.isEmpty {
                    proxyDict[kCFStreamPropertySOCKSUser as String] = currentProxy.username
                    proxyDict[kCFStreamPropertySOCKSPassword as String] = currentProxy.password
                }
            } else {
                proxyDict[kCFNetworkProxiesHTTPEnable as String] = 1
                proxyDict[kCFNetworkProxiesHTTPProxy as String] = currentProxy.host
                proxyDict[kCFNetworkProxiesHTTPPort as String] = currentProxy.port
                proxyDict[kCFNetworkProxiesHTTPSEnable as String] = 1
                proxyDict[kCFNetworkProxiesHTTPSProxy as String] = currentProxy.host
                proxyDict[kCFNetworkProxiesHTTPSPort as String] = currentProxy.port
                
                if !currentProxy.username.isEmpty {
                    proxyDict[kCFProxyUsernameKey as String] = currentProxy.username
                    proxyDict[kCFProxyPasswordKey as String] = currentProxy.password
                }
            }
            configuration.connectionProxyDictionary = proxyDict
        }
        
        return URLSession(configuration: configuration)
    }
}

extension URLSession {
    public static var custom: URLSession {
        AppNetworkManager.makeSession()
    }
}

