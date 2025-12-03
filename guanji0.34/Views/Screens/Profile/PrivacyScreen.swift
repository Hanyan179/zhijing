import SwiftUI

public struct PrivacyScreen: View {
    @ObservedObject public var vm: ProfileViewModel
    @EnvironmentObject private var appState: AppState
    public init(vm: ProfileViewModel) { self.vm = vm }
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("privacyTitle"))
            ListGroup {
                VStack(alignment: .leading, spacing: 8) {
                    HStack { Text(Localization.tr("photoLibrary")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText); Spacer(); ToggleSwitch(checked: $vm.photoEnabled).onChange(of: vm.photoEnabled) { PermissionsService.photoEnabled = $0 } }
                    Text(Localization.tr("permPhotoDesc")).font(.system(size: 11)).foregroundColor(Colors.systemGray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)

                VStack(alignment: .leading, spacing: 8) {
                    HStack { Text(Localization.tr("camera")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText); Spacer(); ToggleSwitch(checked: $vm.cameraEnabled).onChange(of: vm.cameraEnabled) { PermissionsService.cameraEnabled = $0 } }
                    Text(Localization.tr("permCameraDesc")).font(.system(size: 11)).foregroundColor(Colors.systemGray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)

                VStack(alignment: .leading, spacing: 8) {
                    HStack { Text(Localization.tr("location")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText); Spacer(); ToggleSwitch(checked: $vm.locationServicesEnabled) }
                    Text(Localization.tr("permLocationDesc")).font(.system(size: 11)).foregroundColor(Colors.systemGray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)

                VStack(alignment: .leading, spacing: 8) {
                    HStack { Text(Localization.tr("microphone")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText); Spacer(); ToggleSwitch(checked: $vm.micEnabled) }
                    Text(Localization.tr("permMicDesc")).font(.system(size: 11)).foregroundColor(Colors.systemGray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            Text(Localization.tr("privacyFooter")).font(.system(size: 11)).foregroundColor(Colors.systemGray).padding(.horizontal, 20)
        }
        .id(appState.lang.rawValue)
    }
}
