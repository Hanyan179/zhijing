import SwiftUI

/// Collapsible section for displaying AI reasoning/thinking process
/// Requirements: 10.3, 10.4
public struct ThinkingSection: View {
    let content: String
    @State private var isExpanded: Bool = false
    
    public init(content: String) {
        self.content = content
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "brain")
                        .font(.system(size: 14))
                        .foregroundColor(Colors.violet)
                    
                    Text(Localization.tr("AI.ThinkingProcess"))
                        .font(Typography.caption)
                        .foregroundColor(Colors.violet)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Colors.violet)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Colors.violet.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            
            // Expandable content
            if isExpanded {
                Text(content)
                    .font(Typography.caption)
                    .foregroundColor(Colors.slate600)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Colors.slateLight.opacity(0.5))
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Streaming Thinking Section

/// Thinking section that updates during streaming
public struct StreamingThinkingSection: View {
    let content: String
    @State private var isExpanded: Bool = true  // Default expanded during streaming
    @State private var isPulsing: Bool = false
    
    public init(content: String) {
        self.content = content
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with streaming indicator
            HStack(spacing: 6) {
                // Animated brain icon (iOS 16.1+ compatible)
                Image(systemName: "brain")
                    .font(.system(size: 14))
                    .foregroundColor(Colors.violet)
                    .opacity(isPulsing ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
                    .onAppear { isPulsing = true }
                
                Text(Localization.tr("AI.Thinking"))
                    .font(Typography.caption)
                    .foregroundColor(Colors.violet)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Colors.violet)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Colors.violet.opacity(0.15))
            )
            
            // Streaming content
            if isExpanded && !content.isEmpty {
                Text(content)
                    .font(Typography.caption)
                    .foregroundColor(Colors.slate600)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Colors.slateLight.opacity(0.5))
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#if DEBUG
struct ThinkingSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ThinkingSection(content: "Let me think about this question. The user is asking about Swift programming, so I should provide a clear and helpful response with code examples if needed.")
            
            StreamingThinkingSection(content: "Analyzing the request...")
        }
        .padding()
    }
}
#endif
