import SwiftUI
import Foundation

public struct ComponentGalleryScreen: View {
    @EnvironmentObject private var appState: AppState
    @State private var category: String = "basicComponents"
    private let categories: [String] = ["basicComponents", "compositeComponents", "statusComponents", "layoutComponents", "inputs", "charts", "media", "lists"]

    public init() {}
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("componentLibrary"))
            Picker("", selection: $category) {
                ForEach(categories, id: \.self) { key in Text(Localization.tr(key)).tag(key) }
            }
            .pickerStyle(.segmented)
            ScrollView {
                VStack(spacing: 12) {
                    switch category {
                    case "basicComponents": BasicComponentsSection()
                    case "compositeComponents": CompositeComponentsSection()
                    case "statusComponents": StatusComponentsSection()
                    case "layoutComponents": LayoutComponentsSection()
                    case "inputs": InputsGallerySection()
                    case "charts": ChartsGallerySection()
                    case "media": MediaGallerySection()
                    case "lists": ListsGallerySection()
                    default: BasicComponentsSection()
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .id(appState.lang.rawValue)
    }
}
