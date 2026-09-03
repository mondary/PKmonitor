import AppKit
import Darwin
import IOKit
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

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum ValuePosition: String, CaseIterable, Identifiable {
    case left = "Left"
    case right = "Right"

    var id: String { rawValue }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var updateInterval: Double { didSet { defaults.set(updateInterval, forKey: "updateInterval") } }
    @Published var historySeconds: Double { didSet { defaults.set(historySeconds, forKey: "historySeconds") } }
    @Published var iconCount: Int { didSet { defaults.set(iconCount, forKey: "iconCount") } }
    @Published var showOnHover: Bool { didSet { defaults.set(showOnHover, forKey: "showOnHover") } }
    @Published var sparklineWidth: Double { didSet { defaults.set(sparklineWidth, forKey: "sparklineWidth") } }
    @Published var iconSize: Double { didSet { defaults.set(iconSize, forKey: "iconSize") } }
    @Published var lineWidth: Double { didSet { defaults.set(lineWidth, forKey: "lineWidth") } }
    @Published var appearance: AppearanceMode { didSet { defaults.set(appearance.rawValue, forKey: "appearance") } }
    @Published var valuePosition: ValuePosition { didSet { defaults.set(valuePosition.rawValue, forKey: "valuePosition") } }
    @Published var showGauges: Bool { didSet { defaults.set(showGauges, forKey: "showGauges") } }
    @Published var gaugePosition: ValuePosition { didSet { defaults.set(gaugePosition.rawValue, forKey: "gaugePosition") } }
    @Published var showGaugeLabels: Bool { didSet { defaults.set(showGaugeLabels, forKey: "showGaugeLabels") } }
    @Published var labelPosition: ValuePosition { didSet { defaults.set(labelPosition.rawValue, forKey: "labelPosition") } }
    @Published var showLabel: Bool { didSet { defaults.set(showLabel, forKey: "showLabel") } }
    @Published var showIconBorder: Bool { didSet { defaults.set(showIconBorder, forKey: "showIconBorder") } }
    @Published var warningThreshold: Double { didSet { defaults.set(warningThreshold, forKey: "warningThreshold") } }
    @Published var criticalThreshold: Double { didSet { defaults.set(criticalThreshold, forKey: "criticalThreshold") } }
    @Published private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled

    private let defaults = UserDefaults.standard

    init() {
        updateInterval = defaults.object(forKey: "updateInterval") as? Double ?? 0.2
        historySeconds = defaults.object(forKey: "historySeconds") as? Double ?? 8
        iconCount = defaults.object(forKey: "iconCount") as? Int ?? 5
        showOnHover = defaults.object(forKey: "showOnHover") as? Bool ?? true
        sparklineWidth = defaults.object(forKey: "sparklineWidth") as? Double ?? 80
        iconSize = defaults.object(forKey: "iconSize") as? Double ?? 15
        lineWidth = defaults.object(forKey: "lineWidth") as? Double ?? 1.6
        appearance = AppearanceMode(rawValue: defaults.string(forKey: "appearance") ?? "") ?? .system
        valuePosition = ValuePosition(rawValue: defaults.string(forKey: "valuePosition") ?? "") ?? .left
        showGauges = defaults.object(forKey: "showGauges") as? Bool ?? true
        gaugePosition = ValuePosition(rawValue: defaults.string(forKey: "gaugePosition") ?? "") ?? .right
        showGaugeLabels = defaults.object(forKey: "showGaugeLabels") as? Bool ?? true
        labelPosition = ValuePosition(rawValue: defaults.string(forKey: "labelPosition") ?? "") ?? .right
        showLabel = defaults.object(forKey: "showLabel") as? Bool ?? true
        showIconBorder = defaults.object(forKey: "showIconBorder") as? Bool ?? true
        warningThreshold = defaults.object(forKey: "warningThreshold") as? Double ?? 80
        criticalThreshold = defaults.object(forKey: "criticalThreshold") as? Double ?? 95
    }

    func setLaunchAtLogin(_ enabled: Bool) throws {
        if enabled { try SMAppService.mainApp.register() }
        else { try SMAppService.mainApp.unregister() }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func restoreDefaults() {
        updateInterval = 0.2
        historySeconds = 8
        iconCount = 5
        showOnHover = true
        sparklineWidth = 80
        iconSize = 15
        lineWidth = 1.6
        appearance = .system
        valuePosition = .left
        showGauges = true
        gaugePosition = .right
        showGaugeLabels = true
        labelPosition = .right
        showLabel = true
        showIconBorder = true
        warningThreshold = 80
        criticalThreshold = 95
    }

    func colorForValue(_ value: Double) -> NSColor {
        if value >= criticalThreshold { return .systemRed }
        if value >= warningThreshold { return .systemOrange }
        return .labelColor
    }
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
    var gpu = 0.0
    var network = 0.0
    var download = 0.0
    var upload = 0.0
    var apps: [AppUsage] = []

    func value(for metric: Metric) -> Double {
        switch metric {
        case .auto, .cpu: cpu
        case .gpu: gpu
        case .ram: ram
        case .network: network
        }
    }
}

final class SystemSampler {
    private var previousCPU: (idle: UInt64, total: UInt64)?
    private var previousBytes: UInt64?
    private var previousInBytes: UInt64?
    private var previousOutBytes: UInt64?
    private var previousNetworkDate = Date()

    func sample(previousApps: [AppUsage]) -> Reading {
        let net = networkRate()
        return Reading(cpu: cpuUsage(), ram: memoryUsage(), gpu: gpuUsage(), network: net.total, download: net.download, upload: net.upload, apps: previousApps)
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

    private func networkRate() -> (total: Double, download: Double, upload: Double) {
        var first: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&first) == 0, let first else { return (0, 0, 0) }
        defer { freeifaddrs(first) }

        var inBytes: UInt64 = 0
        var outBytes: UInt64 = 0
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let address = cursor {
            let item = address.pointee
            let flags = Int32(item.ifa_flags)
            if flags & IFF_UP != 0,
               flags & IFF_LOOPBACK == 0,
               item.ifa_addr?.pointee.sa_family == UInt8(AF_LINK),
               let data = item.ifa_data?.assumingMemoryBound(to: if_data.self).pointee {
                inBytes += UInt64(data.ifi_ibytes)
                outBytes += UInt64(data.ifi_obytes)
            }
            cursor = item.ifa_next
        }

        let now = Date()
        let elapsed = now.timeIntervalSince(previousNetworkDate)
        defer {
            previousInBytes = inBytes
            previousOutBytes = outBytes
            previousNetworkDate = now
        }
        guard let prevIn = previousInBytes, let prevOut = previousOutBytes, elapsed > 0 else { return (0, 0, 0) }
        let dl = inBytes >= prevIn ? Double(inBytes - prevIn) / elapsed : 0
        let ul = outBytes >= prevOut ? Double(outBytes - prevOut) / elapsed : 0
        return (dl + ul, dl, ul)
    }

    private func gpuUsage() -> Double {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOAccelerator")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { return 0 }
        defer { IOObjectRelease(iterator) }

        var total: Double = 0
        var count = 0
        var entry = IOIteratorNext(iterator)
        while entry != 0 {
            defer { IOObjectRelease(entry) }
            if let props = IORegistryEntrySearchCFProperty(entry, "IOService", "PerformanceStatistics" as CFString, kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)) as? [String: Any] {
                if let util = props["Device Utilization %"] as? Double {
                    total += util
                    count += 1
                } else if let util = props["GPU Core Utilization"] as? Double {
                    total += util
                    count += 1
                }
            }
            entry = IOIteratorNext(iterator)
        }
        return count > 0 ? total / Double(count) : 0
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

    let settings: AppSettings
    private let sampler = SystemSampler()
    private var timer: Timer?
    private var lastSampleDate = Date.distantPast
    private var lastAppsDate = Date.distantPast

    init(settings: AppSettings) {
        self.settings = settings
        selectedMetric = Metric(rawValue: UserDefaults.standard.string(forKey: "metric") ?? "") ?? .auto
    }

    func start(onUpdate: @escaping () -> Void) {
        update(onUpdate: onUpdate)
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, Date().timeIntervalSince(self.lastSampleDate) >= self.settings.updateInterval else { return }
                self.update(onUpdate: onUpdate)
            }
        }
    }

    func select(_ metric: Metric) {
        selectedMetric = metric
        displayedMetric = metric == .auto ? automaticMetric() : metric
        samples.removeAll(keepingCapacity: true)
        markers.removeAll(keepingCapacity: true)
    }

    func format(_ metric: Metric? = nil) -> String {
        let metric = metric ?? displayedMetric
        switch metric {
        case .network: return Self.formatBytes(reading.network) + "/s"
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
        let now = Date()
        lastSampleDate = now
        reading = sampler.sample(previousApps: reading.apps)
        displayedMetric = selectedMetric == .auto ? automaticMetric() : selectedMetric
        let allowedMarkers = Set(displayedApps.prefix(settings.iconCount).map(\.path))
        markers = markers.map { marker in marker.flatMap { allowedMarkers.contains($0) ? $0 : nil } }
        samples.append(normalizedValue())
        markers.append(markerForCurrentSample())
        let historyLimit = max(2, Int(settings.historySeconds / settings.updateInterval))
        if samples.count > historyLimit {
            samples.removeFirst(samples.count - historyLimit)
            markers.removeFirst(markers.count - historyLimit)
        }
        onUpdate()

        if now.timeIntervalSince(lastAppsDate) >= 4 {
            lastAppsDate = now
            Task.detached {
                let apps = Self.topApps()
                await MainActor.run {
                    self.reading.apps = apps
                }
            }
        }
    }

    private func automaticMetric() -> Metric {
        if reading.gpu > 80 { return .gpu }
        if reading.network > 5_000_000 { return .network }
        if reading.ram > 85 { return .ram }
        return .cpu
    }

    private func normalizedValue() -> Double {
        switch displayedMetric {
        case .network: return min(1, log10(max(1, reading.network)) / 8)
        default: return reading.value(for: displayedMetric) / 100
        }
    }

    private func markerForCurrentSample() -> String? {
        let apps = Array(displayedApps.prefix(settings.iconCount))
        let activePaths = Set(markers.compactMap { $0 })
        return apps.first(where: { !activePaths.contains($0.path) })?.path
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
    @ObservedObject var settings: AppSettings
    let openActivityMonitor: (AppUsage) -> Void
    let terminateProcess: (AppUsage) -> Void
    let forceKillProcess: (AppUsage) -> Void

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
                            Button { forceKillProcess(app) } label: {
                                Image(systemName: "skull")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.red)
                            .help("Force kill \(app.name) (SIGKILL)")
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
        .preferredColorScheme(settings.appearance.colorScheme)
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

enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case appearance = "Appearance"
    case about = "About"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintbrush"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var selection: SettingsSection? = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.icon).tag(section)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190)
        } detail: {
            switch selection ?? .general {
            case .general: GeneralSettingsView(settings: settings)
            case .appearance: AppearanceSettingsView(settings: settings)
            case .about: AboutSettingsView()
            }
        }
        .frame(minWidth: 680, minHeight: 440)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Monitoring") {
                Picker("Refresh rate", selection: $settings.updateInterval) {
                    Text("100 ms").tag(0.1)
                    Text("200 ms").tag(0.2)
                    Text("500 ms").tag(0.5)
                    Text("1 second").tag(1.0)
                }
                Picker("History", selection: $settings.historySeconds) {
                    Text("5 seconds").tag(5.0)
                    Text("8 seconds").tag(8.0)
                    Text("15 seconds").tag(15.0)
                    Text("30 seconds").tag(30.0)
                }
                Stepper("Application icons: \(settings.iconCount)", value: $settings.iconCount, in: 1...5)
                Toggle("Show details on hover", isOn: $settings.showOnHover)
            }

            Section("Color Thresholds") {
                LabeledContent("Warning") {
                    HStack {
                        Slider(value: $settings.warningThreshold, in: 50...100, step: 5).frame(width: 160)
                        Text("\(Int(settings.warningThreshold))%").monospacedDigit().frame(width: 40)
                        Circle().fill(.orange).frame(width: 10, height: 10)
                    }
                }
                LabeledContent("Critical") {
                    HStack {
                        Slider(value: $settings.criticalThreshold, in: 50...100, step: 5).frame(width: 160)
                        Text("\(Int(settings.criticalThreshold))%").monospacedDigit().frame(width: 40)
                        Circle().fill(.red).frame(width: 10, height: 10)
                    }
                }
            }

            Section("System") {
                Toggle("Launch at login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { enabled in
                        do { try settings.setLaunchAtLogin(enabled) }
                        catch { errorMessage = error.localizedDescription }
                    }
                ))
            }

            Section {
                Button("Restore Defaults") { settings.restoreDefaults() }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
        .alert("Setting could not be changed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
}

struct AppearanceSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Menu Bar") {
                LabeledContent("Sparkline width") {
                    HStack {
                        Slider(value: $settings.sparklineWidth, in: 56...120, step: 4).frame(width: 180)
                        Text("\(Int(settings.sparklineWidth)) pt").monospacedDigit().frame(width: 48)
                    }
                }
                LabeledContent("Line width") {
                    HStack {
                        Slider(value: $settings.lineWidth, in: 1...3, step: 0.2).frame(width: 180)
                        Text("\(settings.lineWidth, specifier: "%.1f") pt").monospacedDigit().frame(width: 48)
                    }
                }
                LabeledContent("Icon size") {
                    HStack {
                        Slider(value: $settings.iconSize, in: 10...18, step: 1).frame(width: 180)
                        Text("\(Int(settings.iconSize)) pt").monospacedDigit().frame(width: 48)
                    }
                }
                Toggle("Icon border", isOn: $settings.showIconBorder)
                Picker("Value position", selection: $settings.valuePosition) {
                    ForEach(ValuePosition.allCases) { pos in Text(pos.rawValue).tag(pos) }
                }
                Toggle("Show metric label", isOn: $settings.showLabel)
                Picker("Label position", selection: $settings.labelPosition) {
                    ForEach(ValuePosition.allCases) { pos in Text(pos.rawValue).tag(pos) }
                }
                Toggle("Show metric gauges", isOn: $settings.showGauges)
                Picker("Gauge position", selection: $settings.gaugePosition) {
                    ForEach(ValuePosition.allCases) { pos in Text(pos.rawValue).tag(pos) }
                }
                Toggle("Show gauge labels", isOn: $settings.showGaugeLabels)
            }

            Section("Details Panel") {
                Picker("Appearance", selection: $settings.appearance) {
                    ForEach(AppearanceMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Appearance")
    }
}

struct AboutSettingsView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development"
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 54, weight: .medium))
            Text("PKMonitor").font(.title.bold())
            Text("Version \(version)").foregroundStyle(.secondary)
            Text("Local CPU, memory and network activity in one line.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("Requires macOS 13 or later").font(.caption).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("About")
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let settings: AppSettings
    private let model: MonitorModel
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var detailPanel: NSPanel?
    private var settingsWindow: NSWindow?
    private var hoverTimer: Timer?
    private var lastPointerInside = Date.distantPast
    private var panelPinned = false
    private var hoverSuppressed = false

    override init() {
        let settings = AppSettings()
        self.settings = settings
        model = MonitorModel(settings: settings)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(statusClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageLeading
        button.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        button.toolTip = "PKMonitor — hover for details, right-click for menu"
        button.setAccessibilityLabel("PKMonitor system activity")

        setupDetailPanel()
        let hoverTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateHoverState() }
        }
        RunLoop.main.add(hoverTimer, forMode: .common)
        self.hoverTimer = hoverTimer
        model.start { [weak self] in self?.refreshStatusItem() }
    }

    @objc private func statusClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            panelPinned = false
            hoverSuppressed = true
            hideDetailPanel()
            let menu = makeMenu()
            menu.delegate = self
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
        } else {
            if let button = statusItem.button, let event = NSApp.currentEvent {
                let localPoint = button.convert(event.locationInWindow, from: nil)
                let imagePoint = NSPoint(x: localPoint.x, y: button.bounds.height - localPoint.y)
                if let tappedMetric = metricForClick(at: imagePoint) {
                    model.select(tappedMetric)
                    refreshStatusItem()
                    return
                }
            }
            panelPinned.toggle()
            panelPinned ? showDetailPanel() : hideDetailPanel()
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
            settings: settings,
            openActivityMonitor: { [weak self] in self?.openActivityMonitor(for: $0) },
            terminateProcess: { [weak self] in self?.confirmTermination(of: $0) },
            forceKillProcess: { [weak self] in self?.confirmForceKill(of: $0) }
        ))
        hosting.view.wantsLayer = true
        hosting.view.layer?.cornerRadius = 16
        hosting.view.layer?.masksToBounds = true
        panel.contentViewController = hosting
        detailPanel = panel
    }

    private func updateHoverState() {
        guard settings.showOnHover else {
            if !panelPinned, detailPanel?.isVisible == true { hideDetailPanel() }
            return
        }
        let location = NSEvent.mouseLocation
        let overButton = statusButtonFrame?.contains(location) == true
        let overPanel = detailPanel?.isVisible == true && detailPanel?.frame.contains(location) == true
        if !overButton { hoverSuppressed = false }
        if hoverSuppressed { return }
        if overButton || overPanel {
            lastPointerInside = Date()
            if overButton, detailPanel?.isVisible != true { showDetailPanel() }
        } else if !panelPinned, detailPanel?.isVisible == true, Date().timeIntervalSince(lastPointerInside) > 0.3 {
            hideDetailPanel()
        }
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
        switch settings.appearance {
        case .system: detailPanel?.appearance = nil
        case .light: detailPanel?.appearance = NSAppearance(named: .aqua)
        case .dark: detailPanel?.appearance = NSAppearance(named: .darkAqua)
        }
        button.effectiveAppearance.performAsCurrentDrawingAppearance {
            button.image = sparklineImage(model.samples, markers: model.markers, metric: model.displayedMetric, value: model.format())
        }
        let prefix = model.selectedMetric == .auto ? "Auto · \(model.displayedMetric.rawValue)" : model.displayedMetric.rawValue
        button.title = ""
        button.setAccessibilityValue("\(prefix), \(model.format())")
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu(title: "PKMonitor")
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
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
        login.state = settings.launchAtLogin ? .on : .off
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
        panelPinned = false
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
        panelPinned = false
        hideDetailPanel()
    }

    private func confirmForceKill(of app: AppUsage) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Force kill \(app.name)?"
        alert.informativeText = "PKMonitor will send SIGKILL to process \(app.pid). This cannot be undone and will not save any work."
        alert.addButton(withTitle: "Force Kill")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        guard Darwin.kill(app.pid, SIGKILL) == 0 else {
            showError(title: "Could not force kill \(app.name)", message: String(cString: strerror(errno)))
            return
        }
        panelPinned = false
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
            try settings.setLaunchAtLogin(!settings.launchAtLogin)
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = "Launch at Login is unavailable"
            alert.informativeText = "Install PKMonitor as an application before enabling this option."
            alert.runModal()
        }
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let controller = NSHostingController(rootView: SettingsView(settings: settings))
            let window = NSWindow(contentViewController: controller)
            window.title = "PKMonitor Settings"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 680, height: 440))
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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

    private var gaugeRects: [Metric: NSRect] = [:]

    func metricForClick(at point: NSPoint) -> Metric? {
        guard settings.showGauges else { return nil }
        for (metric, rect) in gaugeRects {
            if rect.contains(point) { return metric }
        }
        return nil
    }

    private func sparklineImage(_ values: [Double], markers: [String?], metric: Metric, value: String) -> NSImage {
        let textW: CGFloat = 58
        let labelW: CGFloat = settings.showLabel ? 24 : 0
        let gaugeW: CGFloat = settings.showGauges ? 74 : 0
        let graphW = settings.sparklineWidth
        let totalWidth = textW + labelW + graphW + gaugeW
        let size = NSSize(width: totalWidth, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        let valueFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        let valueColor = settings.colorForValue(model.reading.value(for: metric))
        let valueAttrs: [NSAttributedString.Key: Any] = [.font: valueFont, .foregroundColor: valueColor]
        let valueSize = (value as NSString).size(withAttributes: valueAttrs)
        let label = metric == .network ? "NET" : metric.rawValue.uppercased()
        let labelFont = NSFont.systemFont(ofSize: 8, weight: .heavy)
        let labelAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: NSColor.labelColor]
        let labelCharSize = ("M" as NSString).size(withAttributes: labelAttrs)
        let lineH: CGFloat = 7

        let gaugesOnLeft = settings.gaugePosition == .left
        let valueOnLeft = settings.valuePosition == .left
        let labelOnLeft = settings.labelPosition == .left

        var cursor: CGFloat = 0
        var gaugeStartX: CGFloat = 0
        var valueX: CGFloat = 0
        var labelStartX: CGFloat = 0
        var graphStartX: CGFloat = 0

        if gaugesOnLeft { gaugeStartX = cursor; cursor += gaugeW }
        if valueOnLeft { valueX = cursor; cursor += textW }
        if labelOnLeft { labelStartX = cursor; cursor += labelW }
        graphStartX = cursor; cursor += graphW
        if !labelOnLeft { labelStartX = cursor; cursor += labelW }
        if !valueOnLeft { valueX = cursor; cursor += textW }
        if !gaugesOnLeft { gaugeStartX = cursor; cursor += gaugeW }

        if valueOnLeft {
            (value as NSString).draw(at: NSPoint(x: valueX + textW - valueSize.width - 4, y: (size.height - valueSize.height) / 2), withAttributes: valueAttrs)
        } else {
            (value as NSString).draw(at: NSPoint(x: valueX + 4, y: (size.height - valueSize.height) / 2), withAttributes: valueAttrs)
        }

        if settings.showLabel {
            for (index, character) in label.enumerated() {
                let lx = labelOnLeft ? labelStartX + 2 : labelStartX + 2
                String(character).draw(at: NSPoint(x: lx, y: size.height - labelCharSize.height - CGFloat(index) * lineH), withAttributes: labelAttrs)
            }
        }

        guard values.count > 1 else { return image }

        let rect = NSRect(origin: .zero, size: size)
        let sparkMargin: CGFloat = 4
        let drawGraphW = graphW - sparkMargin * 2
        let capacity = max(2, Int(settings.historySeconds / settings.updateInterval))
        let scaledValues = MonitorModel.scaledHistory(values)
        let path = NSBezierPath()
        for (index, val) in scaledValues.enumerated() {
            let point = NSPoint(
                x: graphStartX + sparkMargin + drawGraphW * CGFloat(capacity - values.count + index) / CGFloat(capacity - 1),
                y: 2 + (rect.height - 4) * CGFloat(max(0, min(1, val)))
            )
            index == 0 ? path.move(to: point) : path.line(to: point)
        }
        NSColor.labelColor.setStroke()
        path.lineWidth = settings.lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()

        for (index, marker) in markers.enumerated() {
            guard let marker else { continue }
            let x = graphStartX + sparkMargin + drawGraphW * CGFloat(capacity - markers.count + index) / CGFloat(capacity - 1)
            let y = 2 + (rect.height - 4) * CGFloat(max(0, min(1, scaledValues[index])))
            let iconSz = settings.iconSize
            let iconRect = NSRect(
                x: x - iconSz / 2,
                y: max(0, min(rect.height - iconSz, y - iconSz / 2)),
                width: iconSz,
                height: iconSz
            )
            NSColor.windowBackgroundColor.setFill()
            NSBezierPath(roundedRect: iconRect, xRadius: 4, yRadius: 4).fill()
            if settings.showIconBorder {
                NSColor.separatorColor.setStroke()
                NSBezierPath(roundedRect: iconRect, xRadius: 4, yRadius: 4).stroke()
            }
            NSWorkspace.shared.icon(forFile: marker).draw(in: iconRect.insetBy(dx: 1, dy: 1))
        }

        if settings.showGauges {
            let gaugeMetrics: [Metric] = [.gpu, .cpu, .ram, .network]
            let gW: CGFloat = 16
            let gGap: CGFloat = 2
            let gFont = NSFont.monospacedDigitSystemFont(ofSize: 6, weight: .heavy)
            let gAttrs: [NSAttributedString.Key: Any] = [.font: gFont, .foregroundColor: NSColor.secondaryLabelColor]
            let gActiveAttrs: [NSAttributedString.Key: Any] = [.font: gFont, .foregroundColor: NSColor.labelColor]
            var newGaugeRects: [Metric: NSRect] = [:]

            for (i, m) in gaugeMetrics.enumerated() {
                let gx = gaugeStartX + 2 + CGFloat(i) * (gW + gGap)
                let gRect = NSRect(x: gx, y: 1, width: gW, height: size.height - 2)
                newGaugeRects[m] = gRect

                let isActive = m == metric
                let bg = gRect.insetBy(dx: 1, dy: 1)

                NSColor.separatorColor.setFill()
                NSBezierPath(roundedRect: bg, xRadius: 2, yRadius: 2).fill()

                if m == .network {
                    let maxNet: CGFloat = 10_000_000
                    let dlFill = CGFloat(max(0, min(1, model.reading.download / maxNet)))
                    let ulFill = CGFloat(max(0, min(1, model.reading.upload / maxNet)))
                    let halfH = bg.height / 2
                    let midY = bg.minY + halfH

                    let dlH = halfH * dlFill
                    let dlR = NSRect(x: bg.minX, y: midY, width: bg.width, height: dlH)
                    let ulH = halfH * ulFill
                    let ulR = NSRect(x: bg.minX, y: bg.minY, width: bg.width, height: ulH)

                    let netColor = settings.colorForValue(model.reading.network / 100_000)
                    (isActive ? netColor : NSColor.tertiaryLabelColor).setFill()
                    NSBezierPath(roundedRect: dlR, xRadius: 2, yRadius: 2).fill()
                    (isActive ? NSColor.systemTeal : NSColor.tertiaryLabelColor).setFill()
                    NSBezierPath(roundedRect: ulR, xRadius: 2, yRadius: 2).fill()

                    if isActive {
                        netColor.setStroke()
                        NSBezierPath(roundedRect: bg, xRadius: 2, yRadius: 2).stroke()
                    }
                } else {
                    let fill = CGFloat(max(0, min(1, model.reading.value(for: m) / 100)))
                    let fillH = bg.height * fill
                    let fillR = NSRect(x: bg.minX, y: bg.minY, width: bg.width, height: fillH)
                    let gColor = settings.colorForValue(model.reading.value(for: m))
                    (isActive ? gColor : NSColor.tertiaryLabelColor).setFill()
                    NSBezierPath(roundedRect: fillR, xRadius: 2, yRadius: 2).fill()

                    if isActive {
                        gColor.setStroke()
                        NSBezierPath(roundedRect: bg, xRadius: 2, yRadius: 2).stroke()
                    }
                }

                if settings.showGaugeLabels {
                    let tag = m == .network ? "NET" : m.rawValue
                    let tagSize = (tag as NSString).size(withAttributes: isActive ? gActiveAttrs : gAttrs)
                    (tag as NSString).draw(at: NSPoint(x: gx + (gW - tagSize.width) / 2, y: size.height - tagSize.height - 1), withAttributes: isActive ? gActiveAttrs : gAttrs)
                }
            }
            gaugeRects = newGaugeRects
        } else {
            gaugeRects.removeAll()
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
