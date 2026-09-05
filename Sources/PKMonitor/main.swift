import AppKit
import ApplicationServices
import Combine
import CoreGraphics
import Darwin
import IOKit
import ServiceManagement
import SwiftUI

enum Metric: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case cpu = "CPU"
    case gpu = "GPU"
    case ram = "RAM"
    case disk = "Disk"
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

enum IconLocation: String, CaseIterable, Identifiable {
    case menuBar = "Menu Bar"
    case underBar = "Second Bar"

    var id: String { rawValue }
}

enum UnderBarBackground: String, CaseIterable, Identifiable {
    case transparent = "None"
    case color = "Tint"
    case hover = "Hover"
    case blur = "Blur"

    var id: String { rawValue }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var updateInterval: Double { didSet { defaults.set(updateInterval, forKey: "updateInterval") } }
    @Published var historySeconds: Double { didSet { defaults.set(historySeconds, forKey: "historySeconds") } }
    @Published var iconCount: Int { didSet { defaults.set(iconCount, forKey: "iconCount") } }
    @Published var showOnHover: Bool { didSet { defaults.set(showOnHover, forKey: "showOnHover") } }
    @Published var showSparkline: Bool { didSet { defaults.set(showSparkline, forKey: "showSparkline") } }
    @Published var showPanel: Bool { didSet { defaults.set(showPanel, forKey: "showPanel") } }
    @Published var sparklineWidth: Double { didSet { defaults.set(sparklineWidth, forKey: "sparklineWidth") } }
    @Published var iconSize: Double { didSet { defaults.set(iconSize, forKey: "iconSize") } }
    @Published var lineWidth: Double { didSet { defaults.set(lineWidth, forKey: "lineWidth") } }
    @Published var appearance: AppearanceMode { didSet { defaults.set(appearance.rawValue, forKey: "appearance") } }
    @Published var valuePosition: ValuePosition { didSet { defaults.set(valuePosition.rawValue, forKey: "valuePosition") } }
    @Published var showGauges: Bool { didSet { defaults.set(showGauges, forKey: "showGauges") } }
    @Published var gaugePosition: ValuePosition { didSet { defaults.set(gaugePosition.rawValue, forKey: "gaugePosition") } }
    @Published var showGaugeLabels: Bool { didSet { defaults.set(showGaugeLabels, forKey: "showGaugeLabels") } }
    @Published var gaugeOrder: String { didSet { defaults.set(gaugeOrder, forKey: "gaugeOrder") } }
    @Published var enabledMetrics: String { didSet { defaults.set(enabledMetrics, forKey: "enabledMetrics") } }
    @Published var gaugeWidth: Double { didSet { defaults.set(gaugeWidth, forKey: "gaugeWidth") } }
    @Published var elementSpacing: Double { didSet { defaults.set(elementSpacing, forKey: "elementSpacing") } }

    var gaugeMetrics: [Metric] {
        let parsed = gaugeOrder.split(separator: ",").compactMap { Metric(rawValue: String($0)) }
        return parsed.isEmpty ? [.gpu, .cpu, .ram, .disk, .network] : parsed
    }
    var enabledGaugeMetrics: [Metric] {
        let enabled = Set(enabledMetrics.split(separator: ",").compactMap { Metric(rawValue: String($0)) })
        return gaugeMetrics.filter { enabled.contains($0) }
    }
    @Published var labelPosition: ValuePosition { didSet { defaults.set(labelPosition.rawValue, forKey: "labelPosition") } }
    @Published var showLabel: Bool { didSet { defaults.set(showLabel, forKey: "showLabel") } }
    @Published var showIconBorder: Bool { didSet { defaults.set(showIconBorder, forKey: "showIconBorder") } }
    @Published var showAbsoluteValues: Bool { didSet { defaults.set(showAbsoluteValues, forKey: "showAbsoluteValues") } }
    @Published var iconLocation: IconLocation { didSet { defaults.set(iconLocation.rawValue, forKey: "iconLocation") } }
    @Published var underBarColorHex: String { didSet { defaults.set(underBarColorHex, forKey: "underBarColorHex") } }
    @Published var underBarPaddingTop: Double { didSet { defaults.set(underBarPaddingTop, forKey: "underBarPaddingTop") } }
    @Published var underBarPaddingBottom: Double { didSet { defaults.set(underBarPaddingBottom, forKey: "underBarPaddingBottom") } }
    @Published var underBarPaddingLeft: Double { didSet { defaults.set(underBarPaddingLeft, forKey: "underBarPaddingLeft") } }
    @Published var underBarPaddingRight: Double { didSet { defaults.set(underBarPaddingRight, forKey: "underBarPaddingRight") } }
    @Published var underBarBackground: UnderBarBackground { didSet { defaults.set(underBarBackground.rawValue, forKey: "underBarBackground") } }
    @Published var underBarContent: AppearanceMode { didSet { defaults.set(underBarContent.rawValue, forKey: "underBarContent") } }
    @Published var menuBarItemsSelected: String { didSet { defaults.set(menuBarItemsSelected, forKey: "menuBarItemsSelected") } }
    @Published var menuBarItemsOrder: String { didSet { defaults.set(menuBarItemsOrder, forKey: "menuBarItemsOrder") } }
    @Published var warningThreshold: Double { didSet { defaults.set(warningThreshold, forKey: "warningThreshold") } }
    @Published var criticalThreshold: Double { didSet { defaults.set(criticalThreshold, forKey: "criticalThreshold") } }
    @Published private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled

    private let defaults = UserDefaults.standard

    init() {
        updateInterval = defaults.object(forKey: "updateInterval") as? Double ?? 0.2
        historySeconds = defaults.object(forKey: "historySeconds") as? Double ?? 8
        iconCount = defaults.object(forKey: "iconCount") as? Int ?? 5
        showOnHover = defaults.object(forKey: "showOnHover") as? Bool ?? true
        showSparkline = defaults.object(forKey: "showSparkline") as? Bool ?? true
        showPanel = defaults.object(forKey: "showPanel") as? Bool ?? true
        sparklineWidth = defaults.object(forKey: "sparklineWidth") as? Double ?? 80
        iconSize = defaults.object(forKey: "iconSize") as? Double ?? 15
        lineWidth = defaults.object(forKey: "lineWidth") as? Double ?? 1.6
        appearance = AppearanceMode(rawValue: defaults.string(forKey: "appearance") ?? "") ?? .system
        valuePosition = ValuePosition(rawValue: defaults.string(forKey: "valuePosition") ?? "") ?? .left
        showGauges = defaults.object(forKey: "showGauges") as? Bool ?? true
        gaugePosition = ValuePosition(rawValue: defaults.string(forKey: "gaugePosition") ?? "") ?? .right
        showGaugeLabels = defaults.object(forKey: "showGaugeLabels") as? Bool ?? true
        gaugeOrder = defaults.string(forKey: "gaugeOrder") ?? "GPU,CPU,RAM,Disk,Network"
        enabledMetrics = defaults.string(forKey: "enabledMetrics") ?? "GPU,CPU,RAM,Disk,Network"
        gaugeWidth = defaults.object(forKey: "gaugeWidth") as? Double ?? 16
        elementSpacing = defaults.object(forKey: "elementSpacing") as? Double ?? 4
        labelPosition = ValuePosition(rawValue: defaults.string(forKey: "labelPosition") ?? "") ?? .right
        showLabel = defaults.object(forKey: "showLabel") as? Bool ?? true
        showIconBorder = defaults.object(forKey: "showIconBorder") as? Bool ?? true
        showAbsoluteValues = defaults.object(forKey: "showAbsoluteValues") as? Bool ?? true
        iconLocation = IconLocation(rawValue: defaults.string(forKey: "iconLocation") ?? "") ?? .menuBar
        underBarColorHex = defaults.string(forKey: "underBarColorHex") ?? "#0000001A"
        underBarPaddingTop = defaults.object(forKey: "underBarPaddingTop") as? Double ?? 2
        underBarPaddingBottom = defaults.object(forKey: "underBarPaddingBottom") as? Double ?? 2
        underBarPaddingLeft = defaults.object(forKey: "underBarPaddingLeft") as? Double ?? 12
        underBarPaddingRight = defaults.object(forKey: "underBarPaddingRight") as? Double ?? 12
        underBarBackground = UnderBarBackground(rawValue: defaults.string(forKey: "underBarBackground") ?? "") ?? .blur
        underBarContent = AppearanceMode(rawValue: defaults.string(forKey: "underBarContent") ?? "") ?? .system
        menuBarItemsSelected = defaults.string(forKey: "menuBarItemsSelected") ?? ""
        menuBarItemsOrder = defaults.string(forKey: "menuBarItemsOrder") ?? ""
        warningThreshold = defaults.object(forKey: "warningThreshold") as? Double ?? 80
        criticalThreshold = defaults.object(forKey: "criticalThreshold") as? Double ?? 95
    }

    var selectedMenuBarItems: [String] { Self.parseIDs(menuBarItemsSelected) }
    var menuBarItemOrderList: [String] { Self.parseIDs(menuBarItemsOrder) }

    nonisolated static func parseIDs(_ raw: String) -> [String] {
        raw.split(separator: ",").map(String.init).filter { !$0.isEmpty }
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
        showSparkline = true
        showPanel = true
        sparklineWidth = 80
        iconSize = 15
        lineWidth = 1.6
        appearance = .system
        valuePosition = .left
        showGauges = true
        gaugePosition = .right
        showGaugeLabels = true
        gaugeOrder = "GPU,CPU,RAM,Disk,Network"
        enabledMetrics = "GPU,CPU,RAM,Disk,Network"
        gaugeWidth = 16
        elementSpacing = 4
        labelPosition = .right
        showLabel = true
        showIconBorder = true
        showAbsoluteValues = true
        iconLocation = .menuBar
        underBarColorHex = "#0000001A"
        underBarPaddingTop = 2
        underBarPaddingBottom = 2
        underBarPaddingLeft = 12
        underBarPaddingRight = 12
        underBarBackground = .blur
        underBarContent = .system
        menuBarItemsSelected = ""
        menuBarItemsOrder = ""
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
    var disk = 0.0
    var freeDisk: UInt64 = 0
    var totalDisk: UInt64 = 0
    var download = 0.0
    var upload = 0.0
    var totalRAM: Double = Double(ProcessInfo.processInfo.physicalMemory)
    var usedRAM: Double = 0
    var cpuCores: Int = ProcessInfo.processInfo.activeProcessorCount
    var apps: [AppUsage] = []

    func value(for metric: Metric) -> Double {
        switch metric {
        case .auto, .cpu: cpu
        case .gpu: gpu
        case .ram: ram
        case .disk: disk
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
        let mem = memoryUsage()
        let disk = diskUsage()
        return Reading(cpu: cpuUsage(), ram: mem.percent, gpu: gpuUsage(), network: net.total, disk: disk.percent, freeDisk: disk.free, totalDisk: disk.total, download: net.download, upload: net.upload, usedRAM: Double(mem.usedBytes), apps: previousApps)
    }

    private func diskUsage() -> (percent: Double, free: UInt64, total: UInt64) {
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        guard let values = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: keys),
              let total = values.volumeTotalCapacity,
              let free = values.volumeAvailableCapacityForImportantUsage else { return (0, 0, 0) }
        let used = max(Int64(0), Int64(total) - Int64(free))
        return (100 * Double(used) / Double(max(1, total)), UInt64(free), UInt64(total))
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

    private func memoryUsage() -> (percent: Double, usedBytes: UInt64) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, 0) }
        let appPages = UInt64(max(0, Int64(stats.internal_page_count) - Int64(stats.purgeable_count)))
        let usedPages = appPages + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)
        let usedBytes = usedPages * UInt64(vm_kernel_page_size)
        let percent = min(100, 100 * Double(usedBytes) / Double(ProcessInfo.processInfo.physicalMemory))
        return (percent, usedBytes)
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
        let pct = "\(Int(reading.value(for: metric).rounded()))%"
        guard settings.showAbsoluteValues else { return pct }
        switch metric {
        case .cpu:
            let cores = Double(reading.cpuCores) * reading.cpu / 100
            return "\(pct) (\(String(format: "%.1f", cores)) cores)"
        case .ram:
            return "\(pct) (\(Self.formatBytes(reading.usedRAM)))"
        case .disk:
            return "\(pct) (\(Self.formatBytes(Double(reading.freeDisk))) free / \(Self.formatBytes(Double(reading.totalDisk))))"
        case .network:
            return "↓\(Self.formatBytes(reading.download))/s ↑\(Self.formatBytes(reading.upload))/s"
        default:
            return pct
        }
    }

    func formatMenuBar() -> String {
        switch displayedMetric {
        case .network: return "↓\(Self.formatBytes(reading.download))/s"
        case .disk: return "\(Self.formatBytes(Double(reading.freeDisk))) free"
        default: return "\(Int(reading.value(for: displayedMetric).rounded()))%"
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
        switch displayedMetric {
        case .ram:
            let pct = String(format: "%.0f%%", app.memory / reading.totalRAM * 100)
            return settings.showAbsoluteValues ? "\(Self.formatBytes(app.memory))  \(pct)" : pct
        case .cpu:
            let pct = String(format: "%.1f%%", app.cpu)
            let cores = app.cpu / 100 * Double(reading.cpuCores)
            return settings.showAbsoluteValues ? "\(String(format: "%.1f", cores))c  \(pct)" : pct
        default:
            return String(format: "%.1f%%", app.cpu)
        }
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
        process.arguments = ["-ww", "-Ao", "pid=,%cpu=,rss=,comm="]
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
            let fallbackName = appName(from: path)
            let bundleName = Bundle(path: path)?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? Bundle(path: path)?.object(forInfoDictionaryKey: "CFBundleName") as? String
            let name = bundleName.flatMap { candidate in
                candidate == "com" || candidate.hasPrefix("com.") ? nil : candidate
            } ?? fallbackName
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
        return String(executablePath[..<range.upperBound])
    }

    nonisolated static func appName(from path: String) -> String {
        path.split(separator: "/").first(where: { $0.hasSuffix(".app") })
            .map { String($0.dropLast(4)) }
            ?? URL(fileURLWithPath: path).lastPathComponent
    }

    nonisolated static func formatBytes(_ bytes: Double) -> String {
        if bytes >= 1_000_000_000 { return String(format: "%.1f Go", bytes / 1_000_000_000) }
        if bytes >= 1_000_000 { return String(format: "%.0f Mo", bytes / 1_000_000) }
        if bytes >= 1_000 { return String(format: "%.0f Ko", bytes / 1_000) }
        return "\(Int(bytes)) o"
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
    let activateApp: (AppUsage) -> Void
    let openSettings: () -> Void
    @State private var hoveredApp: String?

    private var absoluteDetail: String {
        switch model.displayedMetric {
        case .cpu:
            let cores = Double(model.reading.cpuCores) * model.reading.cpu / 100
            return String(format: "%.1f / %d cores", cores, model.reading.cpuCores)
        case .ram:
            let total = MonitorModel.formatBytes(model.reading.totalRAM)
            let used = MonitorModel.formatBytes(model.reading.usedRAM)
            return "\(used) / \(total)"
        case .gpu:
            return "GPU utilization"
        default:
            return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(model.displayedMetric.rawValue).font(.headline)
                Spacer()
                if model.displayedMetric == .network {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.blue)
                            Text(MonitorModel.formatBytes(model.reading.download) + "/s")
                                .font(.system(size: 14, weight: .semibold)).monospacedDigit()
                                .foregroundStyle(.blue)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.orange)
                            Text(MonitorModel.formatBytes(model.reading.upload) + "/s")
                                .font(.system(size: 14, weight: .semibold)).monospacedDigit()
                                .foregroundStyle(.orange)
                        }
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(model.reading.value(for: model.displayedMetric).rounded()))%")
                            .font(.title2.monospacedDigit().weight(.semibold))
                            .foregroundColor(Color(nsColor: settings.colorForValue(model.reading.value(for: model.displayedMetric))))
                        if settings.showAbsoluteValues {
                            Text(absoluteDetail)
                                .font(.system(size: 11)).monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
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
                            Button { activateApp(app) } label: {
                                Text(app.name)
                                    .font(.system(size: 15))
                                    .lineLimit(1)
                                    .underline(hoveredApp == app.id)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(hoveredApp == app.id ? Color.accentColor : Color.primary)
                            .help("Show all \(app.name) windows\nPID \(app.pid)\n\(app.path)")
                            .onHover { inside in hoveredApp = inside ? app.id : nil }
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
            HStack {
                Button { openSettings() } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Open Settings")
                Spacer()
                Text("PKMonitor v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev")")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(width: 360)
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
    case menuBarItems = "Menu Bar Items"
    case sparkline = "Sparkline"
    case gauges = "Gauges"
    case panel = "Panel"
    case about = "About"
    case support = "Help & Support"
    case library = "Project Library"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .general: "gearshape"
        case .menuBarItems: "dock.rectangle"
        case .sparkline: "waveform.path.ecg"
        case .gauges: "barometer"
        case .panel: "rectangle.on.rectangle"
        case .about: "info.circle"
        case .support: "heart"
        case .library: "square.grid.2x2"
        }
    }
    var category: String {
        switch self {
        case .general, .menuBarItems, .sparkline, .gauges, .panel: "MONITORING"
        case .about, .support, .library: "PK PROJECTS"
        }
    }
    var keywords: String { "\(rawValue) \(category) bartender hidden icons second bar".lowercased() }
}

private enum ProjectLinks {
    static let github = URL(string: "https://github.com/mondary/PKmonitor")!
    static let githubProfile = URL(string: "https://github.com/mondary")!
    static let koFi = URL(string: "https://ko-fi.com/pouark")!
}

@MainActor
enum AppIcon {
    private static var cache: [Int: NSImage] = [:]

    static func image(side: CGFloat) -> NSImage {
        let pixels = max(16, Int(side * 2))
        if let cached = cache[pixels] { return cached }
        let source = NSImage(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "icon", ofType: "png") ?? ""))
            ?? NSImage(named: NSImage.applicationIconName)
            ?? NSImage()
        let image = NSImage(size: NSSize(width: pixels, height: pixels))
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        source.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels), from: .zero, operation: .sourceOver, fraction: 1.0)
        image.unlockFocus()
        cache[pixels] = image
        return image
    }
}

private struct ProjectIconView: View {
    let name: String
    var body: some View {
        if let image = NSImage(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: name, ofType: "png", inDirectory: "ProjectIcons") ?? "")) {
            Image(nsImage: image).resizable().interpolation(.high).scaledToFit()
        } else {
            Image(nsImage: NSImage(named: "icon") ?? NSImage())
                .resizable().scaledToFit()
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var manager: MenuBarItemsManager
    @State private var selection: SettingsSection? = .general
    @State private var searchText = ""

    private var filteredSections: [SettingsSection] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return SettingsSection.allCases }
        return SettingsSection.allCases.filter { $0.keywords.contains(query) }
    }
    private var groupedSections: [(String, [SettingsSection])] {
        let grouped = Dictionary(grouping: filteredSections, by: \.category)
        return ["MONITORING", "PK PROJECTS"].compactMap { key in
            guard let values = grouped[key], !values.isEmpty else { return nil }
            return (key, values)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image(nsImage: AppIcon.image(side: 34))
                        .resizable().interpolation(.high).scaledToFit()
                        .frame(width: 34, height: 34)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PKMonitor").font(.headline)
                        Text("System activity").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 22)
                .padding(.bottom, 18)

                Text("SETTINGS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search settings", text: $searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            if let first = filteredSections.first { selection = first }
                        }
                }
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 7))
                .padding(.horizontal, 12)
                .padding(.bottom, 12)

                VStack(spacing: 3) {
                    ForEach(groupedSections, id: \.0) { group, sections in
                        Text(group).font(.system(size: 9, weight: .bold)).foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.top, 8)
                        ForEach(sections) { section in
                        Button {
                            selection = section
                        } label: {
                            HStack(spacing: 11) {
                                Image(systemName: section.icon)
                                    .font(.system(size: 14, weight: .medium))
                                    .frame(width: 20)
                                Text(section.rawValue)
                                    .font(.system(size: 13, weight: selection == section ? .semibold : .regular))
                                Spacer()
                            }
                            .foregroundStyle(selection == section ? .primary : .secondary)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(selection == section ? Color.accentColor.opacity(0.13) : .clear,
                                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        }
                    }
                }
                Spacer()
                Text("PKMonitor \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development")")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
            }
            .frame(width: 220)
            .background(.regularMaterial)

            Divider()

            Group {
                switch selection ?? .general {
                case .general: GeneralSettingsView(settings: settings)
                case .menuBarItems: MenuBarItemsSettingsView(settings: settings, manager: manager)
                case .sparkline: SparklineSettingsView(settings: settings)
                case .gauges: GaugesSettingsView(settings: settings)
                case .panel: PanelSettingsView(settings: settings)
                case .about: AboutSettingsView()
                case .support: SupportSettingsView()
                case .library: ProjectLibraryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(minWidth: 980, minHeight: 650)
    }
}

struct SettingsHeader: View {
    let title: String
    let subtitle: String
    var icon: String = "gearshape"
    var enabled: Binding<Bool>? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 34, height: 34)
                        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    Text(title).font(.system(size: 28, weight: .bold, design: .rounded))
                }
                Text(subtitle).font(.system(size: 13)).foregroundStyle(.secondary)
                    .padding(.leading, 44)
            }
            Spacer(minLength: 0)
            if let enabled {
                Toggle("", isOn: enabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .accessibilityLabel("Show \(title)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let subtitle: String?
    let enabled: Binding<Bool>?
    @ViewBuilder let content: () -> Content

    init(_ title: String, icon: String, subtitle: String? = nil, enabled: Binding<Bool>? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.enabled = enabled
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 30, height: 30)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15, weight: .semibold))
                    if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
                }
                Spacer()
                if let enabled {
                    Toggle("", isOn: enabled).labelsHidden().toggleStyle(.switch)
                        .accessibilityLabel("Show \(title)")
                }
            }
            content()
        }
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5))
    }
}

struct SettingLine<Content: View>: View {
    let title: String
    let detail: String?
    @ViewBuilder let content: () -> Content

    init(_ title: String, detail: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.detail = detail
        self.content = content
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium))
                if let detail { Text(detail).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 20)
            content()
        }
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SettingsHeader(title: "General", subtitle: "Choose how PKMonitor behaves and where it lives.")
                SettingsCard("Icon Location", icon: "menubar.rectangle", subtitle: "Keep the readout in the menu bar or in the compact bar below it.") {
                    Picker("Location", selection: $settings.iconLocation) {
                        ForEach(IconLocation.allCases) { location in Text(location.rawValue).tag(location) }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 310, alignment: .leading)
                    Text("Second Bar is a right-aligned pill. Its background and spacing can be tuned below.")
                        .font(.caption).foregroundStyle(.secondary)
                    Divider()
                    SettingLine("Background") {
                        Picker("Background", selection: $settings.underBarBackground) {
                            ForEach(UnderBarBackground.allCases) { background in Text(background.rawValue).tag(background) }
                        }
                        .labelsHidden().pickerStyle(.segmented).frame(width: 260)
                    }
                    SettingLine("Background color", detail: "Includes opacity") {
                        ColorPicker("Background color", selection: Binding(
                            get: { Color(nsColor: NSColor(hex: settings.underBarColorHex) ?? .black) },
                            set: { settings.underBarColorHex = NSColor($0).hex }
                        ), supportsOpacity: true)
                        .labelsHidden()
                    }
                    SettingLine("Content color") {
                        Picker("Content", selection: $settings.underBarContent) {
                            Text("Auto").tag(AppearanceMode.system)
                            Text("Black").tag(AppearanceMode.light)
                            Text("White").tag(AppearanceMode.dark)
                        }
                        .labelsHidden().pickerStyle(.segmented).frame(width: 260)
                    }
                    Divider()
                    Text("Padding").font(.system(size: 13, weight: .medium))
                    HStack(spacing: 18) {
                        paddingControl("Top", value: $settings.underBarPaddingTop)
                        paddingControl("Bottom", value: $settings.underBarPaddingBottom)
                        paddingControl("Left", value: $settings.underBarPaddingLeft)
                        paddingControl("Right", value: $settings.underBarPaddingRight)
                    }
                }

                SettingsCard("Monitoring", icon: "gauge.with.dots.needle.67percent", subtitle: "How often readings and app activity are refreshed.") {
                    SettingLine("Refresh rate") {
                        Picker("Refresh rate", selection: $settings.updateInterval) {
                            Text("100 ms").tag(0.1); Text("200 ms").tag(0.2); Text("500 ms").tag(0.5); Text("1 second").tag(1.0)
                        }
                        .labelsHidden().frame(width: 180)
                    }
                    SettingLine("History duration") {
                        Picker("History duration", selection: $settings.historySeconds) {
                            Text("5 seconds").tag(5.0); Text("8 seconds").tag(8.0); Text("15 seconds").tag(15.0); Text("30 seconds").tag(30.0)
                        }
                        .labelsHidden().frame(width: 180)
                    }
                    SettingLine("Top applications", detail: "Shown as markers on the sparkline") {
                        Stepper("\(settings.iconCount)", value: $settings.iconCount, in: 1...5).labelsHidden().frame(width: 100)
                    }
                }

                SettingsCard("Detail Panel", icon: "rectangle.on.rectangle", subtitle: "Control what appears when you inspect the readout.") {
                    Toggle("Show details on hover", isOn: $settings.showOnHover)
                    Toggle("Show absolute values", isOn: $settings.showAbsoluteValues)
                }

                SettingsCard("Color Thresholds", icon: "exclamationmark.triangle", subtitle: "Change the warning colors used by the readout.") {
                    thresholdControl("Warning", value: $settings.warningThreshold, color: .orange)
                    thresholdControl("Critical", value: $settings.criticalThreshold, color: .red)
                }

                SettingsCard("System", icon: "power", subtitle: "Start PKMonitor automatically when you log in.") {
                    Toggle("Launch at login", isOn: Binding(
                        get: { settings.launchAtLogin },
                        set: { enabled in
                            do { try settings.setLaunchAtLogin(enabled) }
                            catch { errorMessage = error.localizedDescription }
                        }
                    ))
                }

                Button("Restore All Defaults") { settings.restoreDefaults() }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.secondary)
            }
            .padding(28)
        }
        .alert("Setting could not be changed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    private func paddingControl(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Slider(value: value, in: 0...24, step: 1)
            Text("\(Int(value.wrappedValue)) pt").font(.caption2).monospacedDigit().foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func thresholdControl(_ title: String, value: Binding<Double>, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(title).frame(width: 70, alignment: .leading)
            Slider(value: value, in: 50...100, step: 5)
            Text("\(Int(value.wrappedValue))%").monospacedDigit().foregroundStyle(.secondary).frame(width: 42, alignment: .trailing)
        }
    }
}

struct SparklineSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SettingsHeader(title: "Sparkline", subtitle: "Tune the compact graph shown in the menu bar.", icon: "waveform.path.ecg", enabled: $settings.showSparkline)
                SettingsCard("Graph", icon: "waveform.path.ecg", subtitle: "Size and rendering detail.") {
                    SettingLine("Width", detail: "The graph also controls the pill width") {
                        HStack { Slider(value: $settings.sparklineWidth, in: 56...160, step: 4); Text("\(Int(settings.sparklineWidth)) pt").monospacedDigit().foregroundStyle(.secondary).frame(width: 48) }
                            .frame(width: 280)
                    }
                    SettingLine("Line thickness") {
                        HStack { Slider(value: $settings.lineWidth, in: 1...3, step: 0.2); Text("\(settings.lineWidth, specifier: "%.1f") pt").monospacedDigit().foregroundStyle(.secondary).frame(width: 48) }
                            .frame(width: 280)
                    }
                }
                SettingsCard("App Markers", icon: "app.dashed", subtitle: "Show the apps contributing to activity.") {
                    SettingLine("Icon size") {
                        HStack { Slider(value: $settings.iconSize, in: 10...18, step: 1); Text("\(Int(settings.iconSize)) pt").monospacedDigit().foregroundStyle(.secondary).frame(width: 48) }
                            .frame(width: 280)
                    }
                    Toggle("Show a border around icons", isOn: $settings.showIconBorder)
                }
                SettingsCard("Labels", icon: "textformat", subtitle: "Place or hide the metric labels.") {
                    SettingLine("Value position") {
                        Picker("Value position", selection: $settings.valuePosition) { ForEach(ValuePosition.allCases) { Text($0.rawValue).tag($0) } }
                            .labelsHidden().frame(width: 180)
                    }
                    Toggle("Show metric name", isOn: $settings.showLabel)
                    SettingLine("Metric name position") {
                        Picker("Metric name position", selection: $settings.labelPosition) { ForEach(ValuePosition.allCases) { Text($0.rawValue).tag($0) } }
                            .labelsHidden().frame(width: 180)
                    }
                }
            }
            .padding(28)
        }
    }
}

struct GaugesSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SettingsHeader(title: "Gauges", subtitle: "Keep the system signals visible at a glance.", icon: "barometer", enabled: $settings.showGauges)
                SettingsCard("Gauge Display", icon: "gauge.with.dots.needle.67percent", subtitle: "Choose what is visible beside the graph.") {
                    Text("Visible segments").font(.subheadline.weight(.medium)).padding(.top, 4)
                    ForEach(settings.gaugeMetrics, id: \.self) { metric in
                        Toggle(metric == .network ? "Network" : metric.rawValue,
                               isOn: Binding(
                                get: { settings.enabledGaugeMetrics.contains(metric) },
                                set: { enabled in
                                    var values = settings.enabledGaugeMetrics
                                    if enabled { if !values.contains(metric) { values.append(metric) } }
                                    else { values.removeAll { $0 == metric } }
                                    settings.enabledMetrics = values.map(\.rawValue).joined(separator: ",")
                                }))
                    }
                    SettingLine("Position") {
                        Picker("Position", selection: $settings.gaugePosition) { ForEach(ValuePosition.allCases) { Text($0.rawValue).tag($0) } }
                            .labelsHidden().frame(width: 180)
                    }
                    Toggle("Show labels on gauges", isOn: $settings.showGaugeLabels)
                    SettingLine("Gauge width") {
                        HStack {
                            Slider(value: $settings.gaugeWidth, in: 10...28, step: 2)
                            Text("\(Int(settings.gaugeWidth)) pt").monospacedDigit().foregroundStyle(.secondary).frame(width: 42)
                        }
                        .frame(width: 220)
                    }
                }
                SettingsCard("Gauge Order", icon: "arrow.up.arrow.down", subtitle: "Drag to reorder the four gauges from left to right.") {
                    GaugeOrderList(gaugeOrder: Binding(
                        get: { settings.gaugeMetrics },
                        set: { settings.gaugeOrder = $0.map(\.rawValue).joined(separator: ",") }
                    ))
                }
                SettingsCard("Preview", icon: "eye", subtitle: "The active metric is highlighted in the live readout.") {
                    HStack(spacing: 18) {
                        ForEach(settings.gaugeMetrics, id: \.self) { metric in
                            VStack(spacing: 5) {
                                Text(metric == .network ? "NET" : metric.rawValue).font(.system(size: 9, weight: .bold))
                                RoundedRectangle(cornerRadius: 4).fill(Color.accentColor.opacity(0.28)).frame(width: 24, height: 56)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.accentColor.opacity(0.8), lineWidth: 1))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .padding(28)
        }
    }
}

struct GaugeOrderList: View {
    @Binding var gaugeOrder: [Metric]

    var body: some View {
        List {
            ForEach(gaugeOrder, id: \.self) { metric in
                HStack(spacing: 10) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.tertiary)
                    Text(metric == .network ? "NET" : metric.rawValue)
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Text(gaugeLetter(metric))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .onMove { from, to in
                gaugeOrder.move(fromOffsets: from, toOffset: to)
            }
        }
        .listStyle(.plain)
        .frame(height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func gaugeLetter(_ metric: Metric) -> String {
        switch metric {
        case .gpu: "G"
        case .cpu: "C"
        case .ram: "R"
        case .disk: "D"
        case .network: "N"
        default: ""
        }
    }
}

struct PanelSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SettingsHeader(title: "Panel", subtitle: "Shape the detail panel and its visual language.", icon: "rectangle.on.rectangle", enabled: $settings.showPanel)
                SettingsCard("Appearance", icon: "paintbrush", subtitle: "Choose how the detail panel follows your Mac.") {
                    Picker("Appearance", selection: $settings.appearance) { ForEach(AppearanceMode.allCases) { Text($0.rawValue).tag($0) } }
                        .pickerStyle(.segmented).frame(maxWidth: 360, alignment: .leading)
                }
                SettingsCard("Layout Preview", icon: "rectangle.on.rectangle", subtitle: "A quick overview of the current arrangement.") {
                    previewLine("waveform.path.ecg", "Sparkline graph", "Graph area")
                    previewLine("arrow.down.to.line", "Value label", settings.valuePosition == .left ? "Left" : "Right")
                    previewLine("textformat.abc", "Metric label", settings.showLabel ? (settings.labelPosition == .left ? "Left" : "Right") : "Hidden")
                    previewLine("barometer", "Gauges", settings.showGauges ? (settings.gaugePosition == .left ? "Left" : "Right") : "Hidden")
                }
            }
            .padding(28)
        }
    }

    private func previewLine(_ icon: String, _ title: String, _ value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(Color.accentColor).frame(width: 22)
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
        .font(.system(size: 13))
    }
}

struct AboutSettingsView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(Color.accentColor.opacity(0.14)).frame(width: 132, height: 132)
                    Image(nsImage: AppIcon.image(side: 88))
                        .resizable().interpolation(.high).scaledToFit()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                }
                .padding(.top, 36)
                .padding(.bottom, 18)
                Text("PKMonitor").font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Version \(version)").font(.system(size: 13, design: .monospaced)).foregroundStyle(.secondary).padding(.top, 5)
                Text("A quiet, precise readout for CPU, memory, GPU and network activity.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 430)
                    .padding(.top, 14)

                HStack(spacing: 10) {
                    aboutBadge("waveform.path.ecg", "Live metrics")
                    aboutBadge("eye", "At a glance")
                    aboutBadge("lock.shield", "Local only")
                }
                .padding(.top, 26)

                SettingsCard("About PKMonitor", icon: "info.circle", subtitle: "Built for a focused desktop.") {
                    Text("PKMonitor keeps the information you need close at hand without turning your desktop into a dashboard. Hover for detail, click a gauge to change the active metric, and tune the presentation to your workflow.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Label("macOS 13 or later", systemImage: "apple.logo")
                        Spacer()
                        Text("Made by PK").foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
                .frame(maxWidth: 560)
                .padding(.top, 30)
                .padding(.bottom, 26)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func aboutBadge(_ icon: String, _ title: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(nsColor: .controlBackgroundColor), in: Capsule())
    }
}

struct SupportSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsHeader(title: "Help & Support", subtitle: "Support the project and stay connected.", icon: "heart.fill")
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 25, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(Color(nsColor: NSColor(hex: "#13C3FF")!), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Keep PKMonitor independent")
                                .font(.system(size: 19, weight: .bold, design: .rounded))
                            Text("A small coffee helps me keep polishing the app, adding modules and maintaining releases.")
                                .font(.system(size: 13)).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Link(destination: ProjectLinks.koFi) {
                        HStack(spacing: 10) {
                            Image(systemName: "heart.fill")
                            Text("Buy me a coffee on Ko-fi").fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(Color(nsColor: NSColor(hex: "#13C3FF")!), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .shadow(color: Color(nsColor: NSColor(hex: "#13C3FF")!).opacity(0.25), radius: 10, y: 5)
                }
                .padding(20)
                .background(
                    LinearGradient(colors: [Color.accentColor.opacity(0.16), Color(nsColor: .controlBackgroundColor)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.accentColor.opacity(0.25), lineWidth: 1))

                SettingsCard("Follow the project", icon: "person.2.fill", subtitle: "Updates, source code and the rest of the project collection.") {
                    HStack(spacing: 10) {
                        Link(destination: ProjectLinks.github) { Label("PKMonitor", systemImage: "chevron.left.forwardslash.chevron.right") }
                            .buttonStyle(.bordered)
                        Link(destination: ProjectLinks.githubProfile) { Label("GitHub", systemImage: "person.crop.circle") }
                            .buttonStyle(.bordered)
                    }
                }
                Text("Thank you for helping keep free tools alive.")
                    .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }.padding(28)
        }
    }
}

struct ProjectLibraryView: View {
    private struct Project: Identifiable {
        let id: String
        let title: String
        let kind: String
        let description: String
        let iconAsset: String
        let screenshot: String?
        let tint: NSColor
        var url: URL { URL(string: "https://github.com/mondary/\(id)")! }
    }

    private let projects = [
        Project(id: "Macos_PKarchives", title: "PKarchives", kind: "macOS app", description: "Archive your Desktop to Google Drive with rclone, using a native macOS interface or CLI/TUI.", iconAsset: "PKarchives", screenshot: "PKarchives", tint: NSColor(hex: "#8B5CF6")!),
        Project(id: "PKmonitor", title: "PKMonitor", kind: "macOS app", description: "CPU, GPU, RAM, network and disk metrics in the menu bar.", iconAsset: "icon", screenshot: "PKmonitor", tint: NSColor(hex: "#0EA5E9")!),
        Project(id: "PKwindowsManagement", title: "PKwindowsManagement", kind: "macOS app", description: "Manage windows by keyboard and launch installed applications quickly from the menu bar.", iconAsset: "PKwindowsManagement", screenshot: nil, tint: NSColor(hex: "#F97316")!),
        Project(id: "Macos_PKpowerlines", title: "PKpowerlines", kind: "macOS app", description: "A native multi-display powerline showing RAM, CPU, network or battery in real time.", iconAsset: "PKpowerlines", screenshot: "PKpowerlines", tint: NSColor(hex: "#10B981")!),
        Project(id: "PKmac-cleanup", title: "LaunchPad", kind: "macOS app", description: "Scan and audit user agents and system daemons with local security analysis.", iconAsset: "PKmac-cleanup", screenshot: nil, tint: NSColor(hex: "#EC4899")!),
        Project(id: "Chrome_SimpleGMAIL", title: "PKMail", kind: "Chrome / macOS / Windows / Linux", description: "An immersive IMAP mail client with a vanilla HTML interface and Gmail-style workflows.", iconAsset: "PKMail", screenshot: nil, tint: NSColor(hex: "#EA4335")!),
        Project(id: "Chrome_PKshortcuts", title: "PK Chrome Shortcuts", kind: "Chrome extension", description: "Control tabs, navigation and split view with keyboard shortcuts.", iconAsset: "PKshortcuts", screenshot: nil, tint: NSColor(hex: "#F59E0B")!)
    ]

    private var featured: Project { projects.first { $0.id == "PKmonitor" }! }
    private var gridProjects: [Project] { projects.filter { $0.id != "PKmonitor" } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SettingsHeader(title: "Project Library", subtitle: "Discover the other tools and projects I build.", icon: "square.grid.2x2")
                featuredCard(featured)
                Text("More projects").font(.system(size: 18, weight: .bold, design: .rounded))
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(gridProjects) { project in
                        projectCard(project)
                    }
                }
                Link(destination: ProjectLinks.githubProfile) { Label("View all repositories on GitHub", systemImage: "arrow.up.right.square") }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 6)
            }.padding(28)
        }
    }

    private func screenshotImage(_ name: String) -> NSImage? {
        NSImage(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: name, ofType: "png", inDirectory: "ProjectScreenshots") ?? ""))
    }

    private func featuredCard(_ project: Project) -> some View {
        Link(destination: project.url) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        ProjectIconView(name: project.iconAsset)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: .black.opacity(0.18), radius: 5, y: 2)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(project.title).font(.system(size: 24, weight: .bold, design: .rounded))
                            Text(project.kind.uppercased()).font(.system(size: 10, weight: .bold)).foregroundStyle(Color(nsColor: project.tint))
                        }
                    }
                    Text(project.description)
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(3)
                    Label("Star on GitHub", systemImage: "star.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Color.accentColor, in: Capsule())
                }
                .padding(22)
                .frame(maxWidth: 340, alignment: .topLeading)
                if let image = screenshotImage(project.screenshot!) {
                    GeometryReader { geo in
                        Image(nsImage: image)
                            .resizable().interpolation(.high)
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .leading) {
                        LinearGradient(colors: [Color(nsColor: .controlBackgroundColor), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 60)
                    }
                }
            }
            .frame(height: 210)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func projectCard(_ project: Project) -> some View {
        Link(destination: project.url) {
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    if let shot = project.screenshot, let image = screenshotImage(shot) {
                        Image(nsImage: image)
                            .resizable().interpolation(.high)
                            .scaledToFill()
                            .frame(width: 300, height: 150)
                            .clipped()
                    } else {
                        ZStack {
                            LinearGradient(colors: [Color(nsColor: project.tint).opacity(0.75), Color(nsColor: project.tint).opacity(0.35)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                            ProjectIconView(name: project.iconAsset)
                                .frame(width: 74, height: 74)
                                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
                        }
                    }
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(alignment: .topLeading) {
                    Text(project.kind.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(10)
                }
                HStack(alignment: .top, spacing: 10) {
                    ProjectIconView(name: project.iconAsset)
                        .frame(width: 30, height: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(project.title).font(.system(size: 14, weight: .semibold))
                        Text(project.description).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(2)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.tertiary)
                }
                .padding(14)
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

extension NSColor {
    convenience init?(hex: String) {
        var s = String(hex.filter { $0.isHexDigit })
        guard s.count == 6 || s.count == 8 else { return nil }
        if s.count == 6 { s += "FF" }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        self.init(
            srgbRed: CGFloat((value >> 24) & 0xFF) / 255,
            green: CGFloat((value >> 16) & 0xFF) / 255,
            blue: CGFloat((value >> 8) & 0xFF) / 255,
            alpha: CGFloat(value & 0xFF) / 255
        )
    }

    var hex: String {
        guard let c = usingColorSpace(.sRGB) else { return "#000000FF" }
        return String(
            format: "#%02X%02X%02X%02X",
            Int(round(c.redComponent * 255)),
            Int(round(c.greenComponent * 255)),
            Int(round(c.blueComponent * 255)),
            Int(round(c.alphaComponent * 255))
        )
    }
}

// MARK: - Menu Bar Items (Bartender-style)

@MainActor
final class MenuBarItemsManager: ObservableObject {
    struct Detected: Identifiable {
        let id: String
        let appName: String
        let title: String
        let icon: NSImage?
    }
    struct Rendered: Identifiable {
        let id: String
        let appName: String
        let image: NSImage
    }
    private struct Item {
        let id: String
        let element: AXUIElement
        let appName: String
        let title: String
        let icon: NSImage?
        let frame: CGRect
        let pid: pid_t
    }
    private struct ClickSession {
        let pid: pid_t
        let home: CGPoint
        var menuSeen = false
        var closedStreak = 0
    }

    @Published private(set) var detected: [Detected] = []
    @Published private(set) var rendered: [Rendered] = []
    @Published private(set) var accessibilityTrusted = AXIsProcessTrusted()
    @Published private(set) var screenCaptureTrusted = CGPreflightScreenCaptureAccess()

    private let settings: AppSettings
    private var elements: [String: AXUIElement] = [:]
    private var originals: [String: CGPoint] = [:]
    private var sessions: [String: ClickSession] = [:]

    init(settings: AppSettings) { self.settings = settings }

    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        accessibilityTrusted = AXIsProcessTrustedWithOptions(options)
    }

    func requestScreenCapture() {
        _ = CGRequestScreenCaptureAccess()
        screenCaptureTrusted = CGPreflightScreenCaptureAccess()
    }

    func applySelection() { tick() }

    func tick() {
        accessibilityTrusted = AXIsProcessTrusted()
        screenCaptureTrusted = CGPreflightScreenCaptureAccess()
        guard accessibilityTrusted else {
            if !detected.isEmpty || !rendered.isEmpty || !originals.isEmpty {
                restoreAll()
                detected = []
                rendered = []
                elements = [:]
            }
            return
        }
        // ponytail: reenumeration AX complete toutes les 2 s (~1 IPC par app) ; passer a un AXObserver si profilage exigeant
        let items = enumerateItems()
        elements = Dictionary(items.map { ($0.id, $0.element) }, uniquingKeysWith: { first, _ in first })
        detected = items.map { Detected(id: $0.id, appName: $0.appName, title: $0.title, icon: $0.icon) }

        let selected = Set(settings.selectedMenuBarItems)
        for id in originals.keys where !selected.contains(id) || elements[id] == nil { unpark(id) }
        guard screenCaptureTrusted else { return }
        var fresh: [Rendered] = []
        for item in items where selected.contains(item.id) {
            if sessions[item.id] == nil { park(item) }
            if let image = captureImage(item: item) {
                fresh.append(Rendered(id: item.id, appName: item.appName, image: image))
            }
        }
        rendered = ordered(fresh)
    }

    func forwardClick(_ id: String) {
        guard sessions[id] == nil, let element = elements[id], let home = originals[id], let frame = elementFrame(element) else { return }
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        sessions[id] = ClickSession(pid: pid, home: home)
        setPoint(element, home)
        schedulePollIfNeeded()
        let center = CGPoint(x: home.x + frame.width / 2, y: home.y + frame.height / 2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { Task { @MainActor in
            Self.postMouseButton(.leftMouseDown, at: center)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { Task { @MainActor in
                Self.postMouseButton(.leftMouseUp, at: center)
            } }
        } }
    }

    func restoreAll() {
        for id in Array(originals.keys) { unpark(id) }
        sessions.removeAll()
    }

    // MARK: Private

    private func enumerateItems() -> [Item] {
        var out: [Item] = []
        let ownPID = ProcessInfo.processInfo.processIdentifier
        for app in NSWorkspace.shared.runningApplications where app.processIdentifier != ownPID {
            guard let bundleID = app.bundleIdentifier, let appName = app.localizedName else { continue }
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            var raw: CFTypeRef?
            guard AXUIElementCopyAttributeValue(appElement, kAXExtrasMenuBarAttribute as CFString, &raw) == .success,
                  let children = raw as? [AXUIElement], !children.isEmpty else { continue }
            let icon = app.bundleURL.map { NSWorkspace.shared.icon(forFile: $0.path) }
            icon?.size = NSSize(width: 18, height: 18)
            for (index, element) in children.enumerated() {
                guard let frame = elementFrame(element), frame.width > 1 else { continue }
                let title = axString(element, kAXDescriptionAttribute) ?? axString(element, kAXTitleAttribute) ?? ""
                let id = Self.stableID(bundle: bundleID, appName: appName, title: title, index: index, existing: out.map(\.id))
                out.append(Item(id: id, element: element, appName: appName, title: title, icon: icon, frame: frame, pid: app.processIdentifier))
            }
        }
        return out
    }

    private func park(_ item: Item) {
        let home: CGPoint
        if let saved = originals[item.id] {
            home = saved
        } else {
            guard let position = axPoint(item.element, kAXPositionAttribute) else { return }
            home = position
            originals[item.id] = position
        }
        setPoint(item.element, CGPoint(x: -(item.frame.width + 60), y: home.y))
    }

    private func unpark(_ id: String) {
        guard let element = elements[id] else { originals[id] = nil; return }
        if let home = originals.removeValue(forKey: id) { setPoint(element, home) }
    }

    private func ordered(_ fresh: [Rendered]) -> [Rendered] {
        let order = settings.menuBarItemOrderList
        return fresh.enumerated().sorted { lhs, rhs in
            let li = order.firstIndex(of: lhs.element.id) ?? .max
            let ri = order.firstIndex(of: rhs.element.id) ?? .max
            return li == ri ? lhs.offset < rhs.offset : li < ri
        }.map(\.element)
    }

    private func schedulePollIfNeeded() {
        guard !sessions.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { Task { @MainActor [weak self] in
            guard let self else { return }
            self.stepSessions()
            if !self.sessions.isEmpty { self.schedulePollIfNeeded() }
        } }
    }

    private func stepSessions() {
        for (id, session) in sessions {
            guard let element = elements[id] else { sessions[id] = nil; continue }
            var session = session
            if Self.pidHasOpenMenu(pid: session.pid) {
                session.menuSeen = true
                session.closedStreak = 0
            } else {
                session.closedStreak += 1
            }
            // ponytail: fermeture devinee via fenetres de menu (layer 101) ; AXObserver AXMenuClosed si cas limite
            if (session.menuSeen && session.closedStreak >= 2) || session.closedStreak >= 6 {
                let width = elementFrame(element)?.width ?? 30
                setPoint(element, CGPoint(x: -(width + 60), y: session.home.y))
                sessions[id] = nil
            } else {
                sessions[id] = session
            }
        }
    }

    private func captureImage(item: Item) -> NSImage? {
        guard let window = Self.statusWindows().first(where: {
            $0.pid == item.pid && abs($0.bounds.midX - item.frame.midX) < 4 && abs($0.bounds.width - item.frame.width) < 4
        }) else { return nil }
        return Self.captureWindowImage(window.number, pointsWidth: window.bounds.width)
    }

    nonisolated static func stableID(bundle: String, appName: String, title: String, index: Int, existing: [String]) -> String {
        var base = "\(bundle)|\(title.isEmpty ? appName : title)"
        if existing.contains(base) { base += "#\(index)" }
        return base
    }

    nonisolated private static func postMouseButton(_ type: CGEventType, at point: CGPoint) {
        guard let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left) else { return }
        event.post(tap: .cghidEventTap)
    }

    // ponytail: CGWindowListCreateImage deprecated macOS 14 (ScreenCaptureKit) ; garder le chemin simple tant que macOS 13 supporte
    @available(macOS, deprecated: 14.0)
    nonisolated private static func captureWindowImage(_ window: CGWindowID, pointsWidth: CGFloat) -> NSImage? {
        guard let cgImage = CGWindowListCreateImage(.null, .optionIncludingWindow, window, [.bestResolution]) else { return nil }
        let scale = pointsWidth > 0 ? CGFloat(cgImage.width) / pointsWidth : 2
        var width = CGFloat(cgImage.width) / scale
        var height = CGFloat(cgImage.height) / scale
        let cap: CGFloat = 18
        if height > cap { width *= cap / height; height = cap }
        return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    }

    private struct StatusWindow {
        let number: CGWindowID
        let bounds: CGRect
        let pid: pid_t
    }

    nonisolated private static func statusWindows() -> [StatusWindow] {
        guard let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] else { return [] }
        return list.compactMap { info in
            guard let layer = info[kCGWindowLayer as String] as? Int, (20...30).contains(layer),
                  let pid = info[kCGWindowOwnerPID as String] as? Int,
                  let bounds = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let number = info[kCGWindowNumber as String] as? Int else { return nil }
            let rect = CGRect(x: bounds["X"] ?? 0, y: bounds["Y"] ?? 0, width: bounds["Width"] ?? 0, height: bounds["Height"] ?? 0)
            return StatusWindow(number: CGWindowID(number), bounds: rect, pid: pid_t(pid))
        }
    }

    nonisolated private static func pidHasOpenMenu(pid: pid_t) -> Bool {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else { return false }
        return list.contains { info in
            info[kCGWindowOwnerPID as String] as? Int == Int(pid)
                && info[kCGWindowLayer as String] as? Int == 101
        }
    }

    nonisolated private func axString(_ element: AXUIElement, _ attribute: String) -> String? {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &raw) == .success else { return nil }
        return raw as? String
    }

    nonisolated private func axPoint(_ element: AXUIElement, _ attribute: String) -> CGPoint? {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &raw) == .success,
              let value = raw, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        var point = CGPoint.zero
        AXValueGetValue(value as! AXValue, .cgPoint, &point)
        return point
    }

    nonisolated private func axSize(_ element: AXUIElement, _ attribute: String) -> CGSize? {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &raw) == .success,
              let value = raw, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        var size = CGSize.zero
        AXValueGetValue(value as! AXValue, .cgSize, &size)
        return size
    }

    nonisolated private func elementFrame(_ element: AXUIElement) -> CGRect? {
        guard let origin = axPoint(element, kAXPositionAttribute), let size = axSize(element, kAXSizeAttribute) else { return nil }
        return CGRect(origin: origin, size: size)
    }

    nonisolated private func setPoint(_ element: AXUIElement, _ point: CGPoint) {
        var position = point
        if let value = AXValueCreate(.cgPoint, &position) {
            AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, value)
        }
    }
}

struct MenuBarItemsSettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var manager: MenuBarItemsManager

    private var rows: [MenuBarItemsManager.Detected] {
        let order = settings.menuBarItemOrderList
        let known = manager.detected
        return order.compactMap { id in known.first { $0.id == id } } + known.filter { !order.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SettingsHeader(title: "Menu Bar Items", subtitle: "Lower other apps' menu bar icons into PKMonitor's second bar.", icon: "dock.rectangle")

                if !manager.accessibilityTrusted {
                    SettingsCard("Accessibility permission", icon: "lock.shield", subtitle: "PKMonitor must move the original icons off the menu bar on your behalf.") {
                        Button("Grant Accessibility…") { manager.requestAccessibility() }
                            .buttonStyle(.borderedProminent)
                    }
                } else if !manager.screenCaptureTrusted {
                    SettingsCard("Screen Recording permission", icon: "video.slash", subtitle: "PKMonitor photographs each lowered icon so it can redraw it in the second bar.") {
                        Button("Grant Screen Recording…") { manager.requestScreenCapture() }
                            .buttonStyle(.borderedProminent)
                    }
                }

                SettingsCard("Detected icons", icon: "list.bullet.rectangle", subtitle: "Check an icon to lower it into the second bar. Drag rows to set the order — top row is the leftmost icon.") {
                    if manager.detected.isEmpty {
                        Text(manager.accessibilityTrusted ? "Scanning the menu bar… nothing else found yet." : "Grant Accessibility to scan the menu bar.")
                            .font(.system(size: 13)).foregroundStyle(.secondary)
                    } else {
                        List {
                            ForEach(rows) { item in
                                HStack(spacing: 12) {
                                    Toggle("", isOn: selectionBinding(item.id))
                                    if let icon = item.icon {
                                        Image(nsImage: icon).resizable().frame(width: 18, height: 18)
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.appName).font(.system(size: 13, weight: .medium))
                                        if !item.title.isEmpty { Text(item.title).font(.caption).foregroundStyle(.secondary) }
                                    }
                                    Spacer()
                                    if settings.selectedMenuBarItems.contains(item.id) {
                                        Text("In second bar").font(.caption).foregroundStyle(Color.accentColor)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .onMove(perform: moveRows)
                        }
                        .listStyle(.plain)
                        .frame(height: min(340, max(120, CGFloat(rows.count) * 38)))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }

                Text("Lowered icons stay hidden while PKMonitor runs; they return to the menu bar when unchecked or when PKMonitor quits.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(28)
        }
    }

    private func selectionBinding(_ id: String) -> Binding<Bool> {
        Binding(
            get: { settings.selectedMenuBarItems.contains(id) },
            set: { on in
                var ids = settings.selectedMenuBarItems
                if on {
                    if !ids.contains(id) { ids.append(id) }
                } else {
                    ids.removeAll { $0 == id }
                }
                settings.menuBarItemsSelected = ids.joined(separator: ",")
                manager.applySelection()
            }
        )
    }

    private func moveRows(_ from: IndexSet, _ to: Int) {
        var ids = rows.map(\.id)
        ids.move(fromOffsets: from, toOffset: to)
        settings.menuBarItemsOrder = ids.joined(separator: ",")
        manager.applySelection()
    }
}

final class UnderBarTintView: NSView {
    var color: NSColor = NSColor(hex: "#0000001A")! { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        color.setFill()
        bounds.fill()
    }
}

final class UnderBarIconView: NSImageView {
    var onLeft: (() -> Void)?
    var onRight: (() -> Void)?

    override func mouseDown(with event: NSEvent) { onLeft?() }
    override func rightMouseDown(with event: NSEvent) { onRight?() }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var acceptsFirstResponder: Bool { false }
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
    private var hoverSuppressed = false
    private var underBarPanel: NSPanel?
    private var underBarIconView: UnderBarIconView?
    private var underBarTintView: UnderBarTintView?
    private var underBarBlurView: NSVisualEffectView?
    private var externalItemViews: [String: UnderBarIconView] = [:]
    private var lastUnderBarTick = Date.distantPast
    private var itemsTimer: Timer?
    private var locationCancellable: AnyCancellable?
    private lazy var menuBarItemsManager = MenuBarItemsManager(settings: settings)

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
        applyIconLocation()
        locationCancellable = settings.$iconLocation.dropFirst().sink { [weak self] _ in
            Task { @MainActor in self?.applyIconLocation() }
        }
        let hoverTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateHoverState() }
        }
        RunLoop.main.add(hoverTimer, forMode: .common)
        self.hoverTimer = hoverTimer
        let itemsTimer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.menuBarItemsManager.tick()
                self.refreshUnderBarPresence()
            }
        }
        RunLoop.main.add(itemsTimer, forMode: .common)
        self.itemsTimer = itemsTimer
        menuBarItemsManager.tick()
        refreshUnderBarPresence()
        model.start { [weak self] in self?.refreshStatusItem() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuBarItemsManager.restoreAll()
    }

    @objc private func statusClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            hoverSuppressed = true
            hideDetailPanel()
            showStatusMenu()
        } else {
            handlePrimaryClick(at: statusBarClickPoint())
        }
    }

    private func underBarClicked(right: Bool) {
        if right {
            hoverSuppressed = true
            hideDetailPanel()
            showStatusMenu()
        } else {
            handlePrimaryClick(at: underBarClickPoint())
        }
    }

    private func showStatusMenu() {
        let menu = makeMenu()
        menu.delegate = self
        if settings.iconLocation == .underBar, let view = underBarIconView {
            menu.popUp(positioning: nil, at: NSPoint(x: view.bounds.maxX - 4, y: 2), in: view)
        } else {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
        }
    }

    private func handlePrimaryClick(at point: NSPoint?) {
        if let point, let tappedMetric = metricForClick(at: point) {
            model.select(tappedMetric)
            refreshStatusItem()
            return
        }
        showDetailPanel()
    }

    private func statusBarClickPoint() -> NSPoint? {
        guard let button = statusItem.button, let event = NSApp.currentEvent else { return nil }
        let localPoint = button.convert(event.locationInWindow, from: nil)
        return NSPoint(x: localPoint.x, y: button.bounds.height - localPoint.y)
    }

    private func underBarClickPoint() -> NSPoint? {
        guard let view = underBarIconView, let event = NSApp.currentEvent else { return nil }
        return view.convert(event.locationInWindow, from: nil)
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
            forceKillProcess: { [weak self] in self?.confirmForceKill(of: $0) },
            activateApp: { [weak self] in self?.activateApp($0) },
            openSettings: { [weak self] in self?.openSettings() }
        ))
        hosting.view.wantsLayer = true
        hosting.view.layer?.cornerRadius = 16
        hosting.view.layer?.masksToBounds = true
        panel.contentViewController = hosting
        detailPanel = panel
    }

    private func updateHoverState() {
        updateUnderBarTick()
        updateUnderBarStyle()
        guard settings.showOnHover else {
            if detailPanel?.isVisible == true { hideDetailPanel() }
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
        } else if detailPanel?.isVisible == true, Date().timeIntervalSince(lastPointerInside) > 0.3 {
            hideDetailPanel()
        }
    }

    private var statusButtonFrame: NSRect? {
        if settings.iconLocation == .underBar {
            guard let view = underBarIconView, let window = view.window, window.isVisible else { return nil }
            return window.convertToScreen(view.convert(view.bounds, to: nil))
        }
        guard let button = statusItem.button, let window = button.window else { return nil }
        return window.convertToScreen(button.convert(button.bounds, to: nil))
    }

    private func showDetailPanel() {
        guard settings.showPanel else { return }
        guard let panel = detailPanel, let buttonFrame = statusButtonFrame else { return }
        let screen = NSScreen.screens.first { $0.frame.intersects(buttonFrame) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? .zero
        let x = max(visible.minX + 8, min(buttonFrame.midX - panel.frame.width / 2, visible.maxX - panel.frame.width - 8))
        panel.setFrameOrigin(NSPoint(x: x, y: buttonFrame.minY - panel.frame.height - 6))
        panel.orderFrontRegardless()
    }

    private func hideDetailPanel() {
        detailPanel?.orderOut(nil)
    }

    private func applyIconLocation() {
        hideDetailPanel()
        refreshUnderBarPresence()
        refreshStatusItem()
    }

    private var underBarActive: Bool {
        settings.iconLocation == .underBar || !menuBarItemsManager.rendered.isEmpty
    }

    private func refreshUnderBarPresence() {
        statusItem.isVisible = settings.iconLocation == .menuBar
        if underBarActive {
            if underBarPanel == nil { setupUnderBar() }
            updateUnderBarTick(force: true)
        } else if let panel = underBarPanel, panel.isVisible {
            panel.orderOut(nil)
        }
    }

    private func setupUnderBar() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 22),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces]
        panel.hidesOnDeactivate = false
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 22))
        container.wantsLayer = true
        container.layer?.cornerRadius = 8
        container.layer?.masksToBounds = true
        let blur = NSVisualEffectView(frame: container.bounds)
        blur.material = .menu
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.autoresizingMask = [.width, .height]
        container.addSubview(blur)
        let tint = UnderBarTintView(frame: container.bounds)
        tint.autoresizingMask = [.width, .height]
        container.addSubview(tint)
        let icon = UnderBarIconView(frame: .zero)
        icon.toolTip = "PKMonitor — hover for details, right-click for menu"
        icon.setAccessibilityLabel("PKMonitor system activity")
        icon.onLeft = { [weak self] in self?.underBarClicked(right: false) }
        icon.onRight = { [weak self] in self?.underBarClicked(right: true) }
        container.addSubview(icon)
        panel.contentView = container
        underBarPanel = panel
        underBarIconView = icon
        underBarTintView = tint
        underBarBlurView = blur
    }

    private func updateUnderBarTick(force: Bool = false) {
        guard underBarActive, let panel = underBarPanel else { return }
        guard force || Date().timeIntervalSince(lastUnderBarTick) >= 1 else { return }
        lastUnderBarTick = Date()
        if isAnyAppFullscreen() {
            panel.orderOut(nil)
        } else {
            positionUnderBar(panel)
            if !panel.isVisible { panel.orderFrontRegardless() }
        }
    }

    private func updateUnderBarStyle() {
        guard underBarActive, let blur = underBarBlurView, let tint = underBarTintView else { return }
        let hovered = underBarPanel?.frame.contains(NSEvent.mouseLocation) == true
        switch settings.underBarBackground {
        case .transparent:
            blur.isHidden = true
            tint.isHidden = true
        case .color:
            blur.isHidden = true
            tint.isHidden = false
        case .hover:
            blur.isHidden = !hovered
            tint.isHidden = !hovered
        case .blur:
            blur.isHidden = false
            tint.isHidden = false
        }
    }

    private func positionUnderBar(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let frame = NSRect(x: screen.frame.maxX - panel.frame.width, y: screen.visibleFrame.maxY - panel.frame.height, width: panel.frame.width, height: panel.frame.height)
        if panel.frame != frame { panel.setFrame(frame, display: false) }
    }

    // ponytail: heuristique plein écran via CGWindowList (fenêtre couvrant un écran) ; revoir si un cas manque
    private func isAnyAppFullscreen() -> Bool {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else { return false }
        for info in list {
            guard info[kCGWindowLayer as String] as? Int == 0,
                  let bounds = info[kCGWindowBounds as String] as? [String: CGFloat] else { continue }
            let width = bounds["Width"] ?? 0
            let height = bounds["Height"] ?? 0
            if NSScreen.screens.contains(where: { abs($0.frame.width - width) < 2 && abs($0.frame.height - height) < 2 }) {
                return true
            }
        }
        return false
    }

    private func refreshStatusItem() {
        let panelAppearance: NSAppearance?
        switch settings.appearance {
        case .system: panelAppearance = nil
        case .light: panelAppearance = NSAppearance(named: .aqua)
        case .dark: panelAppearance = NSAppearance(named: .darkAqua)
        }
        detailPanel?.appearance = panelAppearance

        let under = settings.iconLocation == .underBar
        let contentAppearance: NSAppearance?
        if under {
            switch settings.underBarContent {
            case .system: contentAppearance = underBarPanel?.effectiveAppearance ?? NSApp.effectiveAppearance
            case .light: contentAppearance = NSAppearance(named: .aqua)
            case .dark: contentAppearance = NSAppearance(named: .darkAqua)
            }
            underBarPanel?.appearance = settings.underBarContent == .system ? nil : contentAppearance
        } else {
            contentAppearance = panelAppearance ?? NSApp.effectiveAppearance
        }

        var image = sparklineImage(model.samples, markers: model.markers, metric: model.displayedMetric, value: model.formatMenuBar())
        contentAppearance?.performAsCurrentDrawingAppearance {
            image = sparklineImage(model.samples, markers: model.markers, metric: model.displayedMetric, value: model.formatMenuBar())
        }

        if under {
            underBarIconView?.image = image
            underBarTintView?.color = NSColor(hex: settings.underBarColorHex) ?? NSColor.black.withAlphaComponent(0.1)
        } else if let button = statusItem.button {
            button.image = image
        }
        if underBarActive {
            layoutUnderBar(pill: under ? image : nil)
        }
        let prefix = model.selectedMetric == .auto ? "Auto · \(model.displayedMetric.rawValue)" : model.displayedMetric.rawValue
        statusItem.button?.title = ""
        statusItem.button?.setAccessibilityValue("\(prefix), \(model.format())")
    }

    private func layoutUnderBar(pill: NSImage?) {
        guard let panel = underBarPanel, let container = panel.contentView else { return }
        let top = CGFloat(settings.underBarPaddingTop)
        let bottom = CGFloat(settings.underBarPaddingBottom)
        let left = CGFloat(settings.underBarPaddingLeft)
        let right = CGFloat(settings.underBarPaddingRight)
        let ext = menuBarItemsManager.rendered

        for (id, view) in externalItemViews where !ext.contains(where: { $0.id == id }) {
            view.removeFromSuperview()
            externalItemViews[id] = nil
        }
        for item in ext where externalItemViews[item.id] == nil {
            let view = UnderBarIconView(frame: .zero)
            view.toolTip = item.appName
            view.setAccessibilityLabel("\(item.appName) menu bar item")
            view.onLeft = { [weak self] in self?.menuBarItemsManager.forwardClick(item.id) }
            view.onRight = view.onLeft
            container.addSubview(view)
            externalItemViews[item.id] = view
        }
        for item in ext { externalItemViews[item.id]?.image = item.image }

        let gap: CGFloat = 5
        let iconGap: CGFloat = 4
        let pillW = pill?.size.width ?? 0
        let pillH = pill?.size.height ?? 0
        let extW = ext.reduce(0) { $0 + $1.image.size.width } + (ext.isEmpty ? 0 : CGFloat(ext.count - 1) * iconGap)
        let contentH = max(pillH, ext.map(\.image.size.height).max() ?? 0)
        let width = left + pillW + (extW > 0 ? gap + extW : 0) + right
        let height = max(22, contentH + top + bottom)
        if panel.frame.size != NSSize(width: width, height: height), let screen = NSScreen.main {
            panel.setFrame(NSRect(x: screen.frame.maxX - width, y: screen.visibleFrame.maxY - height, width: width, height: height), display: false)
        }
        if let pillView = underBarIconView {
            pillView.isHidden = pill == nil
            if let pill {
                pillView.frame = NSRect(x: width - right - pill.size.width, y: bottom, width: pill.size.width, height: pill.size.height)
            }
        }
        var cursor = width - right - pillW - (extW > 0 ? gap : 0)
        for item in ext.reversed() {
            let w = item.image.size.width
            let h = item.image.size.height
            externalItemViews[item.id]?.frame = NSRect(x: cursor - w, y: (height - h) / 2, width: w, height: h)
            cursor -= w + iconGap
        }
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

    private func activateApp(_ app: AppUsage) {
        hideDetailPanel()
        if let bundle = Bundle(path: app.path), let id = bundle.bundleIdentifier {
            NSWorkspace.shared.open(URL(string: "app://\(id)")!)
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
        }
        let name = Bundle(path: app.path)?.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? URL(fileURLWithPath: app.path).deletingPathExtension().lastPathComponent
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let source = """
            tell application "System Events"
                set frontmost of process "\(name)" to true
            end tell
            """
            var error: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&error)
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
            let controller = NSHostingController(rootView: SettingsView(settings: settings, manager: menuBarItemsManager))
            let window = NSWindow(contentViewController: controller)
            window.title = "PKMonitor Settings"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 1040, height: 700))
            window.minSize = NSSize(width: 900, height: 620)
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
        let gap = CGFloat(settings.elementSpacing)
        let valueFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        let valueColor = settings.colorForValue(model.reading.value(for: metric))
        let valueAttrs: [NSAttributedString.Key: Any] = [.font: valueFont, .foregroundColor: valueColor]
        let valueSize = (value as NSString).size(withAttributes: valueAttrs)
        let textW = valueSize.width + gap * 2
        let labelW: CGFloat = settings.showSparkline && settings.showLabel ? 30 : 0
        let gaugeW: CGFloat = settings.showGauges ? CGFloat(settings.enabledGaugeMetrics.count) * (CGFloat(settings.gaugeWidth) + 2) + 2 : 0
        let graphW = settings.showSparkline ? settings.sparklineWidth : 0
        let totalWidth = textW + labelW + graphW + gaugeW
        let size = NSSize(width: totalWidth, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        let label = metric == .network ? "NET" : metric.rawValue.uppercased()
        let labelFont = NSFont.systemFont(ofSize: 6, weight: .heavy)
        let labelAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: NSColor.labelColor]
        let labelCharSize = ("M" as NSString).size(withAttributes: labelAttrs)
        let lineH: CGFloat = 5

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
            (value as NSString).draw(at: NSPoint(x: valueX + textW - valueSize.width - gap, y: (size.height - valueSize.height) / 2), withAttributes: valueAttrs)
        } else {
            (value as NSString).draw(at: NSPoint(x: valueX + gap, y: (size.height - valueSize.height) / 2), withAttributes: valueAttrs)
        }

        if settings.showLabel {
            for (index, character) in label.enumerated() {
                let lx = labelOnLeft ? labelStartX + 2 : labelStartX + 2
                String(character).draw(at: NSPoint(x: lx, y: size.height - labelCharSize.height - CGFloat(index) * lineH), withAttributes: labelAttrs)
            }
        }

        guard values.count > 1 else { return image }

        let rect = NSRect(origin: .zero, size: size)
        let sparkMargin: CGFloat = 8
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
            let gaugeMetrics = settings.enabledGaugeMetrics
            let gW = CGFloat(settings.gaugeWidth)
            let gGap: CGFloat = 2
            let gFont = NSFont.monospacedDigitSystemFont(ofSize: 6, weight: .heavy)
            let gAttrs: [NSAttributedString.Key: Any] = [.font: gFont, .foregroundColor: NSColor.secondaryLabelColor]
            let gActiveAttrs: [NSAttributedString.Key: Any] = [.font: gFont, .foregroundColor: NSColor.labelColor]
            let tagFont = NSFont.systemFont(ofSize: 5, weight: .heavy)
            let tagAttrs: [NSAttributedString.Key: Any] = [.font: tagFont, .foregroundColor: NSColor.tertiaryLabelColor]
            var newGaugeRects: [Metric: NSRect] = [:]

            for (i, m) in gaugeMetrics.enumerated() {
                let gx = gaugeStartX + 2 + CGFloat(i) * (gW + gGap)
                let gRect = NSRect(x: gx, y: 1, width: gW, height: size.height - 2)
                newGaugeRects[m] = gRect

                let isActive = m == metric
                let bg = gRect.insetBy(dx: 1, dy: 1)

                if m == .disk {
                    let diskFont = NSFont.monospacedDigitSystemFont(ofSize: 5.5, weight: isActive ? .bold : .medium)
                    let totalText = MonitorModel.formatBytes(Double(model.reading.totalDisk))
                    let freeText = MonitorModel.formatBytes(Double(model.reading.freeDisk))
                    let totalAttrs: [NSAttributedString.Key: Any] = [.font: diskFont, .foregroundColor: NSColor.systemRed]
                    let freeAttrs: [NSAttributedString.Key: Any] = [.font: diskFont, .foregroundColor: NSColor.systemBlue]
                    let totalSize = (totalText as NSString).size(withAttributes: totalAttrs)
                    let freeSize = (freeText as NSString).size(withAttributes: freeAttrs)
                    (totalText as NSString).draw(at: NSPoint(x: gx + (gW - totalSize.width) / 2, y: bg.midY + 1), withAttributes: totalAttrs)
                    (freeText as NSString).draw(at: NSPoint(x: gx + (gW - freeSize.width) / 2, y: bg.minY + 1), withAttributes: freeAttrs)
                    if isActive {
                        NSColor.labelColor.setStroke()
                        NSBezierPath(roundedRect: bg, xRadius: 2, yRadius: 2).stroke()
                    }
                    continue
                }

                NSColor.separatorColor.setFill()
                NSBezierPath(roundedRect: bg, xRadius: 2, yRadius: 2).fill()

                if m == .network {
                    let maxNet: CGFloat = 10_000_000
                    let dlFill = CGFloat(max(0, min(1, model.reading.download / maxNet)))
                    let ulFill = CGFloat(max(0, min(1, model.reading.upload / maxNet)))
                    let halfH = bg.height / 2
                    let midY = bg.minY + halfH

                    let dlH = halfH * dlFill
                    let dlR = NSRect(x: bg.minX, y: midY - dlH, width: bg.width, height: dlH)
                    let ulH = halfH * ulFill
                    let ulR = NSRect(x: bg.minX, y: midY, width: bg.width, height: ulH)

                    NSColor.systemBlue.setFill()
                    NSBezierPath(roundedRect: dlR, xRadius: 2, yRadius: 2).fill()
                    NSColor.systemOrange.setFill()
                    NSBezierPath(roundedRect: ulR, xRadius: 2, yRadius: 2).fill()

                    if isActive {
                        NSColor.labelColor.setStroke()
                        NSBezierPath(roundedRect: bg, xRadius: 2, yRadius: 2).stroke()
                    }
                } else {
                    let fill = CGFloat(max(0, min(1, model.reading.value(for: m) / 100)))
                    let fillH = bg.height * fill
                    let fillR = NSRect(x: bg.minX, y: bg.minY, width: bg.width, height: fillH)
                    let gColor = settings.colorForValue(model.reading.value(for: m))
                    gColor.setFill()
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

                let letter: String = {
                    switch m {
                    case .gpu: return "G"
                    case .cpu: return "C"
                    case .ram: return "R"
                    case .disk: return "D"
                    case .network: return "N"
                    default: return ""
                    }
                }()
                let letterSize = (letter as NSString).size(withAttributes: tagAttrs)
                (letter as NSString).draw(at: NSPoint(x: gx + (gW - letterSize.width) / 2, y: 2), withAttributes: tagAttrs)
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
            assert(MonitorModel.formatBytes(999) == "999 o")
            assert(MonitorModel.formatBytes(1_500) == "2 Ko")
            assert(MonitorModel.formatBytes(1_500_000) == "2 Mo")
            assert(MonitorModel.appName(from: "/Applications/Safari.app/Contents/MacOS/Safari") == "Safari")
            assert(MonitorModel.appBundlePath(from: "/Applications/Safari.app/Contents/MacOS/Safari") == "/Applications/Safari.app")
            let scaled = MonitorModel.scaledHistory([0.7, 0.71])
            assert(abs(scaled[0] - 0.12) < 0.001 && abs(scaled[1] - 0.88) < 0.001)
            assert(IconLocation(rawValue: "Second Bar") == .underBar)
            assert(IconLocation(rawValue: "Menu Bar") == .menuBar)
            assert(AppSettings.parseIDs("a|1,b|2,") == ["a|1", "b|2"])
            assert(AppSettings.parseIDs("") == [])
            let baseID = MenuBarItemsManager.stableID(bundle: "com.x.y", appName: "X", title: "Wi-Fi", index: 0, existing: [])
            assert(baseID == "com.x.y|Wi-Fi")
            assert(MenuBarItemsManager.stableID(bundle: "com.x.y", appName: "X", title: "Wi-Fi", index: 1, existing: [baseID]) != baseID)
            assert(NSColor(hex: "#FF000080")?.alphaComponent ?? 0 < 0.51)
            assert(NSColor(hex: "#FF000080")?.redComponent ?? 0 > 0.99)
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
