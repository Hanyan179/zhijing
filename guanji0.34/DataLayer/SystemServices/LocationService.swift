import Foundation
import CoreLocation
import Combine

public final class LocationService: NSObject, CLLocationManagerDelegate {
    public static let shared = LocationService()
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var completion: ((Double, Double, String?) -> Void)?
    public var onAuthChange: ((LocationAuthStatus) -> Void)?
    
    // Continuous updates
    public let locationPublisher = PassthroughSubject<CLLocation, Never>()
    public let regionExitPublisher = PassthroughSubject<CLRegion, Never>()
    public var lastKnownLocation: CLLocation?
    private var isMonitoring = false

    private override init() { 
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        manager.startUpdatingLocation()
        manager.startMonitoringSignificantLocationChanges() // Backup wake-up
    }
    
    public func stopMonitoring() {
        isMonitoring = false
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
    }
    
    public func startRegionMonitoring(region: CLRegion) {
        manager.startMonitoring(for: region)
    }
    
    public func stopRegionMonitoring(region: CLRegion) {
        manager.stopMonitoring(for: region)
    }

    public func currentStatus() -> LocationAuthStatus {
        // Use instance property to avoid main thread warning
        // Note: We no longer call CLLocationManager.locationServicesEnabled() as it can block the main thread.
        // The authorizationStatus already reflects the appropriate state when location services are disabled.
        let status = manager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        default: return .notDetermined
        }
    }

    public func requestAuthorization() {
        manager.requestAlwaysAuthorization()
    }
    
    public func resolveAddress(location: CLLocation, completion: @escaping (String?) -> Void) {
        // Use a local instance to ensure thread safety and avoid state conflicts
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                print("[LocationService] Reverse geocoding failed: \(error.localizedDescription)")
                completion(nil)
                return
            }
            let name = self?.formatPlacemark(placemarks?.first)
            completion(name)
        }
    }

    public func requestCurrentSnapshot(_ completion: @escaping (Double, Double, String?) -> Void) {
        self.completion = completion
        let st = currentStatus()
        if st == .notDetermined { manager.requestWhenInUseAuthorization(); return }
        if st == .authorized { manager.requestLocation() } else { completion(0, 0, nil) }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        self.lastKnownLocation = loc
        
        // Continuous tracking
        locationPublisher.send(loc)
        
        // One-shot snapshot
        if let comp = completion {
            resolveAddress(location: loc) { name in
                comp(loc.coordinate.latitude, loc.coordinate.longitude, name)
                self.completion = nil
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // System wakes us up here
        regionExitPublisher.send(region)
        // Ensure we resume high-precision tracking
        if !isMonitoring {
            startMonitoring()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(0, 0, nil)
        completion = nil
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthChange?(currentStatus())
    }

    private func formatPlacemark(_ p: CLPlacemark?) -> String? {
        guard let p = p else { return nil }
        // Try detailed address first
        let parts: [String?] = [p.administrativeArea, p.locality, p.subLocality, p.thoroughfare, p.subThoroughfare]
        let text = parts.compactMap { $0 }.joined(separator: " ")
        
        if !text.isEmpty { return text }
        
        // Fallback to name (usually "Apple Park" or landmark name)
        if let n = p.name, !n.isEmpty { return n }
        
        // Fallback to broader regions
        return p.locality ?? p.administrativeArea
    }

    public func suggestMappings(lat: Double, lng: Double) -> [AddressMapping] {
        var hits: [AddressMapping] = []
        for f in LocationRepository.shared.fences {
            let dlat = f.lat - lat
            let dlng = f.lng - lng
            let approxMeters = hypot(dlat * 111_000, dlng * 111_000)
            if approxMeters <= f.radius {
                if let m = LocationRepository.shared.mappings.first(where: { $0.id == f.mappingId }) { hits.append(m) }
            }
        }
        return hits
    }
}
