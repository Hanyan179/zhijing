import SwiftUI
import Combine

public struct ExpandedInputView: View {
    @ObservedObject var vm: InputViewModel
    @Binding var isPresented: Bool
    @FocusState private var isFocused: Bool
    @State private var localText: String = ""
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextEditor(text: $localText)
                    .font(.body)
                    .padding(12)
                    .focused($isFocused)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(Localization.tr("edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Colors.slateText)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        vm.text = localText
                        isPresented = false
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Colors.slateDark)
                    }
                }
            }
        }
        .onAppear {
            localText = vm.text
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}
