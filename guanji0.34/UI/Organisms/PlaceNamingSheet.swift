import SwiftUI

public struct PlaceNamingSheet: View {
    public let initial: LocationVO
    public var onSave: (String, String) -> Void
    public var onClose: () -> Void
    @State private var name: String
    @State private var icon: String
    
    public init(initial: LocationVO, onSave: @escaping (String, String) -> Void, onClose: @escaping () -> Void) {
        self.initial = initial
        self.onSave = onSave
        self.onClose = onClose
        _name = State(initialValue: initial.displayText)
        _icon = State(initialValue: initial.icon ?? "mappin")
    }
    
    private let icons = ["house", "building", "briefcase", "bag", "graduationcap", "heart", "tree", "airplane", "bed.double", "fork.knife", "mappin"]
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(Localization.tr("nameThisPlace"))) {
                    TextField(Localization.tr("locationNamePlaceholder"), text: $name)
                }
                
                Section(header: Text(Localization.tr("appearance"))) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(icons, id: \.self) { i in
                                Button(action: { icon = i }) {
                                    Image(systemName: i)
                                        .font(.title2)
                                        .foregroundColor(icon == i ? .white : .primary)
                                        .frame(width: 44, height: 44)
                                        .background(icon == i ? Color.blue : Color(.systemGray6))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    Button(action: { onSave(name, icon) }) {
                        Text(Localization.tr("save"))
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle(Localization.tr("nameThisPlace"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.tr("cancel"), action: onClose)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.tr("save"), action: { onSave(name, icon) })
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
