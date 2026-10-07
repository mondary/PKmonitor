//
//  UpdaterManager.swift
//  PKMonitor
//
//  Cycle de vie des mises à jour Sparkle. ObservableObject (et non @Observable)
//  car Sparkle expose canCheckForUpdates en KVO, bridge via Combine.
//

import AppKit
import Combine
import Foundation
import Sparkle
import SwiftUI

/// Fournit l'URL du feed selon le canal choisi dans les réglages
/// (clé "updateChannel" : "stable" ou "dev"). Sparkle consulte le delegate
/// à chaque vérification : basculer de canal prend effet immédiatement.
/// Objet séparé : il est passé au controller à son init, sans capture de self.
private final class ChannelFeedProvider: NSObject, SPUUpdaterDelegate {
    nonisolated func feedURLString(for updater: SPUUpdater) -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        // Une build suffixée -dev suit toujours le feed Dev : sinon Sparkle
        // compare une build Dev plus récente à Stable et annonce un état trompeur.
        let isDevBuild = version.localizedCaseInsensitiveContains("-dev")
        let isDev = isDevBuild || UserDefaults.standard.string(forKey: "updateChannel") == "dev"
        let address = isDev
            ? "https://raw.githubusercontent.com/mondary/PKmonitor/main/appcast-dev.xml"
            : "https://raw.githubusercontent.com/mondary/PKmonitor/main/appcast.xml"
        guard var components = URLComponents(string: address) else { return address }
        components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "_pk_refresh", value: UUID().uuidString)]
        return components.url?.absoluteString ?? address
    }
}

@MainActor
final class UpdaterManager: NSObject, ObservableObject {
    static let shared = UpdaterManager()

    static let stableFeedURL = "https://raw.githubusercontent.com/mondary/PKmonitor/main/appcast.xml"
    static let devFeedURL = "https://raw.githubusercontent.com/mondary/PKmonitor/main/appcast-dev.xml"

    private let controller: SPUStandardUpdaterController
    // Sparkle garde son updaterDelegate faiblement : conserver le fournisseur,
    // sinon il est libéré après init et Sparkle retombe sur SUFeedURL (Stable).
    private let channelFeedProvider: ChannelFeedProvider
    private var channelChangeObserver: NSObjectProtocol?

    @Published var canCheckForUpdates = false
    @Published private(set) var latestStableVersion: String?
    @Published private(set) var latestDevVersion: String?
    @Published private(set) var availableUpdateVersion: String?
    private var latestStableBuild: String?
    private var latestDevBuild: String?

    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }

    private override init() {
        // startingUpdater: false — start() est appelé explicitement au lancement.
        let feedProvider = ChannelFeedProvider()
        channelFeedProvider = feedProvider
        controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: feedProvider,
            userDriverDelegate: nil
        )
        super.init()
        controller.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func start() {
        #if DEBUG
        return
        #else
        applyChannelPreference()
        channelChangeObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("PKUpdateChannelDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.applyChannelPreference(); self?.refreshAvailableVersions() }
        }
        controller.startUpdater()
        #endif
    }

    /// Dernières versions publiées sur chaque canal, lues directement dans les
    /// appcasts (indépendant de Sparkle) pour affichage dans la page About.
    func refreshAvailableVersions() {
        Task {
            async let stable = Self.latestInfo(at: Self.stableFeedURL)
            async let dev = Self.latestInfo(at: Self.devFeedURL)
            let feeds = await (stable, dev)
            latestStableVersion = feeds.0?.shortVersion
            latestStableBuild = feeds.0?.buildVersion
            latestDevVersion = feeds.1?.shortVersion
            latestDevBuild = feeds.1?.buildVersion
            refreshUpdateAvailability()
        }
    }

    private static func latestInfo(at address: String) async -> MonitorAppcastInfo? {
        guard var components = URLComponents(string: address) else { return nil }
        components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "_pk_refresh", value: UUID().uuidString)]
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.setValue("no-cache, no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200
        else { return nil }
        let parser = AppcastVersionParser()
        let xml = XMLParser(data: data)
        xml.delegate = parser
        guard xml.parse() else { return nil }
        return parser.info
    }

    func versionStatus(for channel: String) -> MonitorChannelVersionStatus {
        let installedVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let installedChannel = installedVersion.localizedCaseInsensitiveContains("-dev") ? "dev" : "stable"
        guard installedChannel == channel else { return .otherChannel }
        guard let publishedBuild = channel == "dev" ? latestDevBuild : latestStableBuild,
              let installedBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
              let order = compareBuildNumbers(publishedBuild, installedBuild) else { return .unavailable }
        switch order {
        case .orderedDescending: return .updateAvailable
        case .orderedSame: return .upToDate
        case .orderedAscending: return .installedAhead
        }
    }

    private func refreshUpdateAvailability() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let isDevBuild = version.localizedCaseInsensitiveContains("-dev")
        let channel = isDevBuild ? "dev" : UserDefaults.standard.string(forKey: "updateChannel") ?? "stable"
        let latestBuild = channel == "dev" ? latestDevBuild : latestStableBuild
        let installedBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        availableUpdateVersion = if let latestBuild, let installedBuild,
                                    compareBuildNumbers(latestBuild, installedBuild) == .orderedDescending {
            channel == "dev" ? latestDevVersion : latestStableVersion
        } else {
            nil
        }
    }

    /// Canal dev : installation silencieuse (SUAutomaticallyUpdate).
    /// Le choix du feed lui-même est fait par ChannelFeedProvider (delegate).
    private func applyChannelPreference() {
        let isDev = UserDefaults.standard.string(forKey: "updateChannel") == "dev"
        controller.updater.automaticallyDownloadsUpdates = isDev
    }

    /// App menu-bar pure : bascule temporairement en .regular pour que la
    /// fenêtre de mise à jour Sparkle puisse apparaître au premier plan.
    func checkForUpdates() {
        #if DEBUG
        return
        #else
        refreshAvailableVersions()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        controller.checkForUpdates(nil)
        #endif
    }
}

/// Lit la dernière version (`sparkle:shortVersionString`, à défaut
/// `sparkle:version`) d'un appcast — adapté du pattern PKwindowsManagement :
/// contrairement au sien, l'appcast stable de PKmonitor liste les items du
/// plus ancien au plus récent, c'est donc la DERNIÈRE version qui gagne.
enum MonitorChannelVersionStatus {
    case updateAvailable, upToDate, installedAhead, otherChannel, unavailable

    var symbol: String {
        switch self {
        case .updateAvailable: "arrow.down.circle.fill"
        case .upToDate: "checkmark.circle.fill"
        case .installedAhead: "arrow.up.circle.fill"
        case .otherChannel: "circle.dashed"
        case .unavailable: "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .updateAvailable: .accentColor
        case .upToDate: .green
        case .installedAhead: .orange
        case .otherChannel, .unavailable: .secondary
        }
    }

    var localizationKey: String {
        switch self {
        case .updateAvailable: "about.statusUpdateAvailable"
        case .upToDate: "about.statusUpToDate"
        case .installedAhead: "about.statusInstalledAhead"
        case .otherChannel: "about.statusOtherChannel"
        case .unavailable: "about.statusUnavailable"
        }
    }
}

private struct MonitorAppcastInfo {
    let shortVersion: String
    let buildVersion: String
}

private func compareBuildNumbers(_ lhs: String, _ rhs: String) -> ComparisonResult? {
    func components(_ value: String) -> [UInt64]? {
        let parts = value.split(separator: ".")
        guard !parts.isEmpty else { return nil }
        let numbers = parts.compactMap { UInt64($0) }
        return numbers.count == parts.count ? numbers : nil
    }
    guard let left = components(lhs), let right = components(rhs) else { return nil }
    for index in 0..<max(left.count, right.count) {
        let a = index < left.count ? left[index] : 0
        let b = index < right.count ? right[index] : 0
        if a != b { return a < b ? .orderedAscending : .orderedDescending }
    }
    return .orderedSame
}

private final class AppcastVersionParser: NSObject, XMLParserDelegate {
    private var insideShortVersion = false
    private var insideSparkleVersion = false
    private var currentText = ""
    private var shortVersion: String?
    private var buildVersion: String?
    var info: MonitorAppcastInfo? {
        guard let shortVersion, let build = buildVersion else { return nil }
        return MonitorAppcastInfo(shortVersion: shortVersion, buildVersion: build)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "sparkle:shortVersionString" || qName == "sparkle:shortVersionString" {
            insideShortVersion = true
            currentText = ""
        } else if elementName == "sparkle:version" || qName == "sparkle:version" {
            insideSparkleVersion = true
            currentText = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideShortVersion || insideSparkleVersion { currentText += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if insideShortVersion && (elementName == "sparkle:shortVersionString" || qName == "sparkle:shortVersionString") {
            shortVersion = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            insideShortVersion = false
        } else if insideSparkleVersion && (elementName == "sparkle:version" || qName == "sparkle:version") {
            buildVersion = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            insideSparkleVersion = false
        }
    }
}
