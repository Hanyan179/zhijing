import SwiftUI
import Combine

/// Sidebar view for AI conversation history
/// Displays conversations grouped by day
/// Requirements: 2.1, 2.2, 2.3
public struct ConversationHistoryView: View {
    @StateObject private var vm = ConversationHistoryViewModel()
    @EnvironmentObject private var appState: AppState
    
    var onSelectConversation: ((String) -> Void)?
    var onNewConversation: (() -> Void)?
    var onExpandToSuperPage: (() -> Void)?
    
    @State private var searchText: String = ""
    
    public init(
        onSelectConversation: ((String) -> Void)? = nil,
        onNewConversation: (() -> Void)? = nil,
        onExpandToSuperPage: (() -> Void)? = nil
    ) {
        self.onSelectConversation = onSelectConversation
        self.onNewConversation = onNewConversation
        self.onExpandToSuperPage = onExpandToSuperPage
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header with New Conversation button
            headerView
            
            // Search bar
            searchBar
            
            // Conversations list
            if vm.groupedConversations.isEmpty {
                emptyStateView
            } else {
                conversationsList
            }
        }
        .background(Colors.background)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 50 {
                        onExpandToSuperPage?()
                    }
                }
        )
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text(formatYearMonth(Date()))
                .font(Typography.header)
                .foregroundColor(Colors.slateText)
            
            Spacer()
            
            Button(action: {
                onNewConversation?()
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Colors.indigo)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Colors.systemGray)
            TextField(Localization.tr("AI.SearchConversations"), text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(Colors.slate500)
            
            Text(Localization.tr("AI.NoConversations"))
                .font(Typography.body)
                .foregroundColor(Colors.slate500)
            
            Button(action: {
                onNewConversation?()
            }) {
                Text(Localization.tr("AI.StartConversation"))
                    .font(Typography.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Colors.indigo)
                    )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Conversations List
    
    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredGroups, id: \.date) { group in
                    ConversationDaySection(
                        date: group.date,
                        conversations: group.conversations,
                        currentConversationId: appState.currentConversationId,
                        onSelect: { id in
                            appState.setCurrentConversation(id: id)
                            onSelectConversation?(id)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Helpers
    
    private var filteredGroups: [ConversationDayGroup] {
        if searchText.isEmpty {
            return vm.groupedConversations
        }
        
        return vm.groupedConversations.compactMap { group in
            let filtered = group.conversations.filter { conv in
                (conv.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                conv.previewText.localizedCaseInsensitiveContains(searchText)
            }
            return filtered.isEmpty ? nil : ConversationDayGroup(date: group.date, conversations: filtered)
        }
    }
    
    private func formatYearMonth(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM"
        return f.string(from: date)
    }
}

// MARK: - Conversation Day Section

/// Section showing conversations for a specific day
/// Requirements: 2.2, 2.6
public struct ConversationDaySection: View {
    let date: String
    let conversations: [AIConversation]
    let currentConversationId: String?
    let onSelect: (String) -> Void
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day header
            Text(date)
                .font(Typography.caption)
                .foregroundColor(Colors.slate500)
                .padding(.leading, 4)
            
            // Conversation cards
            ForEach(conversations) { conversation in
                ConversationCard(
                    conversation: conversation,
                    isSelected: conversation.id == currentConversationId,
                    onTap: { onSelect(conversation.id) }
                )
            }
        }
    }
}

// MARK: - Conversation Card

/// Card displaying a single conversation preview
/// Requirements: 2.3
private struct ConversationCard: View {
    let conversation: AIConversation
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(conversation.title ?? Localization.tr("AI.NewConversation"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Colors.slateText)
                    .lineLimit(1)
                
                // Preview text
                if !conversation.previewText.isEmpty {
                    Text(conversation.previewText)
                        .font(Typography.caption)
                        .foregroundColor(Colors.slate500)
                        .lineLimit(2)
                }
                
                // Timestamp and multi-day indicator
                HStack {
                    Text(formatTime(conversation.updatedAt))
                        .font(.caption2)
                        .foregroundColor(Colors.slate500)
                    
                    if conversation.associatedDays.count > 1 {
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 10))
                            Text("\(conversation.associatedDays.count)")
                                .font(.caption2)
                        }
                        .foregroundColor(Colors.indigo)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Colors.indigo.opacity(0.1) : Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Colors.indigo : Color.clear, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - ViewModel

/// ViewModel for ConversationHistoryView
public final class ConversationHistoryViewModel: ObservableObject {
    @Published public var groupedConversations: [ConversationDayGroup] = []
    
    private let repository = AIConversationRepository.shared
    
    public init() {
        // Load conversations immediately on init
        loadConversations()
        
        // Listen for conversation updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConversationUpdate),
            name: Notification.Name("gj_ai_conversation_updated"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func loadConversations() {
        groupedConversations = repository.getConversationsGroupedByDay()
    }
    
    @objc private func handleConversationUpdate() {
        DispatchQueue.main.async {
            self.loadConversations()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ConversationHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationHistoryView()
            .environmentObject(AppState())
    }
}
#endif
