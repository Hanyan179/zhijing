import SwiftUI
import AVFoundation

#if canImport(UIKit)
import PhotosUI

public struct PhotoPickerSheet: UIViewControllerRepresentable {
    public var onPick: ([UIImage]) -> Void
    public init(onPick: @escaping ([UIImage]) -> Void) { self.onPick = onPick }
    public func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }
    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 5
        config.filter = .images
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = context.coordinator
        return vc
    }
    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    public final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let onPick: ([UIImage]) -> Void
        init(onPick: @escaping ([UIImage]) -> Void) { self.onPick = onPick }
        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            var images: [UIImage] = []
            let group = DispatchGroup()
            for r in results {
                if r.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    r.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                        if let img = obj as? UIImage { images.append(img) }
                        group.leave()
                    }
                }
            }
            group.notify(queue: .main) { self.onPick(images) }
            picker.dismiss(animated: true)
        }
    }
}

public struct CameraCaptureSheet: UIViewControllerRepresentable {
    public var onCapture: (UIImage?, URL?) -> Void
    public init(onCapture: @escaping (UIImage?, URL?) -> Void) { self.onCapture = onCapture }
    public func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.mediaTypes = ["public.image", "public.movie"]
        vc.cameraCaptureMode = .photo
        vc.videoQuality = .typeHigh
        vc.delegate = context.coordinator
        return vc
    }
    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    public final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onCapture: (UIImage?, URL?) -> Void
        init(onCapture: @escaping (UIImage?, URL?) -> Void) { self.onCapture = onCapture }
        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[.originalImage] as? UIImage {
                onCapture(img, nil)
            } else if let url = info[.mediaURL] as? URL {
                onCapture(nil, url)
            } else {
                onCapture(nil, nil)
            }
            picker.dismiss(animated: true)
        }
        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCapture(nil, nil)
            picker.dismiss(animated: true)
        }
    }
}
#endif
