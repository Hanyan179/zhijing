import SwiftUI
import Combine
import Foundation
import Photos
import AVFoundation

public enum ProfileViewState { case main, privacy, notifications, membership, about, subscriptionInfo, dataMaintenance, locationList, locationDetail }

public final class ProfileViewModel: ObservableObject {
    @Published public var view: ProfileViewState = .main
    @Published public var userPlan: String = "base"
    @Published public var analyticsEnabled: Bool = true
    @Published public var crashReportsEnabled: Bool = true
    @Published public var selectedMapping: AddressMapping? = nil
    
    // Notification Preferences
    @Published public var pushEnabled: Bool {
        didSet { UserDefaults.standard.set(pushEnabled, forKey: "pref_push_enabled") }
    }
    @Published public var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "pref_sound_enabled") }
    }
    @Published public var badgeEnabled: Bool {
        didSet { UserDefaults.standard.set(badgeEnabled, forKey: "pref_badge_enabled") }
    }
    @Published public var dailyReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(dailyReminderEnabled, forKey: "pref_daily_reminder_enabled") }
    }
    @Published public var reminderTime: String {
        didSet { UserDefaults.standard.set(reminderTime, forKey: "pref_reminder_time") }
    }
    
    // Day End Time (Daily Cutoff)
    @Published public var dayEndTime: String {
        didSet {
            UserDefaults.standard.set(dayEndTime, forKey: "pref_day_end_time")
            NotificationCenter.default.post(name: Notification.Name("gj_day_end_time_changed"), object: nil)
        }
    }
    
    @Published public var addressMappings: [AddressMapping] = []
    @Published public var addressFences: [AddressFence] = []
    
    // We no longer track permission status here for toggles. 
    // Permissions are handled JIT (Just-In-Time) by the specific features (InputDock, LocationService).

    public init() {
        self.pushEnabled = UserDefaults.standard.object(forKey: "pref_push_enabled") as? Bool ?? true
        self.soundEnabled = UserDefaults.standard.object(forKey: "pref_sound_enabled") as? Bool ?? true
        self.badgeEnabled = UserDefaults.standard.object(forKey: "pref_badge_enabled") as? Bool ?? true
        self.dailyReminderEnabled = UserDefaults.standard.bool(forKey: "pref_daily_reminder_enabled")
        self.reminderTime = UserDefaults.standard.string(forKey: "pref_reminder_time") ?? "08:00"
        self.dayEndTime = UserDefaults.standard.string(forKey: "pref_day_end_time") ?? "00:00"
        
        loadAddresses()
        NotificationCenter.default.addObserver(self, selector: #selector(onAddressChanged), name: Notification.Name("gj_addresses_changed"), object: nil)
    }
    
    @objc private func onAddressChanged() {
        loadAddresses()
    }
    
    public func loadAddresses() {
        LocationRepository.shared.reload()
        self.addressMappings = LocationRepository.shared.mappings
        self.addressFences = LocationRepository.shared.fences
        
        // Refresh selectedMapping if it exists, to ensure UI reflects changes immediately
        if let sm = selectedMapping {
            if let fresh = self.addressMappings.first(where: { $0.id == sm.id }) {
                self.selectedMapping = fresh
            }
        }
    }
    
    private func persist() {
        // No-op in VM, Repo handles persistence
    }

    public func updateMappingName(id: String, name: String) {
        LocationRepository.shared.updateMapping(id: id, name: name)
    }

    public func updateMappingIcon(id: String, icon: String) {
        LocationRepository.shared.updateMapping(id: id, icon: icon)
    }

    public func updateMappingColor(id: String, color: String) {
        LocationRepository.shared.updateMapping(id: id, color: color)
    }

    public func deleteMapping(id: String) {
        LocationRepository.shared.deleteMapping(id: id)
        if selectedMapping?.id == id { selectedMapping = nil }
    }

    public func updateFenceRadius(fenceId: String, radius: Double) {
        LocationRepository.shared.updateFenceRadius(fenceId: fenceId, radius: radius)
    }

    public func deleteFence(fenceId: String) {
        LocationRepository.shared.deleteFence(fenceId: fenceId)
    }

    public func addFence(for mappingId: String, name: String, lat: Double, lng: Double) {
        LocationRepository.shared.addFence(mappingId: mappingId, lat: lat, lng: lng, rawName: name, radius: 100)
    }

    public func addMapping(name: String) {
        _ = LocationRepository.shared.addMapping(name: name)
    }

    public func addAndSelectMapping(name: String) {
        let suggestion = suggestIconColor(for: name)
        let m = LocationRepository.shared.addMapping(name: name, icon: suggestion.icon, color: suggestion.color)
        selectedMapping = m
    }

    public func suggestIconColor(for name: String) -> (icon: String, color: String) {
        let lower = name.lowercased()
        if lower.contains("家") || lower.contains("home") { return ("home", "slate") }
        if lower.contains("公司") || lower.contains("work") || lower.contains("office") { return ("briefcase", "indigo") }
        if lower.contains("学校") || lower.contains("school") || lower.contains("university") { return ("graduation", "blue") }
        if lower.contains("健身") || lower.contains("gym") || lower.contains("fitness") { return ("bag", "emerald") }
        if lower.contains("公园") || lower.contains("park") || lower.contains("tree") { return ("tree", "teal") }
        if lower.contains("机场") || lower.contains("airport") || lower.contains("飞") { return ("airplane", "sky") }
        if lower.contains("酒店") || lower.contains("hotel") || lower.contains("睡") { return ("bed", "violet") }
        if lower.contains("餐") || lower.contains("饭") || lower.contains("bar") || lower.contains("餐厅") { return ("food", "orange") }
        return ("building", "rose")
    }
}
