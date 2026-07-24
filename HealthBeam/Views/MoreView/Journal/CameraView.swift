import SwiftUI
@preconcurrency import AVFoundation
import UIKit
import Combine
struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var cameraService = CameraService()
    var onPhotoTaken: (UIImage) -> Void
    var body: some View {
        ZStack {
            CameraPreview(session: cameraService.session)
                .ignoresSafeArea()

            if let image = cameraService.capturedImage {
                PhotoPreviewView(
                    image: image,
                    onRetake: { cameraService.capturedImage = nil },
                    onUse: {
                        onPhotoTaken(image)
                        dismiss()
                    }
                )
            } else {
                CameraControlsView(
                    flashMode: cameraService.flashMode,
                    onDismiss: { dismiss() },
                    onToggleFlash: { cameraService.toggleFlash() },
                    onCapture: { cameraService.capturePhoto() },
                    onSwitchCamera: { cameraService.switchCamera() }
                )
            }

            if let errorMessage = cameraService.errorMessage {
                errorOverlay(message: errorMessage)
            }
        }
        .task {
            await cameraService.start()
        }
        .onDisappear(perform: cameraService.stop)
    }
    @ViewBuilder func errorOverlay(message: String) -> some View {
        VStack {
            Text("Camera Error")
                .font(.title).bold()
            Text(message)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .padding()
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(20)
        .foregroundColor(.white)
    }

    struct CameraControlsView: View {
        let flashMode: AVCaptureDevice.FlashMode
        let onDismiss: () -> Void
        let onToggleFlash: () -> Void
        let onCapture: () -> Void
        let onSwitchCamera: () -> Void

        var body: some View {
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark").font(.title2)
                    }
                    Spacer()
                    Button(action: onToggleFlash) {
                        Image(systemName: flashMode.iconName).font(.title2)
                    }
                }
                .foregroundColor(.white)
                .padding(20)

                Spacer()

                HStack {
                    Spacer()
                    Button(action: onCapture) {
                        ZStack {
                            Circle().fill(Color.white).frame(width: 70, height: 70)
                            Circle().stroke(Color.white, lineWidth: 4).frame(width: 80, height: 80)
                        }
                    }
                    Spacer()
                    Button(action: onSwitchCamera) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera.fill").font(.largeTitle)
                    }
                }
                .foregroundColor(.white)
                .padding(20)
            }
        }
    }

    struct PhotoPreviewView: View {
        let image: UIImage
        let onRetake: () -> Void
        let onUse: () -> Void

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()

                VStack {
                    Spacer()
                    HStack {
                        Button("Retake", action: onRetake)
                        Spacer()
                        Button("Use Photo", action: onUse)
                            .bold()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(30)
                    .background(Color.black.opacity(0.5))
                }
            }
        }
    }

    struct CameraPreview: UIViewRepresentable {
        let session: AVCaptureSession

        func makeUIView(context: Context) -> UIView {
            let view = UIView()
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            return view
        }

        func updateUIView(_ uiView: UIView, context: Context) {
            (uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer)?.frame = uiView.bounds
        }
    }

    @MainActor
    class CameraService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
        @Published var capturedImage: UIImage?
        @Published var flashMode: AVCaptureDevice.FlashMode = .off
        @Published var errorMessage: String?

        let session = AVCaptureSession()
        private var photoOutput = AVCapturePhotoOutput()
        private var currentCameraInput: AVCaptureDeviceInput?

        func start() async {
            guard await checkPermissions() else { return }
            setupSession()
            Task.detached(priority: .userInitiated) {
                await self.session.startRunning()
            }
        }

        func stop() {
            if session.isRunning {
                session.stopRunning()
            }
        }

        private func checkPermissions() async -> Bool {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                return true
            case .notDetermined:
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if !granted {
                    errorMessage = "Camera permission was not granted."
                }
                return granted
            default:
                errorMessage = "Please go to Settings to allow camera access."
                return false
            }
        }

        private func setupSession() {
            session.beginConfiguration()
            session.sessionPreset = .photo

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                errorMessage = "No camera found."
                session.commitConfiguration()
                return
            }

            if session.canAddInput(input) {
                session.addInput(input)
                currentCameraInput = input
            }

            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }

            session.commitConfiguration()
        }

        func switchCamera() {
            guard let currentInput = currentCameraInput else { return }

            session.beginConfiguration()
            session.removeInput(currentInput)

            let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
            guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
                session.addInput(currentInput)
                session.commitConfiguration()
                return
            }

            if session.canAddInput(newInput) {
                session.addInput(newInput)
                currentCameraInput = newInput
            } else {
                session.addInput(currentInput) 
            }

            session.commitConfiguration()
        }

        func toggleFlash() {
            guard let device = currentCameraInput?.device, device.hasFlash else { return }
            do {
                try device.lockForConfiguration()
                flashMode = flashMode == .off ? .on : (flashMode == .on ? .auto : .off)
                device.unlockForConfiguration()
            } catch {
                print("Failed to toggle flash: \(error)")
            }
        }

        func capturePhoto() {
            let settings = AVCapturePhotoSettings()
            settings.flashMode = self.flashMode
            photoOutput.capturePhoto(with: settings, delegate: self)
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                errorMessage = "Failed to capture photo: \(error.localizedDescription)"
                return
            }
            guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
                errorMessage = "Could not process photo data."
                return
            }
            self.capturedImage = image
        }
    }
}
