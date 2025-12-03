import SwiftUI

public struct TimelineScreen: View {
    @StateObject private var vm = TimelineViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var showCapsuleCreator = false
    @State private var contextState: ContextMenuState? = nil
    @State private var hasDynamicIsland = false
    public init() {}
    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                if !hasDynamicIsland {
                    DateWeatherHeader(dateText: formattedDate(vm.currentDate))
                }
                Button(action: { showCapsuleCreator = true }) {
                    HStack {
                        Image(systemName: "seal")
                        Text(Localization.tr("newCapsule"))
                    }
                }
                ResonanceHub(entries: vm.onThisDay, todayDate: ChronologyAnchor.TODAY_DATE)
                ForEach(Array(vm.items.enumerated()), id: \.element.id) { _, item in
                    switch item {
                    case .scene(let s):
                        SceneBlock(scene: s, questionEntries: MockDataService.questions, currentDateLabel: vm.currentDate, todayDate: ChronologyAnchor.TODAY_DATE, focusEntryId: appState.focusEntryId, onLongPress: { e in contextState = ContextMenuState(x: 180, y: 300, entryId: e.id, currentContent: e.content, type: e.type) })
                    case .journey(let j):
                        JourneyBlockView(journey: j, questionEntries: MockDataService.questions, currentDateLabel: vm.currentDate, todayDate: ChronologyAnchor.TODAY_DATE, focusEntryId: appState.focusEntryId, onLongPress: { e in contextState = ContextMenuState(x: 180, y: 300, entryId: e.id, currentContent: e.content, type: e.type) })
                    }
                }
                let todayEntries2: [JournalEntry] = vm.items.flatMap { item in
                    switch item { case .scene(let s): return s.entries; case .journey(let j): return j.entries }
                }
                MorningBriefing(items: todayEntries2)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: appState.focusEntryId) { newValue in
                if let id = newValue { withAnimation(.easeInOut) { proxy.scrollTo(id, anchor: .center) } }
            }
            .onAppear {
                if let id = appState.focusEntryId { DispatchQueue.main.async { withAnimation(.easeInOut) { proxy.scrollTo(id, anchor: .center) } } }
            }
        }
        .safeAreaInset(edge: .bottom) {
            InputDock()
        }
        .overlay(
            Group {
                if let state = contextState {
                    ContextMenuOverlay(state: state, onClose: { contextState = nil }, onSelect: { cat in vm.tagEntry(id: state.entryId, category: cat) }, onEdit: { new in vm.editEntryContent(id: state.entryId, newContent: new) }, lang: appState.lang)
                }
            }
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(destination: HistorySidebar()) { Image(systemName: "line.3.horizontal").foregroundColor(Colors.systemGray) }
            }
            ToolbarItem(placement: .principal) { EmptyView() }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ProfileScreen()) { Image(systemName: "person.crop.circle").foregroundColor(Colors.systemGray) }
            }
        }
        .sheet(isPresented: $showCapsuleCreator) {
            CapsuleCreatorSheet(onSave: { mode, prompt, date, sealed in
                vm.createCapsule(mode: mode, prompt: prompt, deliveryDate: date, sealed: sealed)
                showCapsuleCreator = false
            })
        }
        .onAppear { hasDynamicIsland = DynamicIslandSupport.hasDynamicIsland(); if hasDynamicIsland { LiveActivityManager.start(dateText: formattedDate(vm.currentDate), weatherSymbolName: "cloud.drizzle") }; vm.load(date: appState.selectedDate) }
        .onChange(of: appState.selectedDate) { newValue in vm.load(date: newValue) }
        .onChange(of: vm.currentDate) { newValue in if hasDynamicIsland { LiveActivityManager.update(dateText: formattedDate(newValue), weatherSymbolName: "cloud.drizzle") } }
    }
}

private func formattedDate(_ date: String) -> String {
    let comps = date.split(separator: ".")
    if comps.count == 3 {
        return "\(comps[1]).\(comps[2])"
    }
    return date
}
