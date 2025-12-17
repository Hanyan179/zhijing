import Foundation

public final class LocationRepository {
    public static let shared = LocationRepository()
    private let mappingsKey = "gj_location_mappings"
    private let fencesKey = "gj_location_fences"
    private let fileStore = AddressRepository()
    private init() { load() }

    public private(set) var mappings: [AddressMapping] = []
    public private(set) var fences: [AddressFence] = []

    private func load() {
        if let t = fileStore.load() {
            mappings = t.mappings
            fences = t.fences
        } else {
            if let md = UserDefaults.standard.data(forKey: mappingsKey), let arr = try? JSONDecoder().decode([AddressMapping].self, from: md) { mappings = arr }
            if let fd = UserDefaults.standard.data(forKey: fencesKey), let arr = try? JSONDecoder().decode([AddressFence].self, from: fd) { fences = arr }
        }
        
        if mappings.isEmpty {
            seedMockData()
        }
    }
    
    private func seedMockData() {
        print("Seeding Location Data from MockService...")
        self.mappings = MockDataService.mappings
        self.fences = MockDataService.fences
        save()
    }
    
    private func save() {
        fileStore.save(mappings: mappings, fences: fences)
        NotificationCenter.default.post(name: Notification.Name("gj_addresses_changed"), object: nil)
    }

    // MARK: - CRUD Operations
    
    public func updateMapping(id: String, name: String? = nil, icon: String? = nil, color: String? = nil) {
        if let idx = mappings.firstIndex(where: { $0.id == id }) {
            var m = mappings[idx]
            if let n = name { m = AddressMapping(id: m.id, userId: m.userId, name: n, icon: m.icon, color: m.color) }
            if let i = icon { m = AddressMapping(id: m.id, userId: m.userId, name: m.name, icon: i, color: m.color) }
            if let c = color { m = AddressMapping(id: m.id, userId: m.userId, name: m.name, icon: m.icon, color: c) }
            mappings[idx] = m
            save()
        }
    }
    
    public func deleteMapping(id: String) {
        mappings.removeAll(where: { $0.id == id })
        fences.removeAll(where: { $0.mappingId == id })
        save()
    }
    
    public func updateFenceRadius(fenceId: String, radius: Double) {
        if let idx = fences.firstIndex(where: { $0.id == fenceId }) {
            let f = fences[idx]
            fences[idx] = AddressFence(id: f.id, mappingId: f.mappingId, lat: f.lat, lng: f.lng, radius: radius, originalRawName: f.originalRawName)
            save()
        }
    }
    
    public func deleteFence(fenceId: String) {
        fences.removeAll(where: { $0.id == fenceId })
        save()
    }
    
    public func addMapping(name: String, icon: String? = nil, color: String? = nil) -> AddressMapping {
        let id = "m_" + String(Int(Date().timeIntervalSince1970))
        let m = AddressMapping(id: id, userId: "u_1", name: name, icon: icon, color: color)
        mappings.append(m)
        save()
        return m
    }

    public func reload() {
        if let t = fileStore.load() {
            mappings = t.mappings
            fences = t.fences
        }
    }

    public func addMappingAndFence(name: String, icon: String?, color: String?, lat: Double, lng: Double, rawName: String?, radius: Double = 150) -> AddressMapping {
        if let existing = findMapping(byName: name) {
            // Update icon/color if provided
            if icon != nil || color != nil {
                updateMapping(id: existing.id, name: name, icon: icon, color: color)
            }
            _ = addFence(mappingId: existing.id, lat: lat, lng: lng, rawName: rawName ?? "-", radius: radius)
            // Return updated mapping
            return findMapping(byName: name) ?? existing
        } else {
            let mid = "map_" + UUID().uuidString
            let m = AddressMapping(id: mid, userId: "user_1", name: name, icon: icon, color: color)
            mappings.append(m)
            let f = AddressFence(id: "fence_" + UUID().uuidString, mappingId: mid, lat: lat, lng: lng, radius: radius, originalRawName: rawName ?? "-")
            fences.append(f)
            save()
            return m
        }
    }

    public func suggestMappings(lat: Double, lng: Double) -> [AddressMapping] {
        guard isWithinOperationalBounds(lat: lat, lng: lng) else { return [] }
        var hits: [AddressMapping] = []
        for f in fences {
            let approxMeters = hypot((f.lat - lat) * 111_000, (f.lng - lng) * 111_000)
            if approxMeters <= f.radius { if let m = mappings.first(where: { $0.id == f.mappingId }) { hits.append(m) } }
        }
        return hits
    }

    public func findMapping(byName name: String) -> AddressMapping? {
        mappings.first { $0.name == name }
    }

    @discardableResult
    public func addFence(mappingId: String, lat: Double, lng: Double, rawName: String, radius: Double = 150) -> AddressFence {
        let f = AddressFence(id: "fence_" + UUID().uuidString, mappingId: mappingId, lat: lat, lng: lng, radius: radius, originalRawName: rawName)
        fences.append(f)
        save()
        return f
    }

    public func validate() -> [String] {
        var issues: [String] = []
        for f in fences {
            if mappings.first(where: { $0.id == f.mappingId }) == nil { issues.append("FenceMissingMapping:\\(f.id)") }
            if !(abs(f.lat) <= 90 && abs(f.lng) <= 180) { issues.append("FenceCoordOutOfWorldRange:\\(f.id)") }
            if f.radius <= 0 { issues.append("FenceRadiusInvalid:\\(f.id)") }
        }
        if let b = operationalBounds(marginDegrees: 0.1) {
            for f in fences {
                if !(f.lat >= b.minLat && f.lat <= b.maxLat && f.lng >= b.minLng && f.lng <= b.maxLng) {
                    issues.append("FenceOutOfOperationalBounds:\\(f.id)")
                }
            }
        }
        let names = mappings.map { $0.name }
        let dupNames = Set(names.filter { name in names.filter { $0 == name }.count > 1 })
        if !dupNames.isEmpty { issues.append("DuplicateMappingNames:\\(Array(dupNames))") }
        return issues
    }

    public func operationalBounds(marginDegrees: Double = 0.05) -> (minLat: Double, maxLat: Double, minLng: Double, maxLng: Double)? {
        guard !fences.isEmpty else { return nil }
        var minLat = fences.first!.lat
        var maxLat = fences.first!.lat
        var minLng = fences.first!.lng
        var maxLng = fences.first!.lng
        for f in fences {
            minLat = min(minLat, f.lat)
            maxLat = max(maxLat, f.lat)
            minLng = min(minLng, f.lng)
            maxLng = max(maxLng, f.lng)
        }
        return (minLat - marginDegrees, maxLat + marginDegrees, minLng - marginDegrees, maxLng + marginDegrees)
    }

    public func isWithinOperationalBounds(lat: Double, lng: Double) -> Bool {
        if let b = operationalBounds(marginDegrees: 0.05) {
            return lat >= b.minLat && lat <= b.maxLat && lng >= b.minLng && lng <= b.maxLng
        }
        return abs(lat) <= 90 && abs(lng) <= 180
    }
}
