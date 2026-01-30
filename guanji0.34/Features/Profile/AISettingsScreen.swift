import SwiftUI

/// Dedicated screen for AI-related configurations
/// Uses model tiers (fast, balanced, powerful) instead of individual models
public struct AISettingsScreen: View {
    @StateObject private var vm = AISettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                // Display Options Section
                Section {
                    Toggle(
                        Localization.tr("AI.Settings.ShowThinking"),
                        isOn: $vm.showThinkingProcess
                    )
                    .tint(Colors.indigo)
                } header: {
                    Text(Localization.tr("AI.Settings.DisplaySection"))
                } footer: {
                    Text(Localization.tr("AI.Settings.ThinkingFooter"))
                }
                
                // Model Tier Selection Section
                Section {
                    Picker(
                        Localization.tr("AI.Settings.ModelTier"),
                        selection: $vm.selectedModelTier
                    ) {
                        ForEach(vm.availableModelTiers, id: \.self) { tier in
                            Text(tier.displayName).tag(tier)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Colors.indigo)
                } header: {
                    Text(Localization.tr("AI.Settings.ModelSection"))
                } footer: {
                    Text(vm.selectedModelTier.description)
                }
            }
            .navigationTitle(Localization.tr("AI.Settings.Title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Localization.tr("Action.Done")) {
                        vm.saveSettings()
                        dismiss()
                    }
                    .disabled(vm.isSaving)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Localization.tr("cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Note: ModelTier.displayName and ModelTier.description are defined in ClaudeflareModels.swift

#if DEBUG
struct AISettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        AISettingsScreen()
    }
}
#endif
