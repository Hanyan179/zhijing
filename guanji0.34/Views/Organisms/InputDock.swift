import SwiftUI
import UIKit

public struct InputDock: View {
    @StateObject private var vm = InputViewModel()
    @State private var showCapsuleCreator = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var permissionAlert: String? = nil
    @FocusState private var inputFocused: Bool
    @State private var inputHeight: CGFloat = 36
    public init() {}
    public var body: some View {
        VStack(spacing: 8) {
            if let ctx = vm.replyContext {
                ReplyContextBar(text: ctx, onCancel: { vm.replyContext = nil })
            }
            if !vm.attachments.isEmpty { AttachmentsBar(items: vm.attachments, onRemove: { vm.removeAttachment(id: $0) }) }
            InputQuickActions(onGallery: { handleGallery() }, onCamera: { handleCamera() }, onRecord: { vm.toggleRecording() }, onTimeCapsule: { showCapsuleCreator = true }, onMood: { })
                .padding(.horizontal, 16)
            DockContainer(isMenuOpen: false, isReplyMode: vm.replyContext != nil) {
                ZStack(alignment: .leading) {
                    GrowingTextEditor(text: $vm.text, dynamicHeight: $inputHeight)
                        .frame(maxWidth: .infinity)
                        .frame(height: min(max(inputHeight, 36), 160))
                        .focused($inputFocused)
                    if vm.text.isEmpty { Text(Localization.tr("placeholder")).foregroundColor(Color(.placeholderText)).padding(.horizontal, 8) }
                }
                SubmitButton(hasText: !vm.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, onClick: { vm.submit(); inputFocused = false })
            }
            if vm.isRecording {
                RecordingBar(isRecording: vm.isRecording, duration: vm.recordingSeconds, onStart: { vm.startRecording() }, onStop: { vm.stopRecording() }, onCancel: { vm.cancelRecording() })
                    .padding(.horizontal, 16)
            }
        }
        .animation(.easeInOut, value: inputFocused)
        .sheet(isPresented: $showCapsuleCreator) {
            CapsuleCreatorSheet(onSave: { mode, prompt, date, sealed in /* delegate to vm if needed */ showCapsuleCreator = false })
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerSheet { imgs in
                vm.addPhoto(name: Localization.tr("photo"))
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraCaptureSheet { img in
                if img != nil { vm.addPhoto(name: Localization.tr("photo")) }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(action: { inputFocused = false; UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }) { Image(systemName: "keyboard.chevron.compact.down").foregroundColor(Colors.systemGray) }
            }
        }
        .alert(permissionAlert ?? "", isPresented: Binding(get: { permissionAlert != nil }, set: { _ in permissionAlert = nil })) {
            Button(Localization.tr("ok"), action: { permissionAlert = nil })
        }
    }

    private func handleGallery() {
        PermissionsService.ensurePhotoAuthorized { granted in
            if granted { showPhotoPicker = true } else { permissionAlert = NSLocalizedString("permPhotoDenied", comment: "") }
        }
    }
    private func handleCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { permissionAlert = NSLocalizedString("permCameraDenied", comment: ""); return }
        PermissionsService.ensureCameraAuthorized { granted in
            if granted { showCamera = true } else { permissionAlert = NSLocalizedString("permCameraDenied", comment: "") }
        }
    }
}
