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

/// Fournit l'URL du feed selon le canal choisi dans les réglages
/// (clé "updateChannel" : "stable" ou "dev"). Sparkle consulte le delegate
/// à chaque vérification : basculer de canal prend effet immédiatement.
/// Objet séparé : il est passé au controller à son init, sans capture de self.
private final class ChannelFeedProvider: NSObject, SPUUpdaterDelegate {
    nonisolated func feedURLString(for updater: SPUUpdater) -> String {
        let isDev = UserDefaults.standard.string(forKey: "updateChannel") == "dev"
        return isDev
            ? "https://raw.githubusercontent.com/mondary/PKmonitor/main/appcast-dev.xml"
            : "https://raw.githubusercontent.com/mondary/PKmonitor/main/appcast.xml"
    }
}

@MainActor
final class UpdaterManager: NSObject, ObservableObject {
    static let shared = UpdaterManager()

    static let stableFeedURL = "https://raw.githubusercontent.com/mondary/PKmonitor/main/appcast.xml"
    static let devFeedURL = "https://raw.githubusercontent.com/mondary/PKmonitor/main/appcast-dev.xml"

    private let controller: SPUStandardUpdaterController
    private var channelChangeObserver: NSObjectProtocol?

    @Published var canCheckForUpdates = false
    @Published private(set) var latestStableVersion: String?
    @Published private(set) var latestDevVersion: String?

    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }

    private override init() {
        // startingUpdater: false — start() est appelé explicitement au lancement.
        controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: ChannelFeedProvider(),
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
            Task { @MainActor in self?.applyChannelPreference() }
        }
        controller.startUpdater()
        #endif
    }

    /// Dernières versions publiées sur chaque canal, lues directement dans les
    /// appcasts (indépendant de Sparkle) pour affichage dans la page About.
    func refreshAvailableVersions() {
        Task {
            async let stable = Self.latestVersion(at: Self.stableFeedURL)
            async let dev = Self.latestVersion(at: Self.devFeedURL)
            let versions = await (stable, dev)
            latestStableVersion = versions.0
            latestDevVersion = versions.1
        }
    }

    private static func latestVersion(at address: String) async -> String? {
        guard let url = URL(string: address),
              let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200
        else { return nil }
        let parser = AppcastVersionParser()
        let xml = XMLParser(data: data)
        xml.delegate = parser
        guard xml.parse() else { return nil }
        return parser.version
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
private final class AppcastVersionParser: NSObject, XMLParserDelegate {
    private var insideShortVersion = false
    private var insideSparkleVersion = false
    private var currentText = ""
    private(set) var version: String?

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
            version = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            insideShortVersion = false
        } else if insideSparkleVersion && (elementName == "sparkle:version" || qName == "sparkle:version") {
            // Numéro de build : ne sert que si aucun shortVersionString n'a été vu.
            if version == nil { version = currentText.trimmingCharacters(in: .whitespacesAndNewlines) }
            insideSparkleVersion = false
        }
    }
}
