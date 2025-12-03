import Foundation
import Photos
import AVFoundation

public enum PermissionsService {
    private static let photoKey = "perm_photo_enabled"
    private static let cameraKey = "perm_camera_enabled"

    public static var photoEnabled: Bool {
        get { UserDefaults.standard.object(forKey: photoKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: photoKey) }
    }
    public static var cameraEnabled: Bool {
        get { UserDefaults.standard.object(forKey: cameraKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: cameraKey) }
    }

    public static func ensurePhotoAuthorized(completion: @escaping (Bool) -> Void) {
        guard photoEnabled else { completion(false); return }
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited: completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { s in
                DispatchQueue.main.async { completion(s == .authorized || s == .limited) }
            }
        default: completion(false)
        }
    }

    public static func ensureCameraAuthorized(completion: @escaping (Bool) -> Void) {
        guard cameraEnabled else { completion(false); return }
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized: completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default: completion(false)
        }
    }
}
