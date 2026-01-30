import Foundation


public enum DynamicIslandSupport {
    public static func hasDynamicIsland() -> Bool {
        let id = modelIdentifier()
        let ids: Set<String> = [
            "iPhone15,2", "iPhone15,3",
            "iPhone15,4", "iPhone15,5",
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4", "iPhone17,5",
            "iPhone18,1", "iPhone18,2", "iPhone18,3", "iPhone18,4"
        ]
        if ids.contains(id) { return true }
        if ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"].flatMap({ ids.contains($0) }) == true { return true }
        return false
    }

    private static func modelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        return mirror.children.reduce("") { acc, child in
            guard let v = child.value as? Int8, v != 0 else { return acc }
            return acc + String(UnicodeScalar(UInt8(v)))
        }
    }
}
