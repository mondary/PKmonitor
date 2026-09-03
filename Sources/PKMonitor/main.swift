import AppKit
import Darwin
import ServiceManagement
import SwiftUI

enum Metric: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case cpu = "CPU"
    case gpu = "GPU"
    case ram = "RAM"
    case network = "Network"

    var id: String { rawValue }
}

struct AppUsage: Identifiable, Equatable {
    let name: String
    let path: String
    let pid: Int32
    let cpu: Double
    let memory: Double
    var id: String { path }
}

struct Reading {
    var cpu = 0.0
    var ram = 0.0
    var network = 0.0
    var apps: [AppUsage] = []

    func value(for metric: Metric) -> Double {
        switch metric {
        case .auto, .cpu: cpu
        case .gpu: 0
        case .ram: ram
        case .network: network
        }
    }
}

final class SystemSampler {
    private var previousCPU: (idle: UInt64, total: UInt64)?
    private var previousBytes: UInt64?
    private var previousNetworkDate = Date()

    func sample(previousApps: [AppUsage]) -> Reading {
        Reading(cpu: cpuUsage(), ram: memoryUsage(), network: networkRate(), apps: previousApps)
    }

    private func cpuUsage() -> Double {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }

        let ticks = info.cpu_ticks
        let idle = UInt64(ticks.2)
        let total = UInt64(ticks.0) + UInt64(ticks.1) + UInt64(ticks.2) + UInt64(ticks.3)
        defer { previousCPU = (idle, total) }
        guard let previousCPU, total > previousCPU.total else { return 0 }
        let totalDelta = total - previousCPU.total
        return 100 * Double(totalDelta - (idle - previousCPU.idle)) / Double(totalDelta)
    }

    private func memoryUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        let usedPages = UInt64(stats.active_count) + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)
        let usedBytes = usedPages * UInt64(vm_kernel_page_size)
        return min(100, 100 * Double(usedBytes) / Double(ProcessInfo.processInfo.physicalMemory))
    }

    private func networkRate() -> Double {
        var first: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&first) == 0, let first else { return 0 }
        defer { freeifaddrs(first) }

        var total: UInt64 = 0
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let address = cursor {
            let item = address.pointee
            let flags = Int32(item.ifa_flags)
            if flags & IFF_UP != 0,
               flags & IFF_LOOPBACK == 0,
               item.ifa_addr?.pointee.sa_family == UInt8(AF_LINK),
               let data = item.ifa_data?.assumingMemoryBound(to: if_data.self).pointee {
                total += UInt64(data.ifi_ibytes) + UInt64(data.ifi_obytes)
            }
            cursor = item.ifa_next
        }

        let now = Date()
        let elapsed = now.timeIntervalSince(previousNetworkDate)
        defer {
            previousBytes = total
            previousNetworkDate = now
        }
        guard let previousBytes, total >= previousBytes, elapsed > 0 else { return 0 }
        return Double(total - previousBytes) / elapsed
    }
}

@MainActor
final class MonitorModel: ObservableObject {
    @Published private(set) var reading = Reading()
    @Published private(set) var displayedMetric: Metric = .cpu
    @Published private(set) var samples: [Double] = []
    @Published private(set) var markers: [String?] = []
    @Published var selectedMetric: Metric {
        didSet { UserDefaults.standard.set(selectedMetric.rawValue, forKey: "metric") }
    }

    private let sampler = SystemSampler()
    private var timer: Timer?
    private var tick = 0
    private var lastMarkerTick = -40

    init() {
        selectedMetric = Metric(rawValue: UserDefaults.standard.string(forKey: "metric") ?? "") ?? .auto
    }

    func start(onUpdate: @escaping () -> Void) {
        update(onUpdate: onUpdate)
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.update(onUpdate: onUpdate) }
        }
    }

    func select(_ metric: Metric) {
        selectedMetric = metric
        displayedMetric = metric == .auto ? automaticMetric() : metric
        samples.removeAll(keepingCapacity: true)
        markers.removeAll(keepingCapacity: true)
        lastMarkerTick = tick - 40
    }

    func format(_ metric: Metric? = nil) -> String {
        let metric = metric ?? displayedMetric
        switch metric {
        case .network: return Self.formatBytes(reading.network) + "/s"
        case .gpu: return "N/A"
        default: return "\(Int(reading.value(for: metric).rounded()))%"
        }
    }

    var displayedApps: [AppUsage] {
        let sorted: [AppUsage]
        switch displayedMetric {
        case .ram: sorted = reading.apps.sorted { $0.memory > $1.memory }
        default: sorted = reading.apps.sorted { $0.cpu > $1.cpu }
        }
        return Array(sorted.prefix(6))
    }

    func format(_ app: AppUsage) -> String {
        displayedMetric == .ram ? Self.formatBytes(app.memory) : String(format: "%.1f%%", app.cpu)
    }

    private func update(onUpdate: @escaping () -> Void) {
        tick += 1
        reading = sampler.sample(previousApps: reading.apps)
        displayedMetric = selectedMetric == .auto ? automaticMetric() : selectedMetric
        samples.append(normalizedValue())
        markers.append(markerForCurrentSample())
        if samples.count > 42 {
            samples.removeFirst(samples.count - 42)
            markers.removeFirst(markers.count - 42)
        }
        onUpdate()

        if tick % 20 == 1 {
            Task.detached {
                let apps = Self.topApps()
                await MainActor.run {
                    self.reading.apps = apps
                }
            }
        }
    }

    private func automaticMetric() -> Metric {
        if reading.network > 5_000_000 { return .network }
        if reading.ram > 85 { return .ram }
        return .cpu
    }

    private func normalizedValue() -> Double {
        switch displayedMetric {
        case .network: return min(1, log10(max(1, reading.network)) / 8)
        case .gpu: return 0
        default: return reading.value(for: displayedMetric) / 100
        }
    }

    private func markerForCurrentSample() -> String? {
        guard tick - lastMarkerTick >= 40,
              let app = displayedApps.first else { return nil }
        lastMarkerTick = tick
        return app.path
    }

    nonisolated static func topApps() -> [AppUsage] {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-Ao", "pid=,%cpu=,rss=,comm="]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard let text = String(data: data, encoding: .utf8) else { return [] }

        var totals: [String: (name: String, pid: Int32, hasMainPID: Bool, cpu: Double, memory: Double)] = [:]
        for line in text.split(separator: "\n") {
            let parts = line.split(maxSplits: 3, whereSeparator: \ .isWhitespace)
            guard parts.count == 4,
                  let pid = Int32(parts[0]),
                  let cpu = Double(parts[1]),
                  let memoryKB = Double(parts[2]) else { continue }
            let executablePath = String(parts[3])
            guard let path = appBundlePath(from: executablePath) else { continue }
            let name = Bundle(path: path)?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? Bundle(path: path)?.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? appName(from: path)
            guard name != "PKMonitor" else { continue }
            let isMainPID = executablePath.hasPrefix(path + "/Contents/MacOS/")
            let current = totals[path] ?? (name, pid, false, 0, 0)
            totals[path] = (
                name,
                isMainPID || !current.hasMainPID ? pid : current.pid,
                isMainPID || current.hasMainPID,
                current.cpu + cpu,
                current.memory + memoryKB * 1024
            )
        }
        return totals.map {
            AppUsage(name: $0.value.name, path: $0.key, pid: $0.value.pid, cpu: $0.value.cpu, memory: $0.value.memory)
        }
    }

    nonisolated static func appBundlePath(from executablePath: String) -> String? {
        guard let range = executablePath.range(of: ".app") else { return nil }
        return String(executablePath[...range.upperBound])
    }

    nonisolated static func appName(from path: String) -> String {
        path.split(separator: "/").first(where: { $0.hasSuffix(".app") })
            .map { String($0.dropLast(4)) }
            ?? URL(fileURLWithPath: path).lastPathComponent
    }

    nonisolated static func formatBytes(_ bytes: Double) -> String {
        if bytes >= 1_000_000 { return String(format: "%.1f MB", bytes / 1_000_000) }
        if bytes >= 1_000 { return String(format: "%.0f KB", bytes / 1_000) }
        return "\(Int(bytes)) B"
    }

    nonisolated static func scaledHistory(_ values: [Double]) -> [Double] {
        guard let low = values.min(), let high = values.max(), high - low > 0.000_001 else {
            return Array(repeating: 0.5, count: values.count)
        }
        return values.map { 0.12 + 0.76 * ($0 - low) / (high - low) }
    }
}

struct DetailView: View {
    @ObservedObject var model: MonitorModel
    let openActivityMonitor: (AppUsage) -> Void
    let terminateProcess: (AppUsage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(model.displayedMetric.rawValue).font(.headline)
                Spacer()
                Text(model.format()).font(.title2.monospacedDigit().weight(.semibold))
            }
            Divider()
            if model.displayedApps.isEmpty {
                Text("Collecting app activity…").foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(model.displayedApps) { app in
                        HStack(spacing: 9) {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                                .resizable().frame(width: 24, height: 24)
                            Text(app.name).font(.system(size: 15)).lineLimit(1)
                            Spacer()
                            Text(model.format(app))
                                .font(.system(size: 15)).foregroundStyle(.secondary).monospacedDigit()
                            Button { openActivityMonitor(app) } label: {
                                Image(systemName: "arrow.up.right.square")
                            }
                            .buttonStyle(.plain)
                            .help("Open Activity Monitor filtered on PID \(app.pid)")
                            Button { terminateProcess(app) } label: {
                                Image(systemName: "xmark.octagon")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.red)
                            .help("Quit \(app.name)")
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.separator.opacity(0.5), lineWidth: 0.5)
        }
    }

}

struct SparklineShape: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }
        for (index, value) in MonitorModel.scaledHistory(values).enumerated() {
            let point = CGPoint(
                x: rect.width * CGFloat(index) / CGFloat(values.count - 1),
                y: rect.height * (1 - CGFloat(max(0, min(1, value))))
            )
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        return path
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let model = MonitorModel()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var detailPanel: NSPanel?
    private var trackingArea: NSTrackingArea?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(statusClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageLeading
        button.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        button.toolTip = "PKMonitor — left-click for details, right-click for menu"
        button.setAccessibilityLabel("PKMonitor system activity")

        let tracking = NSTrackingArea(
            rect: button.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        )
        button.addTrackingArea(tracking)
        trackingArea = tracking
        setupDetailPanel()
        model.start { [weak self] in self?.refreshStatusItem() }
    }

    @objc private func statusClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            hideDetailPanel()
            let menu = makeMenu()
            menu.delegate = self
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
        } else {
            detailPanel?.isVisible == true ? hideDetailPanel() : showDetailPanel()
        }
    }

    @objc func mouseEntered(with event: NSEvent) {
        showDetailPanel()
    }

    @objc func mouseExited(with event: NSEvent) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self,
                  self.statusButtonFrame?.contains(NSEvent.mouseLocation) != true,
                  self.detailPanel?.frame.contains(NSEvent.mouseLocation) != true else { return }
            self.hideDetailPanel()
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }

    private func setupDetailPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 286),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.hidesOnDeactivate = false
        let hosting = NSHostingController(rootView: DetailView(
            model: model,
            openActivityMonitor: { [weak self] in self?.openActivityMonitor(for: $0) },
            terminateProcess: { [weak self] in self?.confirmTermination(of: $0) }
        ))
        hosting.view.wantsLayer = true
        hosting.view.layer?.cornerRadius = 16
        hosting.view.layer?.masksToBounds = true
        hosting.view.addTrackingArea(NSTrackingArea(
            rect: hosting.view.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        ))
        panel.contentViewController = hosting
        detailPanel = panel
    }

    private var statusButtonFrame: NSRect? {
        guard let button = statusItem.button, let window = button.window else { return nil }
        return window.convertToScreen(button.convert(button.bounds, to: nil))
    }

    private func showDetailPanel() {
        guard let panel = detailPanel, let buttonFrame = statusButtonFrame else { return }
        let screen = statusItem.button?.window?.screen ?? NSScreen.main
        let visible = screen?.visibleFrame ?? .zero
        let x = max(visible.minX + 8, min(buttonFrame.midX - panel.frame.width / 2, visible.maxX - panel.frame.width - 8))
        panel.setFrameOrigin(NSPoint(x: x, y: buttonFrame.minY - panel.frame.height - 6))
        panel.orderFrontRegardless()
    }

    private func hideDetailPanel() {
        detailPanel?.orderOut(nil)
    }

    private func refreshStatusItem() {
        guard let button = statusItem.button else { return }
        button.effectiveAppearance.performAsCurrentDrawingAppearance {
            button.image = sparklineImage(model.samples, markers: model.markers, metric: model.displayedMetric)
        }
        let prefix = model.selectedMetric == .auto ? "Auto · \(model.displayedMetric.rawValue)" : model.displayedMetric.rawValue
        button.title = " \(model.format())"
        button.setAccessibilityValue("\(prefix), \(model.format())")
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu(title: "PKMonitor")
        for metric in Metric.allCases {
            let item = NSMenuItem(title: metric.rawValue, action: #selector(selectMetric(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = metric.rawValue
            item.state = model.selectedMetric == metric ? .on : .off
            if metric != .auto { item.title += "    \(model.format(metric))" }
            menu.addItem(item)
        }
        menu.addItem(.separator())
        for app in model.displayedApps {
            let item = NSMenuItem(title: "\(app.name)    \(model.format(app))", action: #selector(openActivityMonitorFromMenu(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = Int(app.pid)
            item.image = NSWorkspace.shared.icon(forFile: app.path)
            item.image?.size = NSSize(width: 16, height: 16)
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin(_:)), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(NSMenuItem(title: "About PKMonitor", action: #selector(showAbout), keyEquivalent: ""))
        menu.items.last?.target = self
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit PKMonitor", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        return menu
    }

    @objc private func selectMetric(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let metric = Metric(rawValue: raw) else { return }
        model.select(metric)
        refreshStatusItem()
    }

    @objc private func openActivityMonitorFromMenu(_ sender: NSMenuItem) {
        guard let pid = sender.representedObject as? Int else { return }
        openActivityMonitor(pid: Int32(pid))
    }

    private func openActivityMonitor(for app: AppUsage) {
        openActivityMonitor(pid: app.pid)
    }

    private func openActivityMonitor(pid: Int32) {
        hideDetailPanel()
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let source = """
            tell application "Activity Monitor" to activate
            tell application "System Events"
                tell process "Activity Monitor"
                    keystroke "f" using command down
                    delay 0.1
                    keystroke "\(pid)"
                end tell
            end tell
            """
            var error: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&error)
            guard let error else { return }
            self.showError(
                title: "Activity Monitor could not be filtered",
                message: error[NSAppleScript.errorMessage] as? String ?? "Allow PKMonitor to control System Events in Privacy & Security > Automation."
            )
        }
    }

    private func confirmTermination(of app: AppUsage) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Quit \(app.name)?"
        alert.informativeText = "PKMonitor will ask process \(app.pid) to quit. Unsaved work may be lost."
        alert.addButton(withTitle: "Quit Process")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        guard Darwin.kill(app.pid, SIGTERM) == 0 else {
            showError(title: "Could not quit \(app.name)", message: String(cString: strerror(errno)))
            return
        }
        hideDetailPanel()
    }

    private func showError(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = message
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func toggleLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = "Launch at Login is unavailable"
            alert.informativeText = "Install PKMonitor as an application before enabling this option."
            alert.runModal()
        }
    }

    @objc private func showAbout() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development"
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "PKMonitor",
            .version: version,
            .credits: NSAttributedString(string: "Local CPU, memory and network activity in one line.")
        ])
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() { NSApp.terminate(nil) }

    private func sparklineImage(_ values: [Double], markers: [String?], metric: Metric) -> NSImage {
        let size = NSSize(width: 80, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }
        guard values.count > 1 else { return image }

        let rect = NSRect(origin: .zero, size: size)
        let graphWidth: CGFloat = 68
        let scaledValues = MonitorModel.scaledHistory(values)
        let path = NSBezierPath()
        for (index, value) in scaledValues.enumerated() {
            let point = NSPoint(
                x: graphWidth * CGFloat(42 - values.count + index) / 41,
                y: 2 + (rect.height - 4) * CGFloat(max(0, min(1, value)))
            )
            index == 0 ? path.move(to: point) : path.line(to: point)
        }
        NSColor.labelColor.setStroke()
        path.lineWidth = 1.6
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()

        for (index, marker) in markers.enumerated() {
            guard let marker else { continue }
            let x = graphWidth * CGFloat(42 - markers.count + index) / 41
            let y = 2 + (rect.height - 4) * CGFloat(max(0, min(1, scaledValues[index])))
            let iconRect = NSRect(x: x - 7.5, y: max(0, min(rect.height - 15, y - 7.5)), width: 15, height: 15)
            NSColor.windowBackgroundColor.setFill()
            NSBezierPath(roundedRect: iconRect, xRadius: 4, yRadius: 4).fill()
            NSColor.separatorColor.setStroke()
            NSBezierPath(roundedRect: iconRect, xRadius: 4, yRadius: 4).stroke()
            NSWorkspace.shared.icon(forFile: marker).draw(in: iconRect.insetBy(dx: 1, dy: 1))
        }

        let label = metric == .network ? "NET" : metric.rawValue.uppercased()
        let font = NSFont.systemFont(ofSize: 5.5, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.labelColor]
        for (index, character) in label.enumerated() {
            String(character).draw(at: NSPoint(x: 72, y: 12 - CGFloat(index) * 5.5), withAttributes: attributes)
        }
        image.isTemplate = false
        return image
    }
}

@main
struct PKMonitorApp {
    static func main() {
        if CommandLine.arguments.contains("--self-test") {
            assert(MonitorModel.formatBytes(999) == "999 B")
            assert(MonitorModel.formatBytes(1_500) == "2 KB")
            assert(MonitorModel.formatBytes(1_500_000) == "1.5 MB")
            assert(MonitorModel.appName(from: "/Applications/Safari.app/Contents/MacOS/Safari") == "Safari")
            assert(MonitorModel.appBundlePath(from: "/Applications/Safari.app/Contents/MacOS/Safari") == "/Applications/Safari.app")
            assert(MonitorModel.scaledHistory([0.7, 0.71]) == [0.12, 0.88])
            let apps = MonitorModel.topApps()
            assert(!apps.isEmpty)
            print("Self-test passed with \(apps.count) detected apps")
            return
        }
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
