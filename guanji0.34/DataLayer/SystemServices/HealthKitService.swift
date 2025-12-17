import Foundation
#if canImport(HealthKit)
import HealthKit
public final class HealthKitService {
    private let store = HKHealthStore()
    public init() {}
    public var isAvailable: Bool {
        if #available(iOS 18.0, *) { return HKHealthStore.isHealthDataAvailable() } else { return false }
    }
    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard isAvailable else { completion(false); return }
        if #available(iOS 18.0, *) {
            let types: Set<HKSampleType> = []
            store.requestAuthorization(toShare: types, read: types) { ok, _ in completion(ok) }
        } else { completion(false) }
    }
}
#else
public final class HealthKitService {
    public init() {}
    public var isAvailable: Bool { false }
    public func requestAuthorization(completion: @escaping (Bool) -> Void) { completion(false) }
}
#endif
