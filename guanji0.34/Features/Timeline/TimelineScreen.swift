import SwiftUI

public struct TimelineScreen: View {
    @StateObject private var vm = TimelineViewModel()
    @EnvironmentObject private var appState: AppState
    @StateObject private var keyboard = KeyboardObserver()
    @StateObject private var aiAttachmentManager = AttachmentManager()
    @State private var showMindState = false
    @State private var hasDynamicIsland = false
    @State private var showHistory = false
    @Namespace private var mindNS
    @Namespace private var editNS
    @State private var historyExpanded = false
    @State private var showTimeRippleSheet = false
    @State private var selectedRippleQuestion: QuestionEntry?
    @State private var editingTrackerRecord: DailyTrackerRecord? = nil

    
    public init() {}
    public var body: some View { content.environmentObject(vm) }
    private var content: some View {
        // Keep both views alive, use opacity to switch - preserves scroll position
        ZStack {
            // Journal view - always exists, hidden when in AI mode
            ScrollViewReader { proxy in
                scrollContent(proxy: proxy)
            }
            .opacity(appState.currentMode == .journal ? 1 : 0)
            .allowsHitTesting(appState.currentMode == .journal)
            
            // AI view - always exists, hidden when in journal mode
            AIConversationScreen()
                .opacity(appState.currentMode == .ai ? 1 : 0)
                .allowsHitTesting(appState.currentMode == .ai)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.currentMode)
        .background(homeGradient(appState.homeValence))
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .safeAreaInset(edge: .bottom) { 
            if appState.editingEntryId == nil && !showHistory { 
                InputDock(attachmentManager: aiAttachmentManager) 
            } 
        }
        .overlay(
            ZStack(alignment: .leading) {
                if showHistory {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation { showHistory = false; historyExpanded = false } }
                        .transition(.opacity)
                    
                    HistorySidebar(context: .timeline, isExpanded: $historyExpanded, onRequestClose: {
                        withAnimation { showHistory = false; historyExpanded = false }
                    })

                    .frame(maxWidth: historyExpanded ? .infinity : 300)
                    .transition(.move(edge: .leading))
                    .overlay(
                        // Drag Indicator
                        HStack {
                            Spacer()
                            Capsule()
                                .fill(Colors.systemGray.opacity(0.3))
                                .frame(width: 4, height: 44)
                                .padding(.trailing, 6)
                        }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.width > 50 && !historyExpanded {
                                    withAnimation { historyExpanded = true }
                                } else if value.translation.width < -50 && historyExpanded {
                                    withAnimation { historyExpanded = false }
                                }
                            }
                    )
                }
            }
            .zIndex(100)
        )
        .sheet(isPresented: Binding(
            get: { appState.editingEntryId != nil },
            set: { if !$0 { appState.editingEntryId = nil; appState.editingDraft = "" } }
        )) {
            if let id = appState.editingEntryId {
                TimelineEditingOverlay(entryId: id, draft: $appState.editingDraft, onSave: {
                    vm.editEntryContent(id: id, newContent: appState.editingDraft)
                    appState.editingEntryId = nil
                    appState.editingDraft = ""
                }, onCancel: {
                    appState.editingEntryId = nil
                    appState.editingDraft = ""
                })
            }
        }
        .sheet(isPresented: $appState.showCapsuleCreator) {
            CapsuleCreatorSheet(
                prompt: $appState.capsuleDraftPrompt,
                deliveryDate: $appState.capsuleDraftDate,
                sealed: $appState.capsuleDraftSealed,
                showSystemQuestion: $appState.capsuleDraftShowSystemQuestion,
                systemQuestion: $appState.capsuleDraftSystemQuestion,
                onSave: { mode, prompt, date, sealed, systemQuestion in
                vm.createCapsule(mode: mode, prompt: prompt, deliveryDate: date, sealed: sealed, systemQuestion: systemQuestion)
                appState.showCapsuleCreator = false
                // Reset draft after successful save
                appState.capsuleDraftPrompt = ""
                appState.capsuleDraftSystemQuestion = ""
                appState.capsuleDraftShowSystemQuestion = false
                appState.capsuleDraftDate = Date().addingTimeInterval(24*60*60)
                appState.capsuleDraftSealed = true
            }, onClose: {
                appState.showCapsuleCreator = false
            })
        }
        .sheet(isPresented: $appState.showPlaceNaming) {
            if let loc = appState.pendingLocation {
                let existing = LocationRepository.shared.mappings
                if existing.isEmpty {
                    PlaceNamingSheet(initial: loc, onSave: { name, icon in
                        let m = LocationRepository.shared.addMappingAndFence(name: name, icon: icon, color: nil, lat: loc.snapshot.lat, lng: loc.snapshot.lng, rawName: loc.originalRawName ?? loc.displayText)
                        let resolved = LocationVO(status: .mapped, mappingId: m.id, snapshot: loc.snapshot, displayText: name, originalRawName: loc.originalRawName, icon: icon, color: nil)
                        vm.applyResolvedLocation(resolved)
                        vm.refreshLocationMappings()
                        appState.showPlaceNaming = false; appState.pendingLocation = nil
                    }, onClose: {
                        appState.showPlaceNaming = false; appState.pendingLocation = nil
                    })
                } else {
                    PlaceResolveSheet(initial: loc, existing: existing, onCreate: { name, icon in
                        let m = LocationRepository.shared.addMappingAndFence(name: name, icon: icon, color: nil, lat: loc.snapshot.lat, lng: loc.snapshot.lng, rawName: loc.originalRawName ?? loc.displayText)
                        let resolved = LocationVO(status: .mapped, mappingId: m.id, snapshot: loc.snapshot, displayText: name, originalRawName: loc.originalRawName, icon: icon, color: nil)
                        vm.applyResolvedLocation(resolved)
                        vm.refreshLocationMappings()
                        appState.showPlaceNaming = false; appState.pendingLocation = nil
                    }, onAppend: { m in
                        _ = LocationRepository.shared.addFence(mappingId: m.id, lat: loc.snapshot.lat, lng: loc.snapshot.lng, rawName: loc.originalRawName ?? loc.displayText)
                        let resolved = LocationVO(status: .mapped, mappingId: m.id, snapshot: loc.snapshot, displayText: m.name, originalRawName: loc.originalRawName, icon: m.icon, color: m.color)
                        vm.applyResolvedLocation(resolved)
                        vm.refreshLocationMappings()
                        appState.showPlaceNaming = false; appState.pendingLocation = nil
                    })
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .animation(.easeInOut, value: appState.editingEntryId != nil)
        .alert(isPresented: $appState.showLocationPermission) {
            let st = appState.locationAuthStatus
            if st == .notDetermined {
                return Alert(title: Text(Localization.tr("privacyTitle")),
                             message: Text(Localization.tr("permLocationDesc")),
                             primaryButton: .default(Text(Localization.tr("grantAccess")), action: {
                                 LocationService.shared.requestAuthorization()
                             }),
                             secondaryButton: .cancel())
            } else {
                return Alert(title: Text(Localization.tr("privacyTitle")),
                             message: Text(Localization.tr("permLocationDesc")),
                             primaryButton: .default(Text(Localization.tr("openSettings")), action: {
                                 #if canImport(UIKit)
                                 if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                                 #endif
                             }),
                             secondaryButton: .cancel())
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: appState.showMindState)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Left toolbar item - only show in journal mode
            ToolbarItem(placement: .navigationBarLeading) {
                if appState.currentMode != .ai {
                    // Journal Mode: History sidebar toggle
                    Button(action: {
                        if showHistory {
                            withAnimation { showHistory = false; historyExpanded = false }
                        } else {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            withAnimation { showHistory = true }
                        }
                    }) {
                        Image(systemName: "sidebar.left")
                            .foregroundColor(showHistory ? Colors.indigo : .primary)
                    }
                }
            }
            
            // Right toolbar items - only show in journal mode
            ToolbarItem(placement: .navigationBarTrailing) {
                if appState.currentMode != .ai {
                    // Journal Mode: Return to today (if viewing history)
                    if vm.currentDate != DateUtilities.today {
                        Button(action: { withAnimation(.easeInOut) { appState.selectedDate = DateUtilities.today } }) {
                            Image(systemName: "arrow.uturn.backward")
                        }
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if appState.currentMode != .ai {
                    // Journal Mode only: Profile button
                    NavigationLink(destination: ProfileScreen()) {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
        }
        #endif
        .sheet(isPresented: $appState.showMindState) {
            Group {
                if let record = editingTrackerRecord {
                    // Edit existing record
                    DailyTrackerFlowScreen(record: record, onClose: {
                        appState.showMindState = false
                        editingTrackerRecord = nil
                    })
                } else {
                    // Create new record
                    DailyTrackerFlowScreen(onClose: {
                        appState.showMindState = false
                    })
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: appState.showMindState) { newValue in
            // Clear editing record when sheet is dismissed
            if !newValue {
                editingTrackerRecord = nil
            }
        }
        .sheet(isPresented: $showTimeRippleSheet) {
            TimeRippleSheet(questions: vm.todayQuestions) { q in
                showTimeRippleSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    selectedRippleQuestion = q
                }
            }
        }
        .sheet(item: $selectedRippleQuestion) { q in
            let source = TimelineRepository.shared.getEntry(id: q.journal_now_id)
            let replies = TimelineRepository.shared.getReplies(for: q.id)
            CapsuleDetailSheet(question: q, sourceEntry: source, replies: replies, onReply: { text in
                vm.handleReply(questionId: q.id, replyText: text)
            }, onClose: {
                selectedRippleQuestion = nil
            }, lang: appState.lang)
            .environmentObject(appState)
            .environmentObject(vm)
        }

        .onAppear {
            // TimelineRecorder is now started in AppState.init() on app launch
            hasDynamicIsland = DynamicIslandSupport.hasDynamicIsland()
            // LiveActivityManager removed
            vm.load(date: appState.selectedDate)
            let dataIssues = LocationRepository.shared.validate()
            if !dataIssues.isEmpty { print("LocationDataIssues:\n\(dataIssues.joined(separator: "\n"))") }
            LocationService.shared.onAuthChange = { st in
                appState.locationAuthStatus = st
                appState.showLocationPermission = (st == .denied || st == .restricted)
                if st == .authorized && appState.selectedDate == DateUtilities.today {
                    // Logic moved to VM, but we keep this to update Live Activity initial state or handle permission changes dynamically
                    LocationService.shared.requestCurrentSnapshot { lat, lng, raw in
                         // The VM handles the data fetching now, but this callback ensures we react to permission changes
                         if lat != 0 {
                             WeatherService.shared.fetchCurrentWeather(lat: lat, lng: lng) { sym, _ in
                                 // LiveActivityManager removed
                             }
                         }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("gj_addresses_changed"))) { _ in
            LocationRepository.shared.reload()
            vm.refreshLocationMappings()
        }
        .onChange(of: appState.pendingLocation) { _ in }
        .onChange(of: appState.showPlaceNaming) { isShowing in
            if !isShowing { appState.pendingLocation = nil }
        }
        .onChange(of: appState.resolvedLocation) { newLoc in
            if let loc = newLoc { vm.applyResolvedLocation(loc); appState.resolvedLocation = nil }
        }
        .onChange(of: appState.selectedDate) { newValue in vm.load(date: newValue) }
        .onChange(of: vm.currentDate) { newValue in 
            // LiveActivity update removed
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("gj_edit_entry"))) { note in
            if let dict = note.userInfo as? [String: Any], let id = dict["id"] as? String, let content = dict["content"] as? String {
                vm.editEntryContent(id: id, newContent: content)
                appState.editingEntryId = nil
                appState.editingDraft = ""
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("gj_delete_entry"))) { note in
            if let dict = note.userInfo as? [String: Any], let id = dict["id"] as? String {
                vm.deleteEntry(id: id)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("gj_submit_input"))) { note in
            // Prevent handling input if we are in AI mode (handled by AIConversationScreen)
            guard appState.currentMode != .ai else { return }
            
            if let dict = note.userInfo as? [String: Any] {
                let text = dict["text"] as? String ?? ""
                let images = dict["images"] as? [UIImage]
                let videos = dict["videos"] as? [URL] // Legacy or unused
                let audio = dict["audio"] as? URL
                let duration = dict["duration"] as? String
                let files = dict["files"] as? [URL]
                
                if let qid = dict["replyQuestionId"] as? String, !qid.isEmpty {
                    vm.handleReply(questionId: qid, replyText: text, images: images, videos: videos, audio: audio, duration: duration, files: files)
                } else {
                    vm.handleTodaySubmit(text: text, images: images, videos: videos, audio: audio, duration: duration, files: files)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("gj_timeline_updated"))) { _ in
            if vm.currentDate == DateUtilities.today {
                vm.load(date: vm.currentDate)
            }
        }
    }

    private func scrollContent(proxy: ScrollViewProxy) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                if !hasDynamicIsland && appState.editingEntryId == nil {
                    DateWeatherHeader(dateText: formattedDate(vm.currentDate))
                        .matchedGeometryEffect(id: "mindHeader", in: mindNS)
                        .id("header")
                }
                // Daily Tracker Summary Card
                if let trackerRecord = vm.dailyTrackerRecord {
                    DailyTrackerSummaryCard(record: trackerRecord) {
                        // Open edit mode with existing record
                        editingTrackerRecord = trackerRecord
                        appState.showMindState = true
                    }
                    .id("tracker")
                }
                
                if vm.currentDate == DateUtilities.today && !vm.resonanceStats.isEmpty {
                    ResonanceHub(stats: vm.resonanceStats)
                        .id("resonance")
                }
                
                if !vm.todayQuestions.isEmpty {
                    // Logic to count replied
                    let repliedCount = vm.todayQuestions.filter { q in
                        if let fid = q.journal_future_id, !fid.isEmpty { return true }
                        // Ideally checking replies needs repo access or VM calculation.
                        // For display, we can assume VM should provide this stats or we check repository directly here (safe since it's local)
                        let replies = TimelineRepository.shared.getReplies(for: q.id)
                        return !replies.isEmpty
                    }.count
                    
                    TimeRippleView(repliedCount: repliedCount, totalCount: vm.todayQuestions.count) {
                        showTimeRippleSheet = true
                    }
                    .id("timeripple")
                }
                
                // Combined timeline items (journal entries + AI conversations) - sorted by time
                // Requirements: 4.10, 4.11, 5.3
                ForEach(vm.combinedDisplayItems) { item in
                    switch item {
                    case .timelineItem(let timelineItem):
                        switch timelineItem {
                        case .scene(let s):
                            SceneBlock(scene: s,
                                       questionEntries: MockDataService.questions,
                                       currentDateLabel: vm.currentDate,
                                       todayDate: DateUtilities.today,
                                       focusEntryId: appState.focusEntryId,
                                       onTagEntry: { id, cat in vm.tagEntry(id: id, category: cat) },
                                       onStartEdit: { id in
                                           var content: String? = nil
                                           for item in vm.items {
                                               switch item {
                                               case .scene(let s): if let e = s.entries.first(where: { $0.id == id }) { content = e.content }
                                               case .journey(let j): if let e = j.entries.first(where: { $0.id == id }) { content = e.content }
                                               }
                                               if content != nil { break }
                                           }
                                           appState.editingEntryId = id
                                           appState.editingDraft = content ?? ""
                                       },
                                       onEditLocation: {
                                           appState.pendingLocation = s.location
                                           appState.showPlaceNaming = true
                                       },
                                       onSubmitReply: { id, text in vm.handleReply(questionId: id, replyText: text) },
                                       editNamespace: editNS)
                            .id(s.id)
                        case .journey(let j):
                            JourneyBlockView(journey: j,
                                             questionEntries: MockDataService.questions,
                                             currentDateLabel: vm.currentDate,
                                             todayDate: DateUtilities.today,
                                             focusEntryId: appState.focusEntryId,
                                             onTagEntry: { id, cat in vm.tagEntry(id: id, category: cat) },
                                             onStartEdit: { id in
                                                 var content: String? = nil
                                                 for item in vm.items {
                                                     switch item {
                                                     case .scene(let s): if let e = s.entries.first(where: { $0.id == id }) { content = e.content }
                                                     case .journey(let j): if let e = j.entries.first(where: { $0.id == id }) { content = e.content }
                                                     }
                                                     if content != nil { break }
                                                 }
                                                 appState.editingEntryId = id
                                                 appState.editingDraft = content ?? ""
                                             },
                                             onEditDestination: {
                                                 appState.pendingLocation = j.destination
                                                 appState.showPlaceNaming = true
                                             },
                                             onSubmitReply: { id, text in vm.handleReply(questionId: id, replyText: text) },
                                             editNamespace: editNS)
                            .id(j.id)
                        }
                    case .aiConversation(let conversation):
                        // Only show AI conversation cards when in journal mode and collapsed
                        if appState.currentMode == .journal && appState.aiConversationCollapsed {
                            AIConversationSummaryCard(conversation: conversation, onTap: {
                                appState.setCurrentConversation(id: conversation.id)
                                appState.expandAIConversation()
                            }, onDelete: {
                                vm.deleteAIConversation(id: conversation.id)
                            })
                            .id("ai_\(conversation.id)")
                        }
                    }
                }
                
                Spacer().frame(height: 1).id("bottom")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: keyboard.height) { height in
            if height > 0 {
                // Wait a bit for layout to adjust then scroll to bottom
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
        .onChange(of: appState.focusEntryId) { newValue in
            if let id = newValue { withAnimation(.easeInOut) { proxy.scrollTo(id, anchor: .center) } }
        }
        .onAppear {
            if let id = appState.focusEntryId {
                DispatchQueue.main.async { withAnimation(.easeInOut) { proxy.scrollTo(id, anchor: .center) } }
            }
        }
    }

    @State private var placeSuggestions: [AddressMapping] = []
}

private func formattedDate(_ date: String) -> String {
    let comps = date.split(separator: ".")
    if comps.count == 3 {
        return "\(comps[1]).\(comps[2])"
    }
    return date
}

private func homeGradient(_ v: MindValence?) -> LinearGradient {
    let bg = Colors.background
    guard let v = v else { return LinearGradient(colors: [bg, bg], startPoint: .top, endPoint: .bottom) }
    
    func adaptive(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        return Color(uiColor: UIColor { trait in
            return trait.userInterfaceStyle == .dark ? .systemBackground : UIColor(red: red, green: green, blue: blue, alpha: 1)
        })
    }
    
    let colors: [Color]
    switch v {
    case .veryUnpleasant:
        colors = [adaptive(0.99, 0.95, 0.96), adaptive(1.0, 0.98, 0.98)]
    case .unpleasant:
        colors = [adaptive(1.0, 0.97, 0.98), bg]
    case .slightlyUnpleasant:
        colors = [adaptive(0.99, 0.98, 0.99), bg]
    case .neutral:
        colors = [bg, bg]
    case .slightlyPleasant:
        colors = [bg, adaptive(0.98, 1.0, 0.98)]
    case .pleasant:
        colors = [adaptive(0.97, 1.0, 0.98), bg]
    case .veryPleasant:
        colors = [adaptive(0.96, 1.0, 0.98), adaptive(0.98, 1.0, 0.99)]
    }
    return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
}
