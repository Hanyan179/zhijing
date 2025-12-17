import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

public struct CapsuleCreatorSheet: View {
    public var onSave: ((String, String, Date, Bool, String?) -> Void)?
    public var onClose: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    
    @Binding var prompt: String
    @Binding var deliveryDate: Date
    @Binding var sealed: Bool
    @Binding var showSystemQuestion: Bool
    @Binding var systemQuestion: String
    
    // Attachments (Simplified for now as per refactor plan to focus on standard UI)
    // If original had attachments, I should probably keep them.
    private struct CapsuleAttachmentItem: Identifiable, Hashable { let id = UUID().uuidString; let type: String; let name: String }
    @State private var attachments: [CapsuleAttachmentItem] = []

    public init(prompt: Binding<String>, deliveryDate: Binding<Date>, sealed: Binding<Bool>, showSystemQuestion: Binding<Bool>, systemQuestion: Binding<String>, onSave: ((String, String, Date, Bool, String?) -> Void)? = nil, onClose: (() -> Void)? = nil) { 
        self._prompt = prompt
        self._deliveryDate = deliveryDate
        self._sealed = sealed
        self._showSystemQuestion = showSystemQuestion
        self._systemQuestion = systemQuestion
        self.onSave = onSave
        self.onClose = onClose 
    }
    
    public var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        DatePicker(Localization.tr("unlockDate"), selection: $deliveryDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                quickChip(Localization.tr("tomorrow"), days: 1)
                                quickChip(Localization.tr("nextWeek"), days: 7)
                                quickChip(Localization.tr("oneMonth"), days: 30)
                                quickChip(Localization.tr("threeMonths"), days: 90)
                                quickChip(Localization.tr("oneYear"), days: 365)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(Localization.tr("date"))
                }
                
                Section {
                    if showSystemQuestion {
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack(alignment: .topLeading) {
                                if systemQuestion.isEmpty {
                                    Text(Localization.tr("capsuleQuestionPlaceholder"))
                                        .foregroundColor(Colors.systemGray)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                }
                                TextEditor(text: $systemQuestion)
                                    .frame(minHeight: 80)
                            }
                            Button(action: {
                                withAnimation {
                                    showSystemQuestion = false
                                    systemQuestion = ""
                                }
                            }) {
                                Text(Localization.tr("removeSystemQuestion"))
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        Button(action: { withAnimation { showSystemQuestion = true } }) {
                            Label(Localization.tr("addSystemQuestion"), systemImage: "questionmark.bubble")
                        }
                    }
                } header: {
                    Text(Localization.tr("systemQuestion"))
                }
                
                Section {
                    ZStack(alignment: .topLeading) {
                        if prompt.isEmpty {
                            Text(Localization.tr("capsuleMessagePlaceholder"))
                                .foregroundColor(Colors.systemGray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $prompt)
                            .frame(minHeight: 120)
                    }
                } header: {
                    Text(Localization.tr("message"))
                }
                
                // Attachments section placeholder if needed
                 if !attachments.isEmpty {
                    Section {
                        ForEach(attachments) { att in
                            HStack {
                                Image(systemName: att.type == "photo" ? "photo" : "doc")
                                Text(att.name)
                            }
                        }
                        .onDelete { idx in attachments.remove(atOffsets: idx) }
                    }
                }
            }
            .navigationTitle(Localization.tr("newCapsule"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.tr("cancel")) {
                        if let c = onClose { c() } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.tr("sealCapsule")) {
                        onSave?("text", prompt, deliveryDate, sealed, showSystemQuestion ? systemQuestion : nil)
                    }
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(action: { hideKeyboard() }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
        }
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in }
        #endif
    }
    
    private func quickChip(_ title: String, days: Int) -> some View {
        Button(action: {
            deliveryDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Colors.slateDark)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}
