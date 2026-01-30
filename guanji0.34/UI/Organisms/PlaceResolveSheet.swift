import SwiftUI

public struct PlaceResolveSheet: View {
    public let initial: LocationVO
    public let existing: [AddressMapping]
    public var onCreate: (String, String) -> Void
    public var onAppend: (AddressMapping) -> Void
    @State private var name: String
    @State private var icon: String
    @Environment(\.dismiss) private var dismiss
    
    public init(initial: LocationVO, existing: [AddressMapping], onCreate: @escaping (String, String) -> Void, onAppend: @escaping (AddressMapping) -> Void) {
        self.initial = initial
        self.existing = existing
        self.onCreate = onCreate
        self.onAppend = onAppend
        _name = State(initialValue: initial.displayText)
        _icon = State(initialValue: initial.icon ?? "mappin")
    }
    
    private let icons = ["house", "building", "briefcase", "bag", "graduationcap", "heart", "tree", "airplane", "bed.double", "fork.knife", "mappin"]
    @State private var query: String = ""
    
    private var filtered: [AddressMapping] {
        if query.isEmpty { return existing }
        return existing.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(Localization.tr("nameThisPlace"))) {
                    TextField(Localization.tr("locationNamePlaceholder"), text: $name)
                    
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
                    
                    Button(action: { onCreate(name, icon) }) {
                        Text(Localization.tr("save"))
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                if !existing.isEmpty {
                    Section {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField(Localization.tr("searchPlace"), text: $query)
                            if !query.isEmpty {
                                Button(action: { query = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    Section(header: Text(Localization.tr("mappedLocations"))) {
                        ForEach(filtered, id: \.id) { m in
                            Button(action: { onAppend(m) }) {
                                HStack {
                                    Image(systemName: m.icon ?? "mappin")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    Text(m.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if m.name == name {
                                        Image(systemName: "checkmark").foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(Localization.tr("nameThisPlace"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.tr("cancel")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
