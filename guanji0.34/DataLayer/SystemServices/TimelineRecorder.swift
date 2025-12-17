import Foundation
import CoreLocation
import Combine

public final class TimelineRecorder {
    public static let shared = TimelineRecorder()
    
    // MARK: - Configuration
    // User requested: "Leave range + move for a while" -> Journey
    // "Stop moving + stay for a while" -> Scene
    private let stationaryRadius: Double = 100.0 // meters
    private let movingDurationThreshold: TimeInterval = 120 // 2 minutes
    private let stationaryDurationThreshold: TimeInterval = 300 // 5 minutes
    
    // MARK: - State
    private var cancellables = Set<AnyCancellable>()
    private var lastKnownLocation: CLLocation?
    
    // State Machine
    private enum RecorderState {
        case unknown
        case stationary(center: CLLocation, startTime: Date)
        case moving(startTime: Date)
    }
    
    private var currentState: RecorderState = .unknown {
        didSet {
            handleStateChange(from: oldValue, to: currentState)
        }
    }
    
    // Transition Buffers
    private var potentialJourneyStart: Date? // When we first left the circle
    private var potentialSceneStart: Date? // When we first stopped/clustered
    private var potentialSceneCenter: CLLocation?
    
    private init() {
        setupSubscriptions()
    }
    
    public func startRecording() {
        LocationService.shared.startMonitoring()
        print("[TimelineRecorder] Started monitoring.")
    }
    
    public func stopRecording() {
        LocationService.shared.stopMonitoring()
        print("[TimelineRecorder] Stopped monitoring.")
    }
    
    private func setupSubscriptions() {
        LocationService.shared.locationPublisher
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)
            
        LocationService.shared.regionExitPublisher
            .sink { [weak self] region in
                // If we exit the region, we should probably wake up and check logic
                // The main update comes from locationPublisher (triggered by startMonitoring in didExitRegion)
                print("[TimelineRecorder] Woke up by region exit: \(region.identifier)")
            }
            .store(in: &cancellables)
    }
    
    private func handleStateChange(from old: RecorderState, to new: RecorderState) {
        // Clean up old state monitoring
        if case .stationary(let center, _) = old {
            let region = CLCircularRegion(center: center.coordinate, radius: stationaryRadius, identifier: "current_stay")
            LocationService.shared.stopRegionMonitoring(region: region)
        }
        
        // Setup new state monitoring
        if case .stationary(let center, _) = new {
            // Monitor this region so if app dies, exit wakes it up
            let region = CLCircularRegion(center: center.coordinate, radius: stationaryRadius, identifier: "current_stay")
            region.notifyOnExit = true
            region.notifyOnEntry = false
            LocationService.shared.startRegionMonitoring(region: region)
        }
    }
    
    private func handleLocationUpdate(_ location: CLLocation) {
        lastKnownLocation = location
        
        // Initialize state if needed
        if case .unknown = currentState {
            initializeState(with: location)
            return
        }
        
        switch currentState {
        case .stationary(let center, _):
            checkIfJourneyStarted(currentLocation: location, center: center)
            
        case .moving:
            checkIfSceneStarted(currentLocation: location)
            
        case .unknown:
            break
        }
    }
    
    private func initializeState(with location: CLLocation) {
        // Try to sync with existing Timeline data
        let today = DateUtilities.today
        let timeline = TimelineRepository.shared.getDailyTimeline(for: today)
        let items = timeline.items
        
        if let lastItem = items.last {
            switch lastItem {
            case .scene(let s):
                let center = CLLocation(latitude: s.location.snapshot.lat, longitude: s.location.snapshot.lng)
                currentState = .stationary(center: center, startTime: Date()) // Approximate start
                print("[TimelineRecorder] Init: Resuming Stationary state from last scene.")
            case .journey:
                currentState = .moving(startTime: Date())
                print("[TimelineRecorder] Init: Resuming Moving state from last journey.")
            }
        } else {
            // No data today, start a new Scene immediately
            createNewScene(at: location)
            currentState = .stationary(center: location, startTime: Date())
            print("[TimelineRecorder] Init: Created initial scene.")
        }
    }
    
    // MARK: - Logic: Scene -> Journey
    private func checkIfJourneyStarted(currentLocation: CLLocation, center: CLLocation) {
        let distance = currentLocation.distance(from: center)
        
        if distance > stationaryRadius {
            // We are outside the radius
            if let start = potentialJourneyStart {
                // We have been outside for a while?
                if Date().timeIntervalSince(start) >= movingDurationThreshold {
                    // CONFIRMED: Switch to Journey
                    print("[TimelineRecorder] Threshold passed. Switching to Journey.")
                    createNewJourney(from: center, to: currentLocation)
                    currentState = .moving(startTime: Date())
                    potentialJourneyStart = nil
                }
            } else {
                // First time outside
                potentialJourneyStart = Date()
                print("[TimelineRecorder] Left radius. Potential journey started at \(Date()).")
            }
        } else {
            // We are back inside/still inside
            if potentialJourneyStart != nil {
                print("[TimelineRecorder] Returned to radius. False alarm.")
                potentialJourneyStart = nil
            }
        }
    }
    
    // MARK: - Logic: Journey -> Scene
    private func checkIfSceneStarted(currentLocation: CLLocation) {
        // We are moving. We need to find if we've settled in a new spot.
        
        guard let candidateCenter = potentialSceneCenter, let start = potentialSceneStart else {
            // No candidate yet, set this point as candidate
            potentialSceneCenter = currentLocation
            potentialSceneStart = Date()
            return
        }
        
        let distance = currentLocation.distance(from: candidateCenter)
        
        if distance < stationaryRadius {
            // We are staying near the candidate
            if Date().timeIntervalSince(start) >= stationaryDurationThreshold {
                // CONFIRMED: Switch to Scene
                print("[TimelineRecorder] Threshold passed. Switching to Scene.")
                createNewScene(at: candidateCenter) // Or currentLocation? Candidate is safer as average.
                currentState = .stationary(center: candidateCenter, startTime: Date())
                potentialSceneCenter = nil
                potentialSceneStart = nil
            }
        } else {
            // We moved away from the candidate. This point becomes the NEW candidate.
            // (Because we are in "Moving" state, keeping moving is normal, but "stopping" means finding a cluster)
            potentialSceneCenter = currentLocation
            potentialSceneStart = Date()
            // print("[TimelineRecorder] Moved away from candidate. Resetting candidate.")
        }
    }
    
    // MARK: - Data Operations
    
    private func createNewScene(at location: CLLocation?) {
        let now = Date()
        let timeString = DateFormatter.hourMinute.string(from: now)
        let today = DateUtilities.today
        
        // Default values for nil location
        let lat = location?.coordinate.latitude ?? 0
        let lng = location?.coordinate.longitude ?? 0
        let tempName = location == nil ? "Unknown Location" : "Location \(timeString)"
        let status: LocationStatus = location == nil ? .no_permission : .raw
        
        let snapshot = LocationSnapshot(lat: lat, lng: lng)
        let locVO = LocationVO(status: status, mappingId: nil, snapshot: snapshot, displayText: tempName, originalRawName: tempName, icon: "mappin.and.ellipse", color: nil)
        
        // 1. Close previous item if needed (Update Journey Destination)
        let timeline = TimelineRepository.shared.getDailyTimeline(for: today)
        let currentItems = timeline.items
        if let lastItem = currentItems.last {
            if case .journey(let j) = lastItem {
                // Calculate duration
                var durationStr = "1 min"
                if case .moving(let startTime) = currentState {
                    let duration = Date().timeIntervalSince(startTime)
                    let minutes = max(1, Int(duration / 60))
                    if minutes < 60 {
                        durationStr = "\(minutes) min"
                    } else {
                        let hours = minutes / 60
                        let mins = minutes % 60
                        durationStr = "\(hours) h \(mins) min"
                    }
                }
                
                TimelineRepository.shared.updateJourneyDestination(itemId: j.id, newDestination: locVO, duration: durationStr, for: today)
            }
        }
        
        // 2. Create new Scene
        let sceneId = "scene_\(UUID().uuidString)"
        let newScene = SceneGroup(type: "scene", id: sceneId, timeRange: timeString, location: locVO, entries: [])
        
        TimelineRepository.shared.appendItem(.scene(newScene), for: today)
        print("[TimelineRecorder] Saved new Scene.")
        
        // Resolve Address Async if location exists
        if let loc = location {
            // Check if we have cached mapping first (Optimistic UI)
            let hits = LocationService.shared.suggestMappings(lat: lat, lng: lng)
            if let hit = hits.first {
                print("[TimelineRecorder] Hit cached mapping: \(hit.name)")
                // Update immediately on main thread to ensure UI reflects it
                DispatchQueue.main.async {
                    TimelineRepository.shared.updateLocationName(itemId: sceneId, newName: hit.name, for: today)
                    // Also update the previous journey destination name if we just linked it
                    if let lastItem = currentItems.last, case .journey(let j) = lastItem {
                         let updatedDest = LocationVO(status: locVO.status, mappingId: hit.id, snapshot: locVO.snapshot, displayText: hit.name, originalRawName: locVO.originalRawName, icon: hit.icon, color: hit.color)
                         TimelineRepository.shared.updateJourneyDestination(itemId: j.id, newDestination: updatedDest, duration: j.duration, for: today)
                    }
                }
            } else {
                LocationService.shared.resolveAddress(location: loc) { [weak self] resolvedName in
                    guard let name = resolvedName, !name.isEmpty else {
                        print("[TimelineRecorder] Address resolution failed or returned empty.")
                        return 
                    }
                    print("[TimelineRecorder] Resolved address: \(name)")
                    // Ensure UI update happens
                    DispatchQueue.main.async {
                        TimelineRepository.shared.updateLocationName(itemId: sceneId, newName: name, for: today)
                        // Also update previous journey
                        if let lastItem = currentItems.last, case .journey(let j) = lastItem {
                             let updatedDest = LocationVO(status: locVO.status, mappingId: nil, snapshot: locVO.snapshot, displayText: name, originalRawName: name, icon: locVO.icon, color: locVO.color)
                             TimelineRepository.shared.updateJourneyDestination(itemId: j.id, newDestination: updatedDest, duration: j.duration, for: today)
                        }
                    }
                }
            }
        }
    }
    
    private func createNewJourney(from: CLLocation?, to: CLLocation?) {
        let now = Date()
        let today = DateUtilities.today
        
        let originLat = from?.coordinate.latitude ?? 0
        let originLng = from?.coordinate.longitude ?? 0
        let destLat = to?.coordinate.latitude ?? 0
        let destLng = to?.coordinate.longitude ?? 0
        
        let originSnap = LocationSnapshot(lat: originLat, lng: originLng)
        let destSnap = LocationSnapshot(lat: destLat, lng: destLng)
        
        let journeyId = "journey_\(UUID().uuidString)"
        
        let originStatus: LocationStatus = from == nil ? .no_permission : .raw
        let destStatus: LocationStatus = to == nil ? .no_permission : .raw
        
        // Try to get origin name from previous scene
        var originName = "未知地点"
        var originMappingId: String? = nil
        var originIcon: String? = nil
        var originColor: String? = nil
        
        let timeline = TimelineRepository.shared.getDailyTimeline(for: today)
        let currentItems = timeline.items
        if let lastItem = currentItems.last, case .scene(let s) = lastItem {
            originName = s.location.displayText
            originMappingId = s.location.mappingId
            originIcon = s.location.icon
            originColor = s.location.color
        }
        
        let originVO = LocationVO(status: originStatus, mappingId: originMappingId, snapshot: originSnap, displayText: originName, originalRawName: originName, icon: originIcon, color: originColor)
        let destVO = LocationVO(status: destStatus, mappingId: nil, snapshot: destSnap, displayText: "途中...", originalRawName: "途中...", icon: nil, color: nil)
        
        let newJourney = JourneyBlock(type: "journey", id: journeyId, origin: originVO, destination: destVO, mode: .car, duration: "移动中", entries: [])
        
        TimelineRepository.shared.appendItem(.journey(newJourney), for: today)
        print("[TimelineRecorder] Saved new Journey.")
        
        // If we didn't have a previous scene, resolve origin address
        var isLastScene = false
        if let last = currentItems.last, case .scene = last { isLastScene = true }
        
        if !isLastScene {
            if let fromLoc = from {
                LocationService.shared.resolveAddress(location: fromLoc) { [weak self] resolvedName in
                    guard let name = resolvedName, !name.isEmpty else { return }
                    TimelineRepository.shared.updateOriginName(itemId: journeyId, newName: name, for: today)
                }
            }
        }
    }
}

// Helper (Assuming DateUtilities exists, but adding extension just in case for this file)
private extension DateFormatter {
    static let hourMinute: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df
    }()
}
