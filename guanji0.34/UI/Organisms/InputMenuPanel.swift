import SwiftUI

public struct InputMenuPanel: View {
    public let onCamera: () -> Void
    public let onPhoto: () -> Void
    public let onFile: () -> Void
    public let onTimeCapsule: () -> Void
    public init(onCamera: @escaping () -> Void, onPhoto: @escaping () -> Void, onFile: @escaping () -> Void, onTimeCapsule: @escaping () -> Void) {
        self.onCamera = onCamera
        self.onPhoto = onPhoto
        self.onFile = onFile
        self.onTimeCapsule = onTimeCapsule
    }
    public var body: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                Button(action: onCamera) {
                    VStack(spacing: 6) { Image(systemName: "camera").foregroundColor(Colors.systemGray); Text(NSLocalizedString("camera", comment: "")).font(.system(size: 12, weight: .bold)).foregroundColor(Colors.slateText) }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.white.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.6)))
                }
                Button(action: onPhoto) {
                    VStack(spacing: 6) { Image(systemName: "photo").foregroundColor(Colors.systemGray); Text(NSLocalizedString("photo", comment: "")).font(.system(size: 12, weight: .bold)).foregroundColor(Colors.slateText) }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.white.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.6)))
                }
                Button(action: onFile) {
                    VStack(spacing: 6) { Image(systemName: "doc").foregroundColor(Colors.systemGray); Text(NSLocalizedString("file", comment: "")).font(.system(size: 12, weight: .bold)).foregroundColor(Colors.slateText) }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.white.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.6)))
                }
                Button(action: onTimeCapsule) {
                    VStack(spacing: 6) { Image(systemName: "hourglass").foregroundColor(Colors.systemGray); Text(NSLocalizedString("timeCapsule", comment: "")).font(.system(size: 12, weight: .bold)).foregroundColor(Colors.slateText) }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.white.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.6)))
                }
            }
        }
        .padding(16)
        .modifier(Materials.prism())
    }
}
