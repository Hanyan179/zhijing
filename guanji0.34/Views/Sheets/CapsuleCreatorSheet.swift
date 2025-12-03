import SwiftUI

public struct CapsuleCreatorSheet: View {
    public var onSave: ((String, String, Date, Bool) -> Void)?
    @State private var mode: String = "text"
    @State private var prompt: String = ""
    @State private var deliveryDate: Date = Date().addingTimeInterval(24*60*60)
    @State private var sealed: Bool = true
    private struct CapsuleAttachmentItem: Identifiable, Hashable { let id = UUID().uuidString; let type: String; let name: String }
    @State private var attachments: [CapsuleAttachmentItem] = []
    public init(onSave: ((String, String, Date, Bool) -> Void)? = nil) { self.onSave = onSave }
    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "hourglass").foregroundColor(Colors.systemGray)
                Text(NSLocalizedString("newCapsule", comment: "")).font(.title3).bold()
                Spacer()
                Button(action: { }) { Image(systemName: "xmark").foregroundColor(Colors.systemGray) }
            }
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
                VStack(spacing: 12) {
                    CapsuleTextEditor(text: $prompt, onAddPhoto: { attachments.append(CapsuleAttachmentItem(type: "photo", name: NSLocalizedString("photo", comment: ""))) }, onAddFile: { attachments.append(CapsuleAttachmentItem(type: "file", name: NSLocalizedString("file", comment: ""))) }, onCollapse: { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) })
                        .frame(height: 140)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
                    if !attachments.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(attachments) { att in
                                    HStack(spacing: 6) {
                                        Image(systemName: att.type == "photo" ? "photo" : "doc").foregroundColor(Colors.systemGray)
                                        Text(att.name).font(.system(size: 12)).foregroundColor(Colors.slateText)
                                        Button(action: { attachments.removeAll { $0.id == att.id } }) { Image(systemName: "xmark.circle.fill").foregroundColor(Color(.systemGray3)) }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.85))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    VStack(spacing: 10) {
                        HStack { Image(systemName: "calendar").foregroundColor(Colors.systemGray); Text(NSLocalizedString("unlockDate", comment: "")); Spacer(); Text(deliveryDate, style: .date).font(.system(size: 14, weight: .bold)) }
                        HStack(spacing: 8) {
                            quickChip(NSLocalizedString("tomorrow", comment: ""), days: 1)
                            quickChip(NSLocalizedString("nextWeek", comment: ""), days: 7)
                            quickChip(NSLocalizedString("oneMonth", comment: ""), days: 30)
                            quickChip(NSLocalizedString("threeMonths", comment: ""), days: 90)
                            quickChip(NSLocalizedString("oneYear", comment: ""), days: 365)
                        }
                        DatePicker("", selection: $deliveryDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
                .padding(16)
            }
            Button(action: { onSave?(mode, prompt, deliveryDate, sealed) }) {
                Text(NSLocalizedString("sealCapsule", comment: "")).font(.system(size: 16, weight: .bold)).frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
        }
        .padding(20)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Menu {
                    Button(action: { attachments.append(CapsuleAttachmentItem(type: "photo", name: NSLocalizedString("photo", comment: ""))) }) { Label(NSLocalizedString("photo", comment: ""), systemImage: "photo") }
                    Button(action: { attachments.append(CapsuleAttachmentItem(type: "file", name: NSLocalizedString("file", comment: ""))) }) { Label(NSLocalizedString("file", comment: ""), systemImage: "doc") }
                } label: {
                    Image(systemName: "plus").foregroundColor(Colors.systemGray)
                }
                Spacer()
                Button(action: { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }) { Image(systemName: "keyboard.chevron.compact.down").foregroundColor(Colors.systemGray) }
            }
        }
    }
    private func quickChip(_ title: String, days: Int) -> some View {
        Button(action: { deliveryDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date() }) {
            Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 6).background(Colors.slateDark).clipShape(Capsule())
        }
    }
    private func chipButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) { Image(systemName: title == NSLocalizedString("photo", comment: "") ? "photo" : "doc.text").foregroundColor(Colors.systemGray); Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(Colors.slateText) }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.6)))
        }
    }
}
