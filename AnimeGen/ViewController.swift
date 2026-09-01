//
//  ViewController.swift
//  AnimeGen
//

import UIKit
import SwiftUI
import Photos
import Kingfisher
import SafariServices

// MARK: - Models

public enum ImageSource: String, CaseIterable, Identifiable {
    case nekosBest = "nekosBest"
    case picRe = "picRe"
    case nekoBot = "nekoBot"
    case nekosApi = "nekosApi"
    case nekosLife = "nekosLife"
    case nekosMoe = "nekosMoe"
    case purr = "purr"
    case waifupics = "waifuPics"
    case waifuIm = "waifuIm"
    case random = "random"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .nekosBest: return "Nekos Best"
        case .picRe: return "Pic.re HD"
        case .nekoBot: return "NekoBot"
        case .nekosApi: return "Nekos API"
        case .nekosLife: return "Nekos Life"
        case .nekosMoe: return "Nekos Moe"
        case .purr: return "PurrBot"
        case .waifupics: return "Otaku GIFs"
        case .waifuIm: return "Waifu.im"
        case .random: return "Random Mix"
        }
    }
    
    public var iconName: String {
        switch self {
        case .nekosBest: return "sparkles"
        case .picRe: return "photo.artframe"
        case .nekoBot: return "cat.fill"
        case .nekosApi: return "star.fill"
        case .nekosLife: return "heart.fill"
        case .nekosMoe: return "paintpalette.fill"
        case .purr: return "pawprint.fill"
        case .waifupics: return "play.rectangle.fill"
        case .waifuIm: return "person.crop.circle.fill"
        case .random: return "dice.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .nekosBest: return "High-res anime characters & actions"
        case .picRe: return "High quality Pixiv anime illustrations"
        case .nekoBot: return "Kemonomimi, nekos & anime art"
        case .nekosApi: return "Curated anime illustrations database"
        case .nekosLife: return "Classic reactions & waifus"
        case .nekosMoe: return "Community-curated anime gallery"
        case .purr: return "Cute wallpapers & reaction GIFs"
        case .waifupics: return "High quality animated anime GIFs"
        case .waifuIm: return "Diverse waifu illustrations"
        case .random: return "Picks a random source every time"
        }
    }
    
    public var tag: String {
        switch self {
        case .waifupics: return "GIF"
        case .picRe: return "HD"
        case .nekosBest: return "Top"
        case .random: return "Mix"
        default: return "SFW"
        }
    }
}

public struct AnimeArtItem: Identifiable, Equatable {
    public let id = UUID()
    public let imageURL: URL
    public let source: ImageSource
    public let category: String
    public let artistName: String?
    public let artistURL: URL?
    public let sourceURL: URL?
    public let tags: [String]
    public let isGIF: Bool
    public let timestamp: Date
    
    public init(
        imageURL: URL,
        source: ImageSource,
        category: String = "Anime",
        artistName: String? = nil,
        artistURL: URL? = nil,
        sourceURL: URL? = nil,
        tags: [String] = [],
        isGIF: Bool = false
    ) {
        self.imageURL = imageURL
        self.source = source
        self.category = category
        self.artistName = artistName
        self.artistURL = artistURL
        self.sourceURL = sourceURL
        self.tags = tags
        self.isGIF = isGIF
        self.timestamp = Date()
    }
    
    public static func == (lhs: AnimeArtItem, rhs: AnimeArtItem) -> Bool {
        lhs.imageURL == rhs.imageURL
    }
}

// MARK: - Debug Logger

public struct DebugLogEntry: Identifiable {
    public let id = UUID()
    public let timestamp = Date()
    public let tag: String
    public let message: String
    public let isError: Bool
    public let details: String?
    
    public var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}

@MainActor
public class DebugLogger: ObservableObject {
    public static let shared = DebugLogger()
    
    @Published public var logs: [DebugLogEntry] = []
    
    public func log(tag: String, message: String, isError: Bool = false, details: String? = nil) {
        let entry = DebugLogEntry(tag: tag, message: message, isError: isError, details: details)
        logs.append(entry)
        if logs.count > 250 {
            logs.removeFirst(50)
        }
    }
    
    public func clear() {
        logs.removeAll()
    }
    
    public var allLogsFormatted: String {
        let device = UIDevice.current
        var text = "=== AnimeGen Debug Log ===\n"
        text += "App Version: 3.1.0-beta.2 (Build 3)\n"
        text += "iOS: \(device.systemName) \(device.systemVersion)\n"
        text += "Device: \(device.model)\n"
        text += "Total Logs: \(logs.count)\n"
        text += "===========================\n\n"
        
        let logsText = logs.map { entry in
            var logLine = "[\(entry.timeString)] [\(entry.tag)] \(entry.isError ? "❌ " : "ℹ️ ")\(entry.message)"
            if let details = entry.details, !details.isEmpty {
                logLine += "\n  Details: \(details)"
            }
            return logLine
        }.joined(separator: "\n\n")
        
        return text + logsText
    }
}

// MARK: - ViewModel

@MainActor
public class AnimeGenViewModel: ObservableObject {
    @Published public var currentItem: AnimeArtItem?
    @Published public var history: [AnimeArtItem] = []
    @Published public var favorites: [AnimeArtItem] = []
    @Published public var historyIndex: Int = -1
    @Published public var selectedSource: ImageSource = .nekosBest
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var failedSource: ImageSource? = nil
    @Published public var toastMessage: String? = nil
    
    @Published public var showSourceSheet: Bool = false
    @Published public var showHistorySheet: Bool = false
    @Published public var showFavoritesSheet: Bool = false
    @Published public var showDebugSheet: Bool = false
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    public init() {
        if let savedSource = UserDefaults.standard.string(forKey: "selectedSource"),
           let source = ImageSource(rawValue: savedSource) {
            self.selectedSource = source
        }
        DebugLogger.shared.log(tag: "App", message: "AnimeGen initialized with source: \(selectedSource.displayName)")
        loadNewImage()
    }
    
    public func setSource(_ source: ImageSource) {
        selectedSource = source
        UserDefaults.standard.set(source.rawValue, forKey: "selectedSource")
        DebugLogger.shared.log(tag: "Source", message: "User selected source: \(source.displayName)")
        showToast("Switched to \(source.displayName)")
        loadNewImage()
    }
    
    public func loadNewImage(targetSource: ImageSource? = nil) {
        let sourceToUse = targetSource ?? selectedSource
        let actualSource: ImageSource
        if sourceToUse == .random {
            let selectableSources = ImageSource.allCases.filter { $0 != .random }
            actualSource = selectableSources.randomElement() ?? .nekosBest
        } else {
            actualSource = sourceToUse
        }
        
        isLoading = true
        errorMessage = nil
        failedSource = nil
        impactFeedback.prepare()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        DebugLogger.shared.log(tag: "Fetch", message: "Requesting art from \(actualSource.displayName)...")
        
        Task {
            do {
                let item: AnimeArtItem
                switch actualSource {
                case .nekosBest:
                    item = try await NekosBestAPI.fetch()
                case .picRe:
                    item = try await PicReAPI.fetch()
                case .nekoBot:
                    item = try await NekoBotAPI.fetch()
                case .nekosApi:
                    item = try await NekosApiAPI.fetch()
                case .nekosLife:
                    item = try await NekosLifeAPI.fetch()
                case .nekosMoe:
                    item = try await NekosMoeAPI.fetch()
                case .purr:
                    item = try await PurrAPI.fetch()
                case .waifupics:
                    item = try await WaifuPicsAPI.fetch()
                case .waifuIm:
                    item = try await WaifuImAPI.fetch()
                case .random:
                    item = try await NekosBestAPI.fetch()
                }
                
                let duration = String(format: "%.2f", (CFAbsoluteTimeGetCurrent() - startTime) * 1000)
                DebugLogger.shared.log(tag: "Fetch", message: "Received \(item.category) from \(actualSource.displayName) in \(duration)ms", isError: false, details: item.imageURL.absoluteString)
                
                self.currentItem = item
                self.history.append(item)
                self.historyIndex = self.history.count - 1
                self.isLoading = false
            } catch {
                let duration = String(format: "%.2f", (CFAbsoluteTimeGetCurrent() - startTime) * 1000)
                let errDesc = error.localizedDescription
                DebugLogger.shared.log(tag: "Fetch", message: "Failed \(actualSource.displayName) after \(duration)ms: \(errDesc)", isError: true, details: "\(error)")
                
                self.failedSource = actualSource
                self.errorMessage = "Сервер \(actualSource.displayName) временно недоступен или отклонил запрос."
                self.isLoading = false
            }
        }
    }
    
    public func goPrevious() {
        guard historyIndex > 0 else { return }
        historyIndex -= 1
        currentItem = history[historyIndex]
        errorMessage = nil
        failedSource = nil
        impactFeedback.impactOccurred()
    }
    
    public func goNext() {
        if historyIndex < history.count - 1 {
            historyIndex += 1
            currentItem = history[historyIndex]
            errorMessage = nil
            failedSource = nil
            impactFeedback.impactOccurred()
        } else {
            loadNewImage()
        }
    }
    
    public var isFavorite: Bool {
        guard let current = currentItem else { return false }
        return favorites.contains { $0.imageURL == current.imageURL }
    }
    
    public func toggleFavorite() {
        guard let current = currentItem else { return }
        if let idx = favorites.firstIndex(where: { $0.imageURL == current.imageURL }) {
            favorites.remove(at: idx)
            showToast("Removed from favorites")
        } else {
            favorites.append(current)
            notificationFeedback.notificationOccurred(.success)
            showToast("Added to favorites! ❤️")
        }
    }
    
    public func saveToPhotos() {
        guard let current = currentItem else { return }
        
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self.showToast("Photos access required in Settings")
                }
                return
            }
            
            let url = current.imageURL
            let isGIF = current.isGIF || url.pathExtension.lowercased() == "gif"
            
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                guard let self = self else { return }
                guard let data = data, error == nil else {
                    DispatchQueue.main.async {
                        self.showToast("Failed to download image")
                    }
                    return
                }
                
                if isGIF {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_\(UUID().uuidString).gif")
                    do {
                        try data.write(to: tempURL)
                        PHPhotoLibrary.shared().performChanges({
                            let req = PHAssetCreationRequest.forAsset()
                            req.addResource(with: .photo, fileURL: tempURL, options: nil)
                        }) { success, _ in
                            try? FileManager.default.removeItem(at: tempURL)
                            DispatchQueue.main.async {
                                if success {
                                    self.notificationFeedback.notificationOccurred(.success)
                                    self.showToast("GIF saved to Photos! 🎉")
                                } else {
                                    self.showToast("Failed to save GIF")
                                }
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.showToast("Failed to write GIF data")
                        }
                    }
                } else if let image = UIImage(data: data) {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }) { success, _ in
                        DispatchQueue.main.async {
                            if success {
                                self.notificationFeedback.notificationOccurred(.success)
                                self.showToast("Saved to Photos! 🎉")
                            } else {
                                self.showToast("Failed to save image")
                            }
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    public func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if self.toastMessage == message {
                self.toastMessage = nil
            }
        }
    }
    
    public func clearCache() {
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache {
            DispatchQueue.main.async {
                self.showToast("Image cache cleared! 🧹")
                DebugLogger.shared.log(tag: "Cache", message: "Disk and memory image cache cleared")
            }
        }
    }
}

// MARK: - Modern SwiftUI UI

struct ModernContentView: View {
    @StateObject private var viewModel = AnimeGenViewModel()
    @StateObject private var debugLogger = DebugLogger.shared
    @State private var dragOffset: CGFloat = 0
    @State private var zoomScale: CGFloat = 1.0
    @State private var showHeartAnimation: Bool = false
    
    var body: some View {
        ZStack {
            // Ambient dynamic background blur
            ambientBackground
                .ignoresSafeArea()
            
            // Safe Area Main Content
            VStack(spacing: 8) {
                // Top Glass Header Bar
                topHeaderBar
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                
                // Center Interactive HD Canvas
                mainImageCanvas
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                
                // Bottom Compact Floating Toolbar Capsule
                bottomToolbarCapsule
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)
            }
            
            // Toast HUD
            if let toast = viewModel.toastMessage {
                VStack {
                    toastView(text: toast)
                        .padding(.top, 48)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
            
            // Double-Tap Heart Overlay Animation
            if showHeartAnimation {
                Image(systemName: "heart.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.red.opacity(0.9))
                    .scaleEffect(showHeartAnimation ? 1.2 : 0.4)
                    .opacity(showHeartAnimation ? 1 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: showHeartAnimation)
                    .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
            }
        }
        .sheet(isPresented: $viewModel.showSourceSheet) {
            SourcePickerSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showHistorySheet) {
            GallerySheet(
                title: "Session History",
                items: viewModel.history,
                onSelect: { item in
                    viewModel.currentItem = item
                    viewModel.errorMessage = nil
                    viewModel.failedSource = nil
                    viewModel.showHistorySheet = false
                }
            )
        }
        .sheet(isPresented: $viewModel.showFavoritesSheet) {
            GallerySheet(
                title: "Favorites",
                items: viewModel.favorites,
                onSelect: { item in
                    viewModel.currentItem = item
                    viewModel.errorMessage = nil
                    viewModel.failedSource = nil
                    viewModel.showFavoritesSheet = false
                }
            )
        }
        .sheet(isPresented: $viewModel.showDebugSheet) {
            DebugConsoleSheet(viewModel: viewModel, logger: debugLogger)
        }
    }
    
    // MARK: - Ambient Background
    private var ambientBackground: some View {
        ZStack {
            Color(UIColor.systemBackground)
            
            if let current = viewModel.currentItem {
                KFImage(current.imageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 60)
                    .opacity(0.3)
            }
            
            LinearGradient(
                colors: [Color.black.opacity(0.12), Color.clear, Color.black.opacity(0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        HStack(spacing: 8) {
            // Source Selector Button
            Button(action: {
                viewModel.showSourceSheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.selectedSource.iconName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.pink)
                    
                    Text(viewModel.selectedSource.displayName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
            }
            
            Spacer()
            
            // Build Beta Badge (Tap opens Debug Console)
            Button(action: {
                viewModel.showDebugSheet = true
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "ladybug.fill")
                        .font(.system(size: 9))
                    Text("b3")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.18), in: Capsule())
                .foregroundColor(.purple)
            }
            
            // Favorites & History Compact Pills
            HStack(spacing: 6) {
                Button(action: {
                    viewModel.showFavoritesSheet = true
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                        if !viewModel.favorites.isEmpty {
                            Text("\(viewModel.favorites.count)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
                
                Button(action: {
                    viewModel.showHistorySheet = true
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12))
                            .foregroundColor(.accentColor)
                        if !viewModel.history.isEmpty {
                            Text("\(viewModel.history.count)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Main Image Canvas
    private var mainImageCanvas: some View {
        ZStack {
            // Glass Card Canvas Container
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 6)
            
            if let _ = viewModel.errorMessage, let failedSrc = viewModel.failedSource {
                // Apple Liquid Glass Error State
                liquidGlassErrorView(source: failedSrc)
            } else if let item = viewModel.currentItem {
                KFImage(item.imageURL)
                    .placeholder {
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading HD Art...")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .fade(duration: 0.2)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(6)
                    .scaleEffect(zoomScale)
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                if value.translation.width < -50 {
                                    viewModel.goNext()
                                } else if value.translation.width > 50 {
                                    viewModel.goPrevious()
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dragOffset = 0
                                }
                            }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { scale in
                                zoomScale = max(1.0, min(scale, 4.0))
                            }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    zoomScale = 1.0
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        viewModel.toggleFavorite()
                        showHeartAnimation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            showHeartAnimation = false
                        }
                    }
                
                // Metadata Badges
                VStack {
                    HStack {
                        Text(item.category)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if item.isGIF {
                            Text("GIF")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.pink.opacity(0.9), in: Capsule())
                                .foregroundColor(.white)
                        }
                    }
                    .padding(10)
                    
                    Spacer()
                    
                    if let artist = item.artistName, !artist.isEmpty {
                        HStack {
                            Label(artist, systemImage: "paintpalette.fill")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(10)
                    }
                }
            } else if viewModel.isLoading {
                VStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(1.3)
                    Text("Summoning anime art...")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
    
    // MARK: - Liquid Glass Error Card
    private func liquidGlassErrorView(source: ImageSource) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.18))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 6) {
                Text("Источник не отвечает")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Сервер \(source.displayName) временно недоступен или отклонил соединение.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 10) {
                Button(action: {
                    viewModel.showSourceSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2.fill")
                        Text("Выбрать другой источник")
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: 240)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color.pink, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: Color.pink.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                
                Button(action: {
                    viewModel.loadNewImage()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Повторить попытку")
                    }
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(maxWidth: 240)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                
                Button(action: {
                    viewModel.showDebugSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "ladybug")
                        Text("Посмотреть логи отладки")
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(24)
    }
    
    // MARK: - Bottom Floating Toolbar Capsule
    private var bottomToolbarCapsule: some View {
        HStack(spacing: 12) {
            // Previous Button
            Button(action: {
                viewModel.goPrevious()
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(viewModel.historyIndex > 0 ? .primary : .secondary.opacity(0.4))
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .disabled(viewModel.historyIndex <= 0)
            
            // Favorite Button
            Button(action: {
                viewModel.toggleFavorite()
            }) {
                Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(viewModel.isFavorite ? .red : .primary)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
            }
            
            // Generate / Next Hero FAB Button
            Button(action: {
                viewModel.loadNewImage()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.pink, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.pink.opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(viewModel.isLoading)
            
            // Save to Photos Button
            Button(action: {
                viewModel.saveToPhotos()
            }) {
                Image(systemName: "arrow.down.to.line")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
            }
            
            // Share Sheet Button
            Button(action: {
                shareCurrentArt()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Toast HUD View
    private func toastView(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.pink)
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
    
    private func shareCurrentArt() {
        guard let current = viewModel.currentItem else { return }
        let activityVC = UIActivityViewController(activityItems: [current.imageURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? windowScene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Source Picker Sheet

struct SourcePickerSheet: View {
    @ObservedObject var viewModel: AnimeGenViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Choose Art Source").font(.caption)) {
                    ForEach(ImageSource.allCases) { source in
                        Button(action: {
                            viewModel.setSource(source)
                            dismiss()
                        }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(source == viewModel.selectedSource ? Color.pink.opacity(0.2) : Color.gray.opacity(0.15))
                                        .frame(width: 38, height: 38)
                                    Image(systemName: source.iconName)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(source == viewModel.selectedSource ? .pink : .secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(source.displayName)
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(.primary)
                                        
                                        Text(source.tag)
                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(source == .waifupics ? Color.pink.opacity(0.2) : Color.blue.opacity(0.15), in: Capsule())
                                            .foregroundColor(source == .waifupics ? .pink : .blue)
                                    }
                                    
                                    Text(source.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if source == viewModel.selectedSource {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.pink)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Image Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Gallery & Favorites Sheet

struct GallerySheet: View {
    let title: String
    let items: [AnimeArtItem]
    let onSelect: (AnimeArtItem) -> Void
    @Environment(\.dismiss) var dismiss
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        NavigationView {
            Group {
                if items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No art pieces yet")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(items.reversed()) { item in
                                Button(action: {
                                    onSelect(item)
                                }) {
                                    KFImage(item.imageURL)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 180)
                                        .clipped()
                                        .cornerRadius(14)
                                        .overlay(
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Text(item.source.displayName)
                                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 3)
                                                        .background(.ultraThinMaterial, in: Capsule())
                                                        .foregroundColor(.primary)
                                                    Spacer()
                                                }
                                                .padding(6)
                                            }
                                        )
                                }
                            }
                        }
                        .padding(12)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Hidden Debug Console Sheet

struct DebugConsoleSheet: View {
    @ObservedObject var viewModel: AnimeGenViewModel
    @ObservedObject var logger: DebugLogger
    @Environment(\.dismiss) var dismiss
    
    @State private var pingResults: [String: String] = [:]
    @State private var isPinging: Bool = false
    @State private var filterErrorsOnly: Bool = false
    
    var filteredLogs: [DebugLogEntry] {
        if filterErrorsOnly {
            return logger.logs.filter { $0.isError }
        }
        return logger.logs
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Quick Action Bar
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button(action: pingAllSources) {
                            HStack(spacing: 4) {
                                Image(systemName: isPinging ? "waveform.path.ecg" : "bolt.horizontal.fill")
                                Text(isPinging ? "Pinging..." : "Test All Sources")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.15), in: Capsule())
                            .foregroundColor(.blue)
                        }
                        .disabled(isPinging)
                        
                        Button(action: {
                            UIPasteboard.general.string = logger.allLogsFormatted
                            viewModel.showToast("Full logs copied to Clipboard! 📋")
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc.fill")
                                Text("Copy Logs")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.15), in: Capsule())
                            .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.clearCache()
                        }) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 12))
                                .padding(7)
                                .background(Color.orange.opacity(0.15), in: Circle())
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: {
                            logger.clear()
                        }) {
                            Image(systemName: "xmark.bin.fill")
                                .font(.system(size: 12))
                                .padding(7)
                                .background(Color.red.opacity(0.15), in: Circle())
                                .foregroundColor(.red)
                        }
                    }
                    
                    Toggle(isOn: $filterErrorsOnly) {
                        Text("Show Errors & Warnings Only")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemBackground))
                
                // Ping Results List if available
                if !pingResults.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Source Status:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Array(pingResults.keys.sorted()), id: \.self) { key in
                                    let val = pingResults[key] ?? ""
                                    HStack(spacing: 4) {
                                        Text(key)
                                            .font(.system(size: 10, weight: .bold))
                                        Text(val)
                                            .font(.system(size: 10, design: .monospaced))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(val.contains("❌") ? Color.red.opacity(0.15) : Color.green.opacity(0.15), in: Capsule())
                                    .foregroundColor(val.contains("❌") ? .red : .green)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(UIColor.tertiarySystemBackground))
                }
                
                // Real-time Logs List
                if filteredLogs.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "terminal")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("No logs recorded yet")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredLogs.reversed()) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(entry.timeString)
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    
                                    Text(entry.tag)
                                        .font(.system(size: 10, weight: .black, design: .rounded))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(entry.isError ? Color.red.opacity(0.2) : Color.blue.opacity(0.15), in: Capsule())
                                        .foregroundColor(entry.isError ? .red : .blue)
                                    
                                    Spacer()
                                }
                                
                                Text(entry.message)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(entry.isError ? .red : .primary)
                                
                                if let details = entry.details, !details.isEmpty {
                                    Text(details)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Live Debug Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func pingAllSources() {
        isPinging = true
        pingResults.removeAll()
        
        let testable = ImageSource.allCases.filter { $0 != .random }
        Task {
            await withTaskGroup(of: (String, String).self) { group in
                for source in testable {
                    group.addTask {
                        let t0 = CFAbsoluteTimeGetCurrent()
                        do {
                            switch source {
                            case .nekosBest: _ = try await NekosBestAPI.fetch()
                            case .picRe: _ = try await PicReAPI.fetch()
                            case .nekoBot: _ = try await NekoBotAPI.fetch()
                            case .nekosApi: _ = try await NekosApiAPI.fetch()
                            case .nekosLife: _ = try await NekosLifeAPI.fetch()
                            case .nekosMoe: _ = try await NekosMoeAPI.fetch()
                            case .purr: _ = try await PurrAPI.fetch()
                            case .waifupics: _ = try await WaifuPicsAPI.fetch()
                            case .waifuIm: _ = try await WaifuImAPI.fetch()
                            case .random: break
                            }
                            let ms = Int((CFAbsoluteTimeGetCurrent() - t0) * 1000)
                            return (source.displayName, "\(ms)ms ✅")
                        } catch {
                            return (source.displayName, "❌")
                        }
                    }
                }
                
                for await (name, result) in group {
                    pingResults[name] = result
                }
            }
            isPinging = false
        }
    }
}

// MARK: - UIKit ViewController Bridge

public class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var refreshButton: UIButton?
    @IBOutlet weak var heartButton: UIButton?
    @IBOutlet weak var rewindButton: UIButton?
    @IBOutlet weak var safariButton: UIButton?
    @IBOutlet weak var sourceButton: UIButton?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let hostingController = UIHostingController(rootView: ModernContentView())
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
    
    @IBAction func safariButtonTapped(_ sender: UIButton) {}
    @IBAction func refreshButtonTapped(_ sender: UIButton) {}
    @IBAction func rewindButtonTapped(_ sender: UIButton) {}
    @IBAction func heartButtonTapped(_ sender: UIButton) {}
}
