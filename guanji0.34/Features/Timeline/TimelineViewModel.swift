import SwiftUI
import Combine
import CoreLocation

public final class TimelineViewModel: ObservableObject {
    @Published public private(set) var items: [TimelineItem] = []
    @Published public private(set) var displayItems: [TimelineItem] = []
    @Published public private(set) var todayQuestions: [QuestionEntry] = []
    @Published public var currentDate: String = DateUtilities.today
    @Published public var todayDataLoaded: Bool = false
    @Published public private(set) var onThisDay: [JournalEntry] = []
    @Published public private(set) var resonanceStats: [ResonanceDateStat] = []
    @Published public private(set) var dailyTrackerRecord: DailyTrackerRecord? = nil
    
    /// AI conversations for the current day - Requirements: 4.10, 4.11, 5.3
    /// Filtered to only include conversations with messages, sorted by creation time
    @Published public private(set) var aiConversations: [AIConversation] = []
    
    /// Combined display items for timeline - includes both journal entries and AI conversations
    /// Sorted by time for proper timeline ordering
    @Published public private(set) var combinedDisplayItems: [TimelineDisplayItem] = []
    
    private var cancellables = Set<AnyCancellable>()

    public init() { 
        // Sync displayItems whenever items or todayQuestions change
        Publishers.CombineLatest($items, $todayQuestions)
            .receive(on: RunLoop.main)
            .sink { [weak self] (items, questions) in
                self?.updateDisplayItems(items: items, questions: questions)
            }
            .store(in: &cancellables)
        
        // Sync combinedDisplayItems whenever displayItems or aiConversations change
        Publishers.CombineLatest($displayItems, $aiConversations)
            .receive(on: RunLoop.main)
            .sink { [weak self] (displayItems, aiConversations) in
                self?.updateCombinedDisplayItems(displayItems: displayItems, aiConversations: aiConversations)
            }
            .store(in: &cancellables)
            
        load(date: currentDate)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onAddressesChanged), name: Notification.Name("gj_addresses_changed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDayEndTimeChanged), name: Notification.Name("gj_day_end_time_changed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTrackerUpdated), name: Notification.Name("gj_tracker_updated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAIConversationUpdated), name: Notification.Name("gj_ai_conversation_updated"), object: nil)
    }
    
    @objc private func onTrackerUpdated() {
        // Reload daily tracker record
        self.dailyTrackerRecord = DailyTrackerRepository.shared.load(for: currentDate)
    }
    
    /// Handle AI conversation updates - Requirements: 4.10, 4.11
    @objc private func onAIConversationUpdated() {
        // Reload AI conversations for current date, filter out empty conversations
        self.aiConversations = AIConversationRepository.shared.getConversations(for: currentDate)
            .filter { !$0.messages.isEmpty }  // Filter out conversations with no messages
            .sorted { $0.createdAt < $1.createdAt }  // Sort by creation time (oldest first for timeline order)
    }
    
    @objc private func onDayEndTimeChanged() {
        // When day end time changes, "Today" definition might change.
        // We reload to the new "Today" to ensure consistency.
        load(date: DateUtilities.today)
    }
    
    @objc private func onAddressesChanged() {
        refreshLocationMappings()
    }

    public func load(date: String? = nil) {
        let targetDate = date ?? DateUtilities.today
        print("[TimelineVM] load() called with date: \(targetDate), currentDate was: \(self.currentDate)")
        self.currentDate = targetDate
        
        // Load Daily Tracker record for this date
        self.dailyTrackerRecord = DailyTrackerRepository.shared.load(for: targetDate)
        
        // Load AI conversations for this date - Requirements: 4.10, 4.11, 5.3
        // Filter out empty conversations (no messages = garbage data)
        // Sort by creation time for proper timeline ordering
        self.aiConversations = AIConversationRepository.shared.getConversations(for: targetDate)
            .filter { !$0.messages.isEmpty }  // Filter out conversations with no messages
            .sorted { $0.createdAt < $1.createdAt }  // Sort by creation time (oldest first for timeline order)
        
        // Use Repository to get DailyTimeline, then extract items for UI
        let timeline = TimelineRepository.shared.getDailyTimeline(for: targetDate)
        
        // Deduplicate items: Keep the last occurrence of any ID to recover from potential race conditions
        var uniqueMap: [String: TimelineItem] = [:]
        var order: [String] = []
        for item in timeline.items {
            if uniqueMap[item.id] == nil {
                order.append(item.id)
            }
            uniqueMap[item.id] = item
        }
        self.items = order.compactMap { uniqueMap[$0] }
        print("[TimelineVM] load() finished: items count = \(self.items.count)")
        
        let allQ = QuestionRepository.shared.getAll()
        // Fetch questions for ANY date (History or Today)
        // Filter: Delivered on targetDate OR Created on targetDate
        self.todayQuestions = allQ.filter { $0.delivery_date == targetDate || $0.created_at == targetDate }
        
        // Ensure that any questions appearing in the stream are also caught, even if date mismatch
        // (Defensive coding for the History Page issue)
        let streamEntryIds = Set(items.flatMap { item -> [String] in
            switch item {
            case .scene(let s): return s.entries.map { $0.id }
            case .journey(let j): return j.entries.map { $0.id }
            }
        })
        
        let streamQuestionIds = items.flatMap { item -> [String] in
            switch item {
            case .scene(let s): return s.entries.compactMap { $0.metadata?.questionId }
            case .journey(let j): return j.entries.compactMap { $0.metadata?.questionId }
            }
        }
        
        let missingQ = allQ.filter { q in 
            // Condition 1: The question is referenced by a reply in the stream
            if streamQuestionIds.contains(q.id) { return true }
            // Condition 2: The question's source entry is in the stream (Sealed Memory case)
            if streamEntryIds.contains(q.journal_now_id) { return true }
            return false
        }
        .filter { q in !self.todayQuestions.contains(where: { tq in tq.id == q.id }) } // Avoid duplicates
        
        if !missingQ.isEmpty {
            self.todayQuestions.append(contentsOf: missingQ)
        }
        
        // Refresh locations against current repository to ensure consistency
        refreshLocationMappings()
        
        // If today, try to fetch real data
        if targetDate == DateUtilities.today {
            fetchRealtimeContext()
        } else {
            // For History Page: Also fetch entries from TODAY's timeline that are "Reviews" of this date.
            let todayTimeline = TimelineRepository.shared.getDailyTimeline(for: DateUtilities.today)
            var reviews: [JournalEntry] = []
            
            for item in todayTimeline.items {
                switch item {
                case .scene(let s):
                    reviews.append(contentsOf: s.entries.filter { $0.metadata?.reviewDate == targetDate })
                case .journey(let j):
                    reviews.append(contentsOf: j.entries.filter { $0.metadata?.reviewDate == targetDate })
                }
            }
            
            if !reviews.isEmpty {
                // Append these reviews to the bottom of the history view
                // We create a new Scene for them or append to last scene?
                // Create a "Review" Scene
                let reviewScene = SceneGroup(type: "scene", id: "review_scene_\(targetDate)", timeRange: "Review", location: LocationVO(status: .raw, mappingId: nil, snapshot: LocationSnapshot(lat: 0, lng: 0), displayText: "Review", originalRawName: nil, icon: nil, color: nil), entries: reviews)
                self.items.append(.scene(reviewScene))
            }
        }
        
        self.onThisDay = [] // Reset or implement historical lookup via Repo
        self.resonanceStats = [] // Reset or implement
        self.todayDataLoaded = true
    }
    
    private func fetchRealtimeContext() {
        // 1. Check Permissions
        // We do not force fetch here anymore as TimelineRecorder handles the continuous stream.
        // However, we can use this to update weather if needed.
        
        LocationService.shared.requestCurrentSnapshot { lat, lng, _ in
            guard lat != 0 && lng != 0 else { return }
            
            // 2. Fetch Weather if we have location
            WeatherService.shared.fetchCurrentWeather(lat: lat, lng: lng) { _, _ in
                // Update Live Activity removed
            }
        }
    }

    public func addEntry(_ entry: JournalEntry) {
        // Get current location
        let currentLoc = LocationService.shared.lastKnownLocation
        let lat = currentLoc?.coordinate.latitude ?? 0
        let lng = currentLoc?.coordinate.longitude ?? 0
        let snapshot = LocationSnapshot(lat: lat, lng: lng)
        
        // Check fence matching
        let fenceMatches = LocationRepository.shared.suggestMappings(lat: lat, lng: lng)
        let currentFence = fenceMatches.first
        
        // Determine if we should create a new block
        if let last = items.last {
            let shouldCreateNew = shouldCreateNewBlock(
                lastItem: last,
                currentFence: currentFence,
                currentSnapshot: snapshot
            )
            
            if shouldCreateNew {
                // Create new block based on last item type
                switch last {
                case .scene:
                    // Was in a scene, now moving or in different fence -> Create Journey
                    createJourneyBlock(from: last, currentSnapshot: snapshot, currentFence: currentFence, entry: entry)
                case .journey:
                    // Was traveling, now arrived at a fence -> Create Scene
                    createSceneBlock(currentSnapshot: snapshot, currentFence: currentFence, entry: entry)
                }
            } else {
                // Append to existing block
                appendToLastBlock(entry: entry)
            }
        } else {
            // First entry of the day -> Create initial Scene
            createSceneBlock(currentSnapshot: snapshot, currentFence: currentFence, entry: entry)
        }
        
        // Refresh location mappings to update UI
        if lat != 0 {
            refreshLocationMappings()
        }
    }
    
    // MARK: - Location Block Logic
    
    private func shouldCreateNewBlock(lastItem: TimelineItem, currentFence: AddressMapping?, currentSnapshot: LocationSnapshot) -> Bool {
        switch lastItem {
        case .scene(let s):
            // Check if we're still in the same fence
            if let fence = currentFence, let lastMappingId = s.location.mappingId {
                // Same fence -> Stay in scene
                return fence.id != lastMappingId
            } else if currentFence != nil {
                // New fence detected -> Move to journey
                return true
            } else {
                // No fence, check distance (fallback)
                let distance = calculateDistance(s.location.snapshot, currentSnapshot)
                return distance > 500 // 500m threshold
            }
            
        case .journey(_):
            // If we're in any fence, we've arrived -> Create scene
            if currentFence != nil {
                return true
            }
            // Still no fence -> Continue journey
            return false
        }
    }
    
    private func createSceneBlock(currentSnapshot: LocationSnapshot, currentFence: AddressMapping?, entry: JournalEntry) {
        let displayText: String
        let status: LocationStatus
        let mappingId: String?
        let icon: String?
        let color: String?
        
        if let fence = currentFence {
            displayText = fence.name
            status = .mapped
            mappingId = fence.id
            icon = fence.icon
            color = fence.color
        } else if currentSnapshot.lat != 0 {
            displayText = "Location"
            status = .raw
            mappingId = nil
            icon = nil
            color = nil
        } else {
            displayText = "Unknown Location"
            status = .no_permission
            mappingId = nil
            icon = nil
            color = nil
        }
        
        let loc = LocationVO(
            status: status,
            mappingId: mappingId,
            snapshot: currentSnapshot,
            displayText: displayText,
            originalRawName: displayText,
            icon: icon,
            color: color
        )
        
        let newScene = SceneGroup(
            type: "scene",
            id: "scene_\(UUID().uuidString)",
            timeRange: entry.timestamp,
            location: loc,
            entries: [entry]
        )
        
        items.append(.scene(newScene))
        TimelineRepository.shared.saveItems(items, for: currentDate)
    }
    
    private func createJourneyBlock(from lastItem: TimelineItem, currentSnapshot: LocationSnapshot, currentFence: AddressMapping?, entry: JournalEntry) {
        // Get origin from last scene
        let origin: LocationVO
        switch lastItem {
        case .scene(let s):
            origin = s.location
        case .journey(let j):
            origin = j.origin // Should not happen, but defensive
        }
        
        // Destination is current location (may be updated later)
        let destDisplayText = currentFence?.name ?? "Moving..."
        let destStatus: LocationStatus = currentFence != nil ? .mapped : .raw
        let destination = LocationVO(
            status: destStatus,
            mappingId: currentFence?.id,
            snapshot: currentSnapshot,
            displayText: destDisplayText,
            originalRawName: destDisplayText,
            icon: currentFence?.icon,
            color: currentFence?.color
        )
        
        let newJourney = JourneyBlock(
            type: "journey",
            id: "journey_\(UUID().uuidString)",
            origin: origin,
            destination: destination,
            mode: .car, // Default mode
            entries: [entry]
        )
        
        items.append(.journey(newJourney))
        TimelineRepository.shared.saveItems(items, for: currentDate)
    }
    
    private func appendToLastBlock(entry: JournalEntry) {
        guard let last = items.last else { return }
        
        switch last {
        case .scene(let s):
            let newScene = SceneGroup(
                type: s.type,
                id: s.id,
                timeRange: s.timeRange,
                location: s.location,
                entries: s.entries + [entry]
            )
            items[items.count - 1] = .scene(newScene)
            
        case .journey(let j):
            let newJourney = JourneyBlock(
                type: j.type,
                id: j.id,
                origin: j.origin,
                destination: j.destination,
                mode: j.mode,
                entries: j.entries + [entry]
            )
            items[items.count - 1] = .journey(newJourney)
        }
        
        TimelineRepository.shared.saveItems(items, for: currentDate)
    }
    
    private func calculateDistance(_ a: LocationSnapshot, _ b: LocationSnapshot) -> Double {
        // Approximate distance in meters
        return hypot((a.lat - b.lat) * 111_000, (a.lng - b.lng) * 111_000)
    }
    
    private func saveFileToDisk(_ url: URL) -> String? {
        let filename = UUID().uuidString + "_" + url.lastPathComponent
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let destURL = dir.appendingPathComponent(filename)
            do {
                if FileManager.default.fileExists(atPath: destURL.path) {
                    try FileManager.default.removeItem(at: destURL)
                }
                try FileManager.default.copyItem(at: url, to: destURL)
                return filename
            } catch {
                print("Error saving file: \(error)")
                return nil
            }
        }
        return nil
    }

    public func handleTodaySubmit(text: String, images: [UIImage]? = nil, videos: [URL]? = nil, audio: URL? = nil, duration: String? = nil, files: [URL]? = nil) {
        let ts = DateFormatter.hourMinute.string(from: Date())
        let isToday = (currentDate == DateUtilities.today)
        let reviewDate = isToday ? nil : currentDate
        let chronology: EntryChronology = isToday ? .present : .past
        
        var blocks: [ContentBlock] = []
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Save images to blocks
        if let imgs = images {
            for img in imgs {
                if let path = saveImageToDisk(img) {
                    blocks.append(ContentBlock(id: UUID().uuidString, type: .image, content: "", url: path, duration: nil))
                }
            }
        }
        
        // 2. Save videos to blocks
        if let vids = videos {
            for vid in vids {
                if let path = saveVideoToDisk(vid) {
                    blocks.append(ContentBlock(id: UUID().uuidString, type: .video, content: "", url: path, duration: nil))
                }
            }
        }
        
        // 3. Save audio
        if let audioURL = audio, let path = saveFileToDisk(audioURL) {
            blocks.append(ContentBlock(id: UUID().uuidString, type: .audio, content: "", url: path, duration: duration))
        }
        
        // 4. Save files
        if let fileURLs = files {
            for url in fileURLs {
                if let path = saveFileToDisk(url) {
                    let ext = url.pathExtension.lowercased()
                    if ["jpg", "jpeg", "png", "heic"].contains(ext) {
                        blocks.append(ContentBlock(id: UUID().uuidString, type: .image, content: "", url: path, duration: nil))
                    } else if ["m4a", "mp3", "wav"].contains(ext) {
                        blocks.append(ContentBlock(id: UUID().uuidString, type: .audio, content: "", url: path, duration: nil))
                    } else if ["mov", "mp4"].contains(ext) {
                        blocks.append(ContentBlock(id: UUID().uuidString, type: .video, content: "", url: path, duration: nil))
                    } else {
                        blocks.append(ContentBlock(id: UUID().uuidString, type: .file, content: url.lastPathComponent, url: path, duration: nil))
                    }
                }
            }
        }
        
        let hasText = !trimmedText.isEmpty
        let mediaCount = blocks.count
        
        var entry: JournalEntry!
        let meta = JournalEntry.Metadata(blocks: blocks, reviewDate: reviewDate, createdDate: DateUtilities.today, questionId: nil, duration: duration, sender: nil)
        
        if hasText && mediaCount > 0 {
            // Mixed
            let textBlock = ContentBlock(id: UUID().uuidString, type: .text, content: trimmedText, url: nil, duration: nil)
            blocks.insert(textBlock, at: 0)
            let mixedMeta = JournalEntry.Metadata(blocks: blocks, reviewDate: reviewDate, createdDate: DateUtilities.today, questionId: nil, duration: duration, sender: nil)
            
            entry = JournalEntry(id: UUID().uuidString,
                                     type: .mixed,
                                     subType: nil,
                                     chronology: chronology,
                                     content: trimmedText,
                                     url: nil,
                                     timestamp: ts,
                                     category: nil,
                                     metadata: mixedMeta)
        } else if mediaCount > 1 {
            // Multiple media -> Mixed
            entry = JournalEntry(id: UUID().uuidString,
                                     type: .mixed,
                                     subType: nil,
                                     chronology: chronology,
                                     content: "Shared \(mediaCount) items",
                                     url: nil,
                                     timestamp: ts,
                                     category: .media,
                                     metadata: meta)
        } else if mediaCount == 1 {
            // Single Media
            let block = blocks[0]
            entry = JournalEntry(id: UUID().uuidString,
                                     type: block.type,
                                     subType: nil,
                                     chronology: chronology,
                                     content: block.content.isEmpty ? nil : block.content,
                                     url: block.url,
                                     timestamp: ts,
                                     category: .media,
                                     metadata: meta)
        } else if hasText {
            // Only Text
            entry = JournalEntry(id: UUID().uuidString,
                                     type: .text,
                                     subType: nil,
                                     chronology: chronology,
                                     content: trimmedText,
                                     url: nil,
                                     timestamp: ts,
                                     category: nil,
                                     metadata: JournalEntry.Metadata(blocks: nil, reviewDate: reviewDate, createdDate: DateUtilities.today, questionId: nil, duration: nil, sender: nil))
        }
        
        if let e = entry {
            if isToday {
                addEntry(e)
            } else {
                // If reviewing history, save to TODAY's timeline but it references the past.
                // We also want to display it in the current history view (optimistically).
                TimelineRepository.shared.appendItem(.scene(SceneGroup(type: "scene", id: "scene_\(UUID().uuidString)", timeRange: ts, location: LocationVO(status: .raw, mappingId: nil, snapshot: LocationSnapshot(lat: 0, lng: 0), displayText: "Review", originalRawName: nil, icon: nil, color: nil), entries: [e])), for: DateUtilities.today)
                
                // Add to local display items so user sees it immediately
                if let last = items.last {
                    switch last {
                    case .scene(let s):
                        let newScene = SceneGroup(type: s.type, id: s.id, timeRange: s.timeRange, location: s.location, entries: s.entries + [e])
                        items[items.count - 1] = .scene(newScene)
                    case .journey(let j):
                        let newJourney = JourneyBlock(type: j.type, id: j.id, origin: j.origin, destination: j.destination, mode: j.mode, entries: j.entries + [e])
                        items[items.count - 1] = .journey(newJourney)
                    }
                } else {
                    // Create new scene for display
                    let scene = SceneGroup(type: "scene", id: UUID().uuidString, timeRange: ts, location: LocationVO(status: .raw, mappingId: nil, snapshot: LocationSnapshot(lat: 0, lng: 0), displayText: "Review", originalRawName: nil, icon: nil, color: nil), entries: [e])
                    items.append(.scene(scene))
                }
            }
        }
    }
    
    private func saveVideoToDisk(_ url: URL) -> String? {
        let filename = UUID().uuidString + ".mov"
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(filename)
            do {
                try FileManager.default.copyItem(at: url, to: fileURL)
                return filename
            } catch {
                print("Error saving video: \(error)")
                return nil
            }
        }
        return nil
    }
    
    private func saveImageToDisk(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(filename)
            do {
                try data.write(to: fileURL)
                return filename
            } catch {
                print("Error saving image: \(error)")
                return nil
            }
        }
        return nil
    }

    public func handleReply(questionId: String, replyText: String, images: [UIImage]? = nil, videos: [URL]? = nil, audio: URL? = nil, duration: String? = nil, files: [URL]? = nil) {
        guard !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (images != nil && !images!.isEmpty) || (videos != nil && !videos!.isEmpty) || audio != nil || (files != nil && !files!.isEmpty) else { return }
        
        let now = Date()
        let fullDateStr = DateUtilities.format(now)
        let ts = DateFormatter.hourMinute.string(from: now)
        
        var blocks: [ContentBlock] = []
        let trimmedText = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Save images to blocks
        if let imgs = images {
            for img in imgs {
                if let path = saveImageToDisk(img) {
                    blocks.append(ContentBlock(id: UUID().uuidString, type: .image, content: "", url: path, duration: nil))
                }
            }
        }
        
        // 2. Save videos to blocks
        if let vids = videos {
            for vid in vids {
                if let path = saveVideoToDisk(vid) {
                    blocks.append(ContentBlock(id: UUID().uuidString, type: .video, content: "", url: path, duration: nil))
                }
            }
        }
        
        // 3. Save audio
        if let audioURL = audio, let path = saveFileToDisk(audioURL) {
            blocks.append(ContentBlock(id: UUID().uuidString, type: .audio, content: "", url: path, duration: duration))
        }
        
        // 4. Save files
        if let fileURLs = files {
            for url in fileURLs {
                if let path = saveFileToDisk(url) {
                    let ext = url.pathExtension.lowercased()
                    if ["jpg", "jpeg", "png", "heic"].contains(ext) {
                        blocks.append(ContentBlock(id: UUID().uuidString, type: .image, content: "", url: path, duration: nil))
                    } else if ["m4a", "mp3", "wav"].contains(ext) {
                        blocks.append(ContentBlock(id: UUID().uuidString, type: .audio, content: "", url: path, duration: nil))
                    } else if ["mov", "mp4"].contains(ext) {
                         blocks.append(ContentBlock(id: UUID().uuidString, type: .video, content: "", url: path, duration: nil))
                    } else {
                         blocks.append(ContentBlock(id: UUID().uuidString, type: .file, content: url.lastPathComponent, url: path, duration: nil))
                    }
                }
            }
        }
        
        let hasText = !trimmedText.isEmpty
        let mediaCount = blocks.count
        
        var entry: JournalEntry!
        
        // Logic similar to handleTodaySubmit but forcing questionId metadata
        let metadata = JournalEntry.Metadata(blocks: blocks.isEmpty ? nil : blocks,
                                            reviewDate: nil,
                                            createdDate: fullDateStr,
                                            questionId: questionId,
                                            duration: duration,
                                            sender: nil)
        
        if hasText && mediaCount > 0 {
            // Mixed
            let textBlock = ContentBlock(id: UUID().uuidString, type: .text, content: trimmedText, url: nil, duration: nil)
            blocks.insert(textBlock, at: 0)
            // Update metadata with new blocks
            let mixedMeta = JournalEntry.Metadata(blocks: blocks, reviewDate: nil, createdDate: fullDateStr, questionId: questionId, duration: duration, sender: nil)
            
            entry = JournalEntry(id: UUID().uuidString,
                                 type: .mixed,
                                 subType: nil,
                                 chronology: .present,
                                 content: trimmedText,
                                 url: nil,
                                 timestamp: ts,
                                 category: .emotion,
                                 metadata: mixedMeta)
        } else if mediaCount > 1 {
            // Multiple media -> Mixed
            entry = JournalEntry(id: UUID().uuidString,
                                 type: .mixed,
                                 subType: nil,
                                 chronology: .present,
                                 content: "Shared \(mediaCount) items",
                                 url: nil,
                                 timestamp: ts,
                                 category: .media,
                                 metadata: metadata)
        } else if mediaCount == 1 {
            // Single Media
            let block = blocks[0]
            entry = JournalEntry(id: UUID().uuidString,
                                 type: block.type,
                                 subType: nil,
                                 chronology: .present,
                                 content: block.content.isEmpty ? nil : block.content,
                                 url: block.url,
                                 timestamp: ts,
                                 category: .media,
                                 metadata: metadata)
        } else {
            // Only Text
            entry = JournalEntry(id: UUID().uuidString,
                                 type: .text,
                                 subType: nil,
                                 chronology: .present,
                                 content: trimmedText,
                                 url: nil,
                                 timestamp: ts,
                                 category: .emotion,
                                 metadata: metadata)
        }
        
        let currentLoc = LocationService.shared.lastKnownLocation
        let lat = currentLoc?.coordinate.latitude ?? 0
        let lng = currentLoc?.coordinate.longitude ?? 0
        let displayText = (lat != 0) ? "Location" : "Reply"
        
        // Always save to TODAY's timeline, even if we are replying to a past question.
        TimelineRepository.shared.appendItem(.scene(SceneGroup(type: "scene", id: "scene_\(UUID().uuidString)", timeRange: entry.timestamp, location: LocationVO(status: .raw, mappingId: nil, snapshot: LocationSnapshot(lat: lat, lng: lng), displayText: displayText, originalRawName: displayText, icon: nil, color: nil), entries: [entry])), for: DateUtilities.today)
        
        // Refresh mappings if we have location
        if lat != 0 {
             // Delay slightly to ensure item is saved and reloadable
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                 self.refreshLocationMappings()
             }
        }
        
        objectWillChange.send()
        
        // If we are currently viewing Today, reload.
        if currentDate == DateUtilities.today {
            load(date: currentDate)
        } else {
            // If we are viewing History, and we replied to a question...
            // We should probably check if this question is in the current history view.
            // But since it's a "Reply", it is hidden from the main stream anyway (filtered out by questionId).
            // So we might not need to do anything for the history view display.
        }
    }

    public func createCapsule(mode: String, prompt: String, deliveryDate: Date, sealed: Bool, systemQuestion: String? = nil) {
        let type: EntryType = {
            switch mode {
            case "image": return .image
            case "audio": return .audio
            default: return .text
            }
        }()
        let id = "capsule_" + UUID().uuidString
        let now = Date()
        let ts = DateFormatter.hourMinute.string(from: now)
        let creationDateStr = DateUtilities.format(now) // Use ACTUAL Today, not vm.currentDate
        
        var questionId: String? = nil
        // Ensure we create a QuestionEntry even if systemQuestion is empty, so it appears in Time Ripple
        // If systemQuestion is empty, we use a snippet of the user's prompt (content) as the title.
        let qId = "q_" + UUID().uuidString
        let interval = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: Calendar.current.startOfDay(for: deliveryDate)).day ?? 0
        
        let finalPrompt: String
        if let sq = systemQuestion, !sq.isEmpty {
            finalPrompt = sq
        } else {
            // Use user's content as title (truncated if needed, or full)
            // User requested: "Title is today's message content"
            finalPrompt = prompt.isEmpty ? "Time Capsule" : prompt
        }
        
        let q = QuestionEntry(id: qId,
                              created_at: creationDateStr,
                              updated_at: creationDateStr,
                              system_prompt: finalPrompt,
                              journal_now_id: id,
                              journal_future_id: nil,
                              interval_days: interval,
                              delivery_date: DateUtilities.format(deliveryDate))
        QuestionRepository.shared.add(q)
        questionId = qId
        
        let entry = JournalEntry(id: id,
                                 type: type,
                                 subType: sealed ? nil : .pending_question,
                                 chronology: .future,
                                 content: prompt.isEmpty ? nil : prompt,
                                 url: nil,
                                 timestamp: ts,
                                 category: .health,
                                metadata: JournalEntry.Metadata(blocks: nil,
                                                               reviewDate: nil,
                                                               createdDate: creationDateStr,
                                                               questionId: questionId,
                                                               duration: nil,
                                                               sender: nil))
        
        // Save to TODAY'S Timeline, regardless of what we are viewing
        TimelineRepository.shared.appendItem(.scene(SceneGroup(type: "scene", id: "scene_\(UUID().uuidString)", timeRange: ts, location: LocationVO(status: .no_permission, mappingId: nil, snapshot: LocationSnapshot(lat: 0, lng: 0), displayText: "Capsule", originalRawName: nil, icon: nil, color: nil), entries: [entry])), for: creationDateStr)
        
        // If we are currently viewing Today, refresh to show it (although it should be hidden by filter, the Question logic might need it)
        if currentDate == creationDateStr {
            load(date: currentDate)
        }
        // If we are viewing History, do NOTHING to the current view.
        
        objectWillChange.send()
    }

    private func computeOnThisDay() {
        var result: [JournalEntry] = []
        for d in [ChronologyAnchor.ONE_YEAR_AGO_DATE, ChronologyAnchor.TWO_YEARS_AGO_DATE] {
            let timeline = TimelineRepository.shared.getDailyTimeline(for: d)
            for item in timeline.items {
                switch item {
                case .scene(let s): result.append(contentsOf: s.entries)
                case .journey(let j): result.append(contentsOf: j.entries)
                }
            }
        }
        onThisDay = result
    }

    private func computeResonanceStats() {
        let todayYear = Int(ChronologyAnchor.TODAY_DATE.prefix(4)) ?? 0
        let targets = [ChronologyAnchor.ONE_YEAR_AGO_DATE, ChronologyAnchor.TWO_YEARS_AGO_DATE]
        var stats: [ResonanceDateStat] = []
        for d in targets {
            let year = Int(d.prefix(4)) ?? 0
            let timeline = TimelineRepository.shared.getDailyTimeline(for: d)
            let items = timeline.items
            var originals = 0
            var images = 0
            for item in items {
                switch item {
                case .scene(let s):
                    originals += s.entries.count
                    images += s.entries.filter { $0.type == .image }.count
                case .journey(let j):
                    originals += j.entries.count
                    images += j.entries.filter { $0.type == .image }.count
                }
            }
            var echoes = 0
            let allTimelines = TimelineRepository.shared.getAllTimelines()
            for t in allTimelines {
                for it in t.items {
                    switch it {
                    case .scene(let s):
                        echoes += s.entries.filter { ($0.metadata?.reviewDate ?? "") == d }.count
                    case .journey(let j):
                        echoes += j.entries.filter { ($0.metadata?.reviewDate ?? "") == d }.count
                    }
                }
            }
            // Mock LoveLog/Capsule data removed for now
            let loveLogs = 0 
            let capsules = 0
            var title: String? = nil
            if title == nil {
                outer: for item in items {
                    switch item {
                    case .scene(let s): if let t = s.entries.first?.content, !t.isEmpty { title = String(t.prefix(10)); break outer }
                    case .journey(let j): if let t = j.entries.first?.content, !t.isEmpty { title = String(t.prefix(10)); break outer }
                    }
                }
            }
            // Achievement title removed for now
            let stat = ResonanceDateStat(date: d, year: year, title: title, originalCount: originals, imageCount: images, echoesCount: echoes, loveLogsCount: loveLogs, capsulesCount: capsules, todayYear: todayYear)
            if originals > 0 || echoes > 0 || loveLogs > 0 || capsules > 0 { stats.append(stat) }
        }
        resonanceStats = stats
    }

    public func tagEntry(id: String, category: EntryCategory?) {
        items = items.map { item in
            switch item {
            case .scene(let s):
                let updated = s.entries.map { e in e.id == id ? JournalEntry(id: e.id, type: e.type, subType: e.subType, chronology: e.chronology, content: e.content, url: e.url, timestamp: e.timestamp, category: category, metadata: e.metadata) : e }
                return .scene(SceneGroup(type: s.type, id: s.id, timeRange: s.timeRange, location: s.location, entries: updated))
            case .journey(let j):
                let updated = j.entries.map { e in e.id == id ? JournalEntry(id: e.id, type: e.type, subType: e.subType, chronology: e.chronology, content: e.content, url: e.url, timestamp: e.timestamp, category: category, metadata: e.metadata) : e }
                return .journey(JourneyBlock(type: j.type, id: j.id, origin: j.origin, destination: j.destination, mode: j.mode, entries: updated))
            }
        }
        TimelineRepository.shared.saveItems(items, for: currentDate)
    }

    public func editEntryContent(id: String, newContent: String) {
        items = items.map { item in
            switch item {
            case .scene(let s):
                let updated = s.entries.map { e in e.id == id ? JournalEntry(id: e.id, type: e.type, subType: e.subType, chronology: e.chronology, content: newContent, url: e.url, timestamp: e.timestamp, category: e.category, metadata: e.metadata) : e }
                return .scene(SceneGroup(type: s.type, id: s.id, timeRange: s.timeRange, location: s.location, entries: updated))
            case .journey(let j):
                let updated = j.entries.map { e in e.id == id ? JournalEntry(id: e.id, type: e.type, subType: e.subType, chronology: e.chronology, content: newContent, url: e.url, timestamp: e.timestamp, category: e.category, metadata: e.metadata) : e }
                return .journey(JourneyBlock(type: j.type, id: j.id, origin: j.origin, destination: j.destination, mode: j.mode, entries: updated))
            }
        }
        TimelineRepository.shared.saveItems(items, for: currentDate)
    }
    
    public func deleteEntry(id: String) {
        // Only allow deletion if current view is Today
        guard currentDate == DateUtilities.today else { return }
        
        items = items.compactMap { item in
            switch item {
            case .scene(let s):
                let updated = s.entries.filter { $0.id != id }
                if updated.isEmpty { return nil } // Remove scene if empty
                return .scene(SceneGroup(type: s.type, id: s.id, timeRange: s.timeRange, location: s.location, entries: updated))
            case .journey(let j):
                let updated = j.entries.filter { $0.id != id }
                if updated.isEmpty { return nil } // Remove journey if empty
                return .journey(JourneyBlock(type: j.type, id: j.id, origin: j.origin, destination: j.destination, mode: j.mode, entries: updated))
            }
        }
        TimelineRepository.shared.saveItems(items, for: currentDate)
    }

    public func mapRawLocation(rawName: String, newName: String, icon: String, color: String?, mappingId: String? = nil) {
        items = items.map { item in
            switch item {
            case .scene(let s):
                let loc = s.location
                let updatedLoc = (loc.originalRawName == rawName && loc.status == .raw) ? LocationVO(status: .mapped, mappingId: mappingId ?? UUID().uuidString, snapshot: loc.snapshot, displayText: newName, originalRawName: loc.originalRawName, icon: icon, color: color) : loc
                return .scene(SceneGroup(type: s.type, id: s.id, timeRange: s.timeRange, location: updatedLoc, entries: s.entries))
            case .journey(let j):
                let o = j.origin
                let d = j.destination
                let newO = (o.originalRawName == rawName && o.status == .raw) ? LocationVO(status: .mapped, mappingId: mappingId ?? UUID().uuidString, snapshot: o.snapshot, displayText: newName, originalRawName: o.originalRawName, icon: icon, color: color) : o
                let newD = (d.originalRawName == rawName && d.status == .raw) ? LocationVO(status: .mapped, mappingId: mappingId ?? UUID().uuidString, snapshot: d.snapshot, displayText: newName, originalRawName: d.originalRawName, icon: icon, color: color) : d
                return .journey(JourneyBlock(type: j.type, id: j.id, origin: newO, destination: newD, mode: j.mode, entries: j.entries))
            }
        }
    }

    private func isNear(_ a: LocationSnapshot, _ b: LocationSnapshot, thresholdMeters: Double) -> Bool {
        let meters = hypot((a.lat - b.lat) * 111_000, (a.lng - b.lng) * 111_000)
        return meters <= thresholdMeters
    }

    public func refreshLocationMappings() {
        items = items.map { item in
            switch item {
            case .scene(let s):
                let loc = s.location
                var updatedLoc = loc
                let hits = LocationService.shared.suggestMappings(lat: loc.snapshot.lat, lng: loc.snapshot.lng)
                if let m = hits.first {
                    updatedLoc = LocationVO(status: .mapped,
                                            mappingId: m.id,
                                            snapshot: loc.snapshot,
                                            displayText: m.name,
                                            originalRawName: loc.originalRawName,
                                            icon: m.icon,
                                            color: m.color)
                } else {
                    updatedLoc = LocationVO(status: .raw,
                                            mappingId: nil,
                                            snapshot: loc.snapshot,
                                            displayText: loc.originalRawName ?? loc.displayText,
                                            originalRawName: loc.originalRawName ?? loc.displayText,
                                            icon: nil,
                                            color: nil)
                }
                return .scene(SceneGroup(type: s.type, id: s.id, timeRange: s.timeRange, location: updatedLoc, entries: s.entries))
            case .journey(let j):
                let o = j.origin
                let d = j.destination
                var newO = o
                var newD = d
                let hitsO = LocationService.shared.suggestMappings(lat: o.snapshot.lat, lng: o.snapshot.lng)
                if let m = hitsO.first {
                    newO = LocationVO(status: .mapped,
                                      mappingId: m.id,
                                      snapshot: o.snapshot,
                                      displayText: m.name,
                                      originalRawName: o.originalRawName,
                                      icon: m.icon,
                                      color: m.color)
                } else {
                    newO = LocationVO(status: .raw,
                                      mappingId: nil,
                                      snapshot: o.snapshot,
                                      displayText: o.originalRawName ?? o.displayText,
                                      originalRawName: o.originalRawName ?? o.displayText,
                                      icon: nil,
                                      color: nil)
                }
                let hitsD = LocationService.shared.suggestMappings(lat: d.snapshot.lat, lng: d.snapshot.lng)
                if let m = hitsD.first {
                    newD = LocationVO(status: .mapped,
                                      mappingId: m.id,
                                      snapshot: d.snapshot,
                                      displayText: m.name,
                                      originalRawName: d.originalRawName,
                                      icon: m.icon,
                                      color: m.color)
                } else {
                    newD = LocationVO(status: .raw,
                                      mappingId: nil,
                                      snapshot: d.snapshot,
                                      displayText: d.originalRawName ?? d.displayText,
                                      originalRawName: d.originalRawName ?? d.displayText,
                                      icon: nil,
                                      color: nil)
                }
                return .journey(JourneyBlock(type: j.type, id: j.id, origin: newO, destination: newD, mode: j.mode, entries: j.entries))
            }
        }
    }

    public func applyResolvedLocation(_ newLoc: LocationVO, thresholdMeters: Double = 150) {
        items = items.map { item in
            switch item {
            case .scene(let s):
                let updated = isNear(s.location.snapshot, newLoc.snapshot, thresholdMeters: thresholdMeters) ? newLoc : s.location
                return .scene(SceneGroup(type: s.type, id: s.id, timeRange: s.timeRange, location: updated, entries: s.entries))
            case .journey(let j):
                let newO = isNear(j.origin.snapshot, newLoc.snapshot, thresholdMeters: thresholdMeters) ? newLoc : j.origin
                let newD = isNear(j.destination.snapshot, newLoc.snapshot, thresholdMeters: thresholdMeters) ? newLoc : j.destination
                return .journey(JourneyBlock(type: j.type, id: j.id, origin: newO, destination: newD, mode: j.mode, entries: j.entries))
            }
        }
        refreshLocationMappings()
    }

    private func updateDisplayItems(items: [TimelineItem], questions: [QuestionEntry]) {
        // Filter logic to keep the main stream clean:
        // 1. Universal Hide: Any entry with a `questionId` (Source or Reply) belongs to the Time Ripple system.
        // 2. Specific Hide: Any entry ID that matches a known Question's source ID (for legacy or edge cases).
        // 3. Type Hide: Any entry with subType == .pending_question (Sealed Memory) must be hidden.
        
        let hiddenEntryIds = Set(questions.compactMap { $0.journal_now_id })
        
        self.displayItems = items.compactMap { item in
            switch item {
            case .scene(let s):
                let visible = s.entries.filter { entry in
                    // Rule 1: Sealed Memories are never shown in stream
                    if entry.subType == .pending_question { return false }
                    // Rule 1.1: Future entries (Capsules) are never shown in stream
                    if entry.chronology == .future { return false }
                    // Rule 2: Replies (linked to questions) are never shown in stream
                    if let qid = entry.metadata?.questionId, !qid.isEmpty { return false }
                    // Rule 3: Source entries of known questions are hidden
                    if hiddenEntryIds.contains(entry.id) { return false }
                    return true
                }
                if visible.isEmpty { return nil }
                return .scene(SceneGroup(type: s.type, id: s.id, timeRange: s.timeRange, location: s.location, entries: visible))
            case .journey(let j):
                let visible = j.entries.filter { entry in
                    if entry.subType == .pending_question { return false }
                    if entry.chronology == .future { return false }
                    if let qid = entry.metadata?.questionId, !qid.isEmpty { return false }
                    if hiddenEntryIds.contains(entry.id) { return false }
                    return true
                }
                if visible.isEmpty { return nil }
                return .journey(JourneyBlock(type: j.type, id: j.id, origin: j.origin, destination: j.destination, mode: j.mode, entries: visible))
            }
        }
    }
    
    /// Update combined display items by merging timeline items and AI conversations
    /// Sorted by time for proper timeline ordering
    /// - Requirements: 4.10, 4.11, 5.3
    private func updateCombinedDisplayItems(displayItems: [TimelineItem], aiConversations: [AIConversation]) {
        var combined: [TimelineDisplayItem] = []
        
        // Add timeline items
        for item in displayItems {
            combined.append(.timelineItem(item))
        }
        
        // Add AI conversations (already filtered for non-empty in load/onAIConversationUpdated)
        for conversation in aiConversations {
            combined.append(.aiConversation(conversation))
        }
        
        // Sort by timestamp
        self.combinedDisplayItems = combined.sorted { $0.sortTimestamp < $1.sortTimestamp }
    }
    
    /// Delete an AI conversation by ID
    /// - Parameter id: The conversation ID to delete
    public func deleteAIConversation(id: String) {
        AIConversationRepository.shared.delete(id: id)
        // The notification will trigger onAIConversationUpdated to refresh the list
    }
}

private extension DateFormatter {
    static let hourMinute: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df
    }()
}
