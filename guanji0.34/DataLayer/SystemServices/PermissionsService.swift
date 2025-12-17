import Foundation
import Photos
import AVFoundation
import CoreLocation

public enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
    case restricted
    case limited // Photos only
}

public final class PermissionsService: NSObject, CLLocationManagerDelegate {
    public static let shared = PermissionsService()
    
    private let locationManager = CLLocationManager()
    
    // Callbacks for location updates
    public var onLocationAuthChange: ((PermissionStatus) -> Void)?
    
    private override init() {
        super.init()
        locationManager.delegate = self
    }
    
    // MARK: - Photo Library
    public var photoStatus: PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized: return .authorized
        case .limited: return .limited
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }
    
    public func requestPhotoAccess(completion: @escaping (PermissionStatus) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized: completion(.authorized)
                case .limited: completion(.limited)
                case .denied: completion(.denied)
                case .restricted: completion(.restricted)
                case .notDetermined: completion(.notDetermined)
                @unknown default: completion(.denied)
                }
            }
        }
    }
    
    // MARK: - Camera
    public var cameraStatus: PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }
    
    public func requestCameraAccess(completion: @escaping (PermissionStatus) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted ? .authorized : .denied)
            }
        }
    }
    
    // MARK: - Microphone
    public var micStatus: PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }
    
    public func requestMicAccess(completion: @escaping (PermissionStatus) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                completion(granted ? .authorized : .denied)
            }
        }
    }
    
    // MARK: - Location
    public var locationStatus: PermissionStatus {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }
    
    public func requestLocationAccess() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onLocationAuthChange?(locationStatus)
    }
}
