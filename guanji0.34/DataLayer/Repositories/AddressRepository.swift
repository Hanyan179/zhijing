import Foundation

public final class AddressRepository {
    private struct Store: Codable { let mappings: [AddressMapping]; let fences: [AddressFence] }
    private var url: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Addresses.json")
    }
    public init() {}
    public func load() -> (mappings: [AddressMapping], fences: [AddressFence])? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let store = try? JSONDecoder().decode(Store.self, from: data) else { return nil }
        return (store.mappings, store.fences)
    }
    public func save(mappings: [AddressMapping], fences: [AddressFence]) {
        let store = Store(mappings: mappings, fences: fences)
        if let data = try? JSONEncoder().encode(store) { try? data.write(to: url) }
    }
}
