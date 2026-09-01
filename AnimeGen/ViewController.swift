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
    
    var displayName: String {
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
    
    var iconName: String {
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
    
    var description: String {
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
    
    var tag: String {
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
    @Published public var toastMessage: String? = nil
    
    @Published public var showSourceSheet: Bool = false
    @Published public var showHistorySheet: Bool = false
    @Published public var showFavoritesSheet: Bool = false
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    public init() {
        if let savedSource = UserDefaults.standard.string(forKey: "selectedSource"),
           let source = ImageSource(rawValue: savedSource) {
            self.selectedSource = source
        }
        loadNewImage()
    }
    
    public func setSource(_ source: ImageSource) {
        selectedSource = source
        UserDefaults.standard.set(source.rawValue, forKey: "selectedSource")
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
        impactFeedback.prepare()
        
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
                
                self.currentItem = item
                self.history.append(item)
                self.historyIndex = self.history.count - 1
                self.isLoading = false
                self.impactFeedback.impactOccurred()
            } catch {
                // Resilient automatic fallback
                do {
                    let fallbackItem = try await NekosBestAPI.fetch()
                    self.currentItem = fallbackItem
                    self.history.append(fallbackItem)
                    self.historyIndex = self.history.count - 1
                    self.isLoading = false
                    self.impactFeedback.impactOccurred()
                } catch {
                    self.isLoading = false
                    self.errorMessage = "Failed to load art. Tap to retry."
                    self.showToast("Connection issue. Please retry.")
                }
            }
        }
    }
    
    public func goPrevious() {
        guard historyIndex > 0 else {
            showToast("Beginning of history")
            return
        }
        historyIndex -= 1
        currentItem = history[historyIndex]
        impactFeedback.impactOccurred()
    }
    
    public func goNext() {
        if historyIndex < history.count - 1 {
            historyIndex += 1
            currentItem = history[historyIndex]
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
}

// MARK: - Modern SwiftUI UI

struct ModernContentView: View {
    @StateObject private var viewModel = AnimeGenViewModel()
    @State private var dragOffset: CGFloat = 0
    @State private var zoomScale: CGFloat = 1.0
    @State private var showHeartAnimation: Bool = false
    
    var body: some View {
        ZStack {
            // Ambient dynamic background blur
            ambientBackground
                .ignoresSafeArea()
            
            VStack(spacing: 14) {
                // Top Glass Header Bar
                topHeaderBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                // Center Interactive Canvas
                mainImageCanvas
                    .padding(.horizontal, 16)
                
                // Bottom Glass Floating Toolbar Capsule
                bottomToolbarCapsule
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            
            // Toast HUD
            if let toast = viewModel.toastMessage {
                toastView(text: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
            
            // Double-Tap Heart Overlay Animation
            if showHeartAnimation {
                Image(systemName: "heart.fill")
                    .font(.system(size: 84))
                    .foregroundColor(.red.opacity(0.85))
                    .scaleEffect(showHeartAnimation ? 1.2 : 0.4)
                    .opacity(showHeartAnimation ? 1 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: showHeartAnimation)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
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
                    viewModel.showFavoritesSheet = false
                }
            )
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
                    .opacity(0.35)
            }
            
            LinearGradient(
                colors: [Color.black.opacity(0.15), Color.clear, Color.black.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        HStack {
            // Source Selector Button
            Button(action: {
                viewModel.showSourceSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.selectedSource.iconName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.pink)
                    
                    Text(viewModel.selectedSource.displayName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            
            Spacer()
            
            // Favorites & History Pill Buttons
            HStack(spacing: 8) {
                Button(action: {
                    viewModel.showFavoritesSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                        if !viewModel.favorites.isEmpty {
                            Text("\(viewModel.favorites.count)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                
                Button(action: {
                    viewModel.showHistorySheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 13))
                            .foregroundColor(.accentColor)
                        if !viewModel.history.isEmpty {
                            Text("\(viewModel.history.count)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }
            }
        }
    }
    
    // MARK: - Main Image Canvas
    private var mainImageCanvas: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                
                if let item = viewModel.currentItem {
                    KFImage(item.imageURL)
                        .placeholder {
                            ProgressView()
                                .scaleEffect(1.3)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(20)
                        .padding(6)
                        .scaleEffect(zoomScale)
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.width
                                }
                                .onEnded { value in
                                    if value.translation.width < -60 {
                                        viewModel.goNext()
                                    } else if value.translation.width > 60 {
                                        viewModel.goPrevious()
                                    }
                                    withAnimation(.spring()) {
                                        dragOffset = 0
                                    }
                                }
                        )
                        .gesture(
                            MagnificationGesture()
                                .onChanged { scale in
                                    zoomScale = max(1.0, scale)
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
                    
                    // Metadata Badges (Top & Bottom of Card)
                    VStack {
                        HStack {
                            Text(item.category)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.ultraThinMaterial, in: Capsule())
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if item.isGIF {
                                Text("GIF")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.pink.opacity(0.85), in: Capsule())
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(14)
                        
                        Spacer()
                        
                        if let artist = item.artistName, !artist.isEmpty {
                            HStack {
                                Label(artist, systemImage: "paintpalette.fill")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(14)
                        }
                    }
                } else if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Summoning anime art...")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            viewModel.loadNewImage()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.pink)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    // MARK: - Bottom Floating Toolbar Capsule
    private var bottomToolbarCapsule: some View {
        HStack(spacing: 16) {
            // Previous Button
            Button(action: {
                viewModel.goPrevious()
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(viewModel.historyIndex > 0 ? .primary : .secondary.opacity(0.5))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .disabled(viewModel.historyIndex <= 0)
            
            // Favorite Button
            Button(action: {
                viewModel.toggleFavorite()
            }) {
                Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(viewModel.isFavorite ? .red : .primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            
            // Generate / Next Hero Button
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
                        .frame(width: 62, height: 62)
                        .shadow(color: Color.pink.opacity(0.4), radius: 10, x: 0, y: 5)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 24, weight: .bold))
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
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            
            // Share Sheet Button
            Button(action: {
                shareCurrentArt()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 15, x: 0, y: 8)
    }
    
    // MARK: - Toast HUD View
    private func toastView(text: String) -> some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.pink)
                Text(text)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            .padding(.top, 40)
            
            Spacer()
        }
    }
    
    private func shareCurrentArt() {
        guard let current = viewModel.currentItem else { return }
        let activityVC = UIActivityViewController(activityItems: [current.imageURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
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
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
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

