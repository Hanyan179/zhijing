import SwiftUI

/// The main entry point (Container) for the History Feature.
/// It manages the transition between the specific context view (Sidebar) and the Super Page (Full Screen).
/// Requirements: 1.2, 2.1 - Sidebar switches content based on current mode
public struct HistorySidebar: View {
    @EnvironmentObject private var appState: AppState
    
    // The context in which this sidebar is opened
    var context: HistoryContext
    
    // Controlled by the parent (TimelineScreen) to handle layout expansion
    @Binding var isExpanded: Bool
    
    // Optional callback to close the sidebar entirely (from TimelineScreen parent state)
    var onRequestClose: (() -> Void)?
    
    public init(context: HistoryContext = .timeline, isExpanded: Binding<Bool>, onRequestClose: (() -> Void)? = nil) {
        self.context = context
        self._isExpanded = isExpanded
        self.onRequestClose = onRequestClose
    }
    
    public var body: some View {
        ZStack {
            if isExpanded {
                // The "Super Page"
                GlobalHistoryView(onClose: {
                    withAnimation {
                        isExpanded = false
                        onRequestClose?()
                    }
                })
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                // Show appropriate sidebar based on current mode - Requirements 1.2, 2.1
                if appState.currentMode == .ai {
                    ConversationHistoryView(
                        onSelectConversation: { _ in
                            onRequestClose?()
                        },
                        onNewConversation: {
                            appState.currentConversationId = nil
                            onRequestClose?()
                        },
                        onExpandToSuperPage: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isExpanded = true
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(0)
                } else {
                    TimelineHistoryView(onExpandToSuperPage: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isExpanded = true
                        }
                    }, onSelectDate: {
                        onRequestClose?()
                    })
                    .transition(.opacity)
                    .zIndex(0)
                }
            }
        }
        .background(Colors.background)
    }
}
