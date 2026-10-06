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

    private let controller: SPUStandardUpdaterController
    private var channelChangeObserver: NSObjectProtocol?

    @Published var canCheckForUpdates = false

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
