import SwiftUI

/// Dedicated screen for AI-related configurations
/// Requirements: 5.1-5.5
public struct AISettingsScreen: View {
    @StateObject private var vm = AISettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                // API Configuration Section
                Section {
                    SecureField(
                        Localization.tr("AI.Settings.EnterAPIKey"),
                        text: $vm.apiKey
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    
                    if let error = vm.apiKeyError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(Colors.red)
                    }
                } header: {
                    Text(Localization.tr("AI.Settings.APISection"))
                } footer: {
                    Text(Localization.tr("AI.Settings.APIFooter"))
                }
                
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
                
                // Model Selection Section
                Section {
                    Picker(
                        Localization.tr("AI.Settings.Model"),
                        selection: $vm.selectedModel
                    ) {
                        ForEach(vm.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Colors.indigo)
                } header: {
                    Text(Localization.tr("AI.Settings.ModelSection"))
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

#if DEBUG
struct AISettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        AISettingsScreen()
    }
}
#endif
