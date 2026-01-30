import SwiftUI

public struct MindStateFlowScreen: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = MindStateViewModel()
    @Environment(\.dismiss) private var dismiss
    public let onClose: () -> Void
    
    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                switch vm.step {
                case 1:
                    Section(header: Text(Localization.tr("mind_select_intensity"))) {
                        VStack(alignment: .center, spacing: 24) {
                            // Mood Icon
                            if #available(iOS 17.0, *) {
                                Image(systemName: vm.valenceSegment.iconName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(valenceAccent(vm.valenceSegment))
                                    .symbolEffect(.bounce, value: vm.valenceSegment)
                            } else {
                                Image(systemName: vm.valenceSegment.iconName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(valenceAccent(vm.valenceSegment))
                            }
                            
                            Text(Localization.tr(vm.valenceSegment.titleKey))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(valenceAccent(vm.valenceSegment))
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            ThickSlider(value: $vm.valenceValue, range: 0...100, step: 1, leftText: Localization.tr(MindValence.veryUnpleasant.titleKey), rightText: Localization.tr(MindValence.veryPleasant.titleKey), accent: valenceAccent(vm.valenceSegment))
                                .frame(height: 44)
                        }
                        .padding(.vertical, 20)
                    }
                    .listRowBackground(valenceAccent(vm.valenceSegment).opacity(0.1))
                    
                case 2:
                    Section(header: Text(Localization.tr("mind_select_labels"))) {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                                ForEach(vm.filteredLabels, id: \.id) { item in
                                    let selected = vm.selectedLabels.contains(item.id)
                                    TagChip(text: Localization.tr(item.key), selected: selected, accent: valenceAccent(vm.valenceSegment))
                                        .onTapGesture { vm.toggleLabel(item.id) }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                case 3:
                    Section(header: Text(Localization.tr("mind_select_influences"))) {
                        let accent = valenceAccent(vm.valenceSegment)
                        InfluenceSection(titleKey: "mind_cat_identity", items: [.identity, .spirituality], selected: vm.selectedInfluences, accent: accent, onToggle: vm.toggleInfluence)
                        InfluenceSection(titleKey: "mind_cat_social", items: [.social, .community, .friends, .family, .relationships, .partner, .dating], selected: vm.selectedInfluences, accent: accent, onToggle: vm.toggleInfluence)
                        InfluenceSection(titleKey: "mind_cat_environment", items: [.weather, .home, .education, .work, .tasks, .money, .health, .fitness], selected: vm.selectedInfluences, accent: accent, onToggle: vm.toggleInfluence)
                    }
                    
                default:
                    EmptyView()
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.tr("cancel")) {
                        onClose()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if vm.step < 3 {
                        Button(Localization.tr("next")) {
                            withAnimation { vm.step += 1 }
                        }
                    } else {
                        Button(Localization.tr("done")) {
                            complete()
                        }
                    }
                }
                
                if vm.step > 1 {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { withAnimation { vm.step -= 1 } }) {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
            }
        }
    }
    
    private var navTitle: String {
        switch vm.step {
        case 1: return Localization.tr("mood")
        case 2: return Localization.tr("mind_select_labels")
        case 3: return Localization.tr("mind_select_influences")
        default: return ""
        }
    }
    
    private func complete() {
        let res = vm.finalize()
        let repo = MindStateRepository()
        let rec = MindStateRecord(date: appState.selectedDate, valenceValue: Int(vm.valenceValue), labels: res.labels, influences: res.influences)
        repo.save(rec)
        appState.homeValence = vm.valenceSegment
        onClose()
    }
}

struct ValenceSlider: View {
    @Binding var value: Double
    var onEnd: (() -> Void)? = nil
    var onChange: ((Double) -> Void)? = nil
    var body: some View {
        VStack(spacing: 12) {
            Slider(value: $value, in: 0...100, step: 1, onEditingChanged: { editing in
                if !editing {
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    onEnd?()
                }
            })
            .tint(Colors.systemGray)
            #if os(macOS)
            .onChange(of: value) { _, v in onChange?(v) }
            #else
            .onChange(of: value) { v in onChange?(v) }
            #endif
            HStack {
                Text(Localization.tr(MindValence.veryUnpleasant.titleKey)).font(.caption2)
                Spacer()
                Text(Localization.tr(MindValence.veryPleasant.titleKey)).font(.caption2)
            }
        }
    }
}

struct TagChip: View {
    let text: String
    let selected: Bool
    let accent: Color
    var body: some View {
            Text(text)
                .font(.subheadline)
                .foregroundColor(selected ? .white : Colors.slateDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            	.background(selected ? accent : Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(selected ? Color.clear : Colors.slateLight, lineWidth: 1))
    }
}

struct HandleCapsule: View {
    let color: Color
    var body: some View {
        Capsule()
            .fill(color.opacity(0.12))
            .frame(width: 44, height: 6)
            .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 0.5))
            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
            .padding(.top, 10)
    }
}

private func valenceGradient(_ v: MindValence) -> LinearGradient {
    let colors: [Color]
    switch v {
    case .veryUnpleasant:
        colors = [Color(red: 0.98, green: 0.92, blue: 0.93), Color(red: 0.99, green: 0.95, blue: 0.96)]
    case .unpleasant:
        colors = [Color(red: 0.99, green: 0.93, blue: 0.94), Color(red: 1.0, green: 0.96, blue: 0.97)]
    case .slightlyUnpleasant:
        colors = [Color(red: 0.99, green: 0.96, blue: 0.97), Color.white]
    case .neutral:
        colors = [Color.white, Color.white]
    case .slightlyPleasant:
        colors = [Color.white, Color(red: 0.96, green: 1.0, blue: 0.96)]
    case .pleasant:
        colors = [Color(red: 0.94, green: 0.99, blue: 0.95), Color(red: 0.97, green: 1.0, blue: 0.97)]
    case .veryPleasant:
        colors = [Color(red: 0.92, green: 0.99, blue: 0.94), Color(red: 0.96, green: 1.0, blue: 0.96)]
    }
    return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
}

private func valenceAccent(_ v: MindValence) -> Color {
    switch v {
    case .veryUnpleasant, .unpleasant:
        return Color(red: 0.90, green: 0.50, blue: 0.55)
    case .slightlyUnpleasant:
        return Color(red: 0.94, green: 0.60, blue: 0.64)
    case .neutral:
        return Colors.systemGray
    case .slightlyPleasant:
        return Color(red: 0.38, green: 0.74, blue: 0.52)
    case .pleasant, .veryPleasant:
        return Color(red: 0.32, green: 0.68, blue: 0.50)
    }
}

struct InfluenceSection: View {
    let titleKey: String
    let items: [MindInfluence]
    let selected: Set<MindInfluence>
    let accent: Color
    let onToggle: (MindInfluence) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.tr(titleKey)).font(.subheadline).foregroundColor(Colors.slateText)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                ForEach(items) { inf in
                    let isSel = selected.contains(inf)
                    TagChip(text: Localization.tr(inf.key), selected: isSel, accent: accent)
                        .onTapGesture { onToggle(inf) }
                }
            }
        }
    }
}
