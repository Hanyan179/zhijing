import Foundation
import SwiftUI

public enum HistoryContext {
    case timeline
    case aiConversation // Future proofing
    case global // Direct entry to super page
    
    var title: String {
        switch self {
        case .timeline: return "Time Travel"
        case .aiConversation: return "Chat History"
        case .global: return "All Memories"
        }
    }
    
    var icon: String {
        switch self {
        case .timeline: return "clock.arrow.circlepath"
        case .aiConversation: return "bubble.left.and.bubble.right"
        case .global: return "archivebox"
        }
    }
}
