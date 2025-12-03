import SwiftUI
import Combine
import Foundation
import Photos
import AVFoundation

public enum ProfileViewState { case main, privacy, notifications, membership, about, subscriptionInfo, dataMaintenance, locationList, locationDetail, componentGallery }

public final class ProfileViewModel: ObservableObject {
    @Published public var view: ProfileViewState = .main
    @Published public var userPlan: String = "base"
    @Published public var analyticsEnabled: Bool = true
    @Published public var crashReportsEnabled: Bool = true
    @Published public var locationServicesEnabled: Bool = true
    @Published public var selectedMapping: AddressMapping? = nil
    @Published public var pushEnabled: Bool = true
    @Published public var soundEnabled: Bool = true
    @Published public var badgeEnabled: Bool = true
    @Published public var dailyReminderEnabled: Bool = false
    @Published public var reminderTime: String = "08:00"
    @Published public var addressMappings: [AddressMapping] = MockDataService.mappings
    @Published public var addressFences: [AddressFence] = MockDataService.fences
    @Published public var photoEnabled: Bool = PermissionsService.photoEnabled
    @Published public var cameraEnabled: Bool = PermissionsService.cameraEnabled
    @Published public var micEnabled: Bool = false
    public init() {}

    public func bindPermissions() {
        PermissionsService.photoEnabled = photoEnabled
        PermissionsService.cameraEnabled = cameraEnabled
    }

    public func updateMappingName(id: String, name: String) {
        if let idx = addressMappings.firstIndex(where: { $0.id == id }) {
            let m = addressMappings[idx]
            addressMappings[idx] = AddressMapping(id: m.id, userId: m.userId, name: name, icon: m.icon, color: m.color)
            if selectedMapping?.id == id { selectedMapping = addressMappings[idx] }
        }
    }

    public func updateMappingIcon(id: String, icon: String) {
        if let idx = addressMappings.firstIndex(where: { $0.id == id }) {
            let m = addressMappings[idx]
            addressMappings[idx] = AddressMapping(id: m.id, userId: m.userId, name: m.name, icon: icon, color: m.color)
            if selectedMapping?.id == id { selectedMapping = addressMappings[idx] }
        }
    }

    public func updateMappingColor(id: String, color: String) {
        if let idx = addressMappings.firstIndex(where: { $0.id == id }) {
            let m = addressMappings[idx]
            addressMappings[idx] = AddressMapping(id: m.id, userId: m.userId, name: m.name, icon: m.icon, color: color)
            if selectedMapping?.id == id { selectedMapping = addressMappings[idx] }
        }
    }

    public func deleteMapping(id: String) {
        addressMappings.removeAll(where: { $0.id == id })
        addressFences.removeAll(where: { $0.mappingId == id })
        if selectedMapping?.id == id { selectedMapping = nil }
    }

    public func updateFenceRadius(fenceId: String, radius: Double) {
        if let idx = addressFences.firstIndex(where: { $0.id == fenceId }) {
            let f = addressFences[idx]
            addressFences[idx] = AddressFence(id: f.id, mappingId: f.mappingId, lat: f.lat, lng: f.lng, radius: radius, originalRawName: f.originalRawName)
        }
    }

    public func deleteFence(fenceId: String) {
        addressFences.removeAll(where: { $0.id == fenceId })
    }
}
