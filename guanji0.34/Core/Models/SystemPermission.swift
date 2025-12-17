import Foundation

public enum LocationAuthStatus: String, Codable {
    case notDetermined
    case restricted
    case denied
    case authorized
}

