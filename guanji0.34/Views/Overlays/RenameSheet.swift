import SwiftUI

public struct RenameSheet: View {
    public let vo: LocationVO
    public let onClose: () -> Void
    public let onConfirm: (String) -> Void
    public let lang: Lang
    @State private var name: String = ""
    public init(vo: LocationVO, onClose: @escaping () -> Void, onConfirm: @escaping (String) -> Void, lang: Lang) { self.vo = vo; self.onClose = onClose; self.onConfirm = onConfirm; self.lang = lang }
    public var body: some View {
        ZStack {
            Colors.slateLight.opacity(0.5).ignoresSafeArea().onTapGesture { onClose() }
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle").foregroundColor(Colors.slatePrimary)
                    Text(Localization.tr("nameThisPlace", lang: lang)).font(.system(size: 14, weight: .bold))
                }
                Text("\(vo.displayText) " + Localization.tr("rawLabel", lang: lang)).font(.system(size: 12, weight: .regular, design: .monospaced)).foregroundColor(Colors.systemGray).frame(maxWidth: .infinity, alignment: .leading).padding(8).background(Colors.slateLight).clipShape(RoundedRectangle(cornerRadius: 12))
                TextField(Localization.tr("locationNamePlaceholder", lang: lang), text: $name)
                    #if canImport(UIKit)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    #endif
                    .padding(12)
                    .background(Colors.cardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Colors.slateLight))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                HStack(spacing: 12) {
                    Button(Localization.tr("cancel", lang: lang)) { onClose() }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Colors.slateLight)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Button(Localization.tr("save", lang: lang)) {
                        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { onConfirm(name) }
                        onClose()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Colors.slateDark)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .frame(maxWidth: 360)
        }
        .zIndex(100)
    }
}
