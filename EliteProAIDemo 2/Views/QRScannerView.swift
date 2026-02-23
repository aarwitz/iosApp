// QRScannerView.swift
// EliteProAIDemo
//
// Provides two reusable components:
//   QRCodeView       – generates and renders a QR code image from a string
//   QRScannerView    – live camera feed that reads QR codes via AVFoundation

import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins

// MARK: – QR Code Generator

struct QRCodeView: View {
    let content: String
    var size: CGFloat = 200

    private var qrImage: UIImage? {
        generateQRCode(from: content)
    }

    var body: some View {
        if let image = qrImage {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: "qrcode")
                .font(.system(size: size * 0.7))
                .foregroundStyle(.black)
                .frame(width: size, height: size)
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        // Scale up for crisp rendering
        let scale = size / outputImage.extent.width
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: – QR Code Scanner

/// A camera-based QR code scanner presented as a full-screen sheet.
/// Add NSCameraUsageDescription to your target's Info settings in Xcode.
struct QRScannerView: View {
    /// Called with the scanned string content when a QR code is successfully read.
    let onScan: (String) -> Void
    let onCancel: () -> Void

    @State private var isAuthorized: Bool = false
    @State private var authDenied: Bool = false
    @State private var manualCode: String = ""
    @State private var showManualEntry: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                if isAuthorized {
                    CameraPreview(onScan: onScan)
                        .ignoresSafeArea()

                    // Viewfinder overlay
                    VStack {
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(EPTheme.accent, lineWidth: 3)
                                .frame(width: 240, height: 240)

                            // Corner markers
                            ViewfinderCorners()
                        }

                        Text("Point at a friend's code to connect")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.top, 20)

                        Button {
                            showManualEntry = true
                        } label: {
                            Text("Enter code manually")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(EPTheme.accent)
                                .padding(.top, 8)
                        }

                        Spacer()
                    }
                } else if authDenied {
                    cameraPermissionDeniedView
                } else {
                    ProgressView("Requesting camera access…")
                        .foregroundStyle(Color.primary)
                }
            }
            .navigationTitle("Scan Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                }
            }
            .alert("Enter Friend Code", isPresented: $showManualEntry) {
                TextField("Paste UUID here…", text: $manualCode)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Add") {
                    let trimmed = manualCode.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        onScan(trimmed)
                    }
                }
                Button("Cancel", role: .cancel) { manualCode = "" }
            } message: {
                Text("Enter your friend's unique ID code.")
            }
        }
        .task { await requestCameraAccess() }
    }

    private var cameraPermissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 56))
                .foregroundStyle(EPTheme.softText)
            Text("Camera Access Required")
                .font(.system(.title3, design: .rounded).weight(.semibold))
            Text("Go to Settings → EliteProAI → Camera to enable access, or enter the code manually below.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(EPTheme.softText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showManualEntry = true
            } label: {
                Text("Enter Code Manually")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.85))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(EPTheme.accent))
            }

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(EPTheme.accent)
        }
        .padding()
    }

    private func requestCameraAccess() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                isAuthorized = granted
                authDenied = !granted
            }
        default:
            authDenied = true
        }
    }
}

// MARK: – Camera Preview (UIViewRepresentable)

private struct CameraPreview: UIViewRepresentable {
    let onScan: (String) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return view
        }

        let session = AVCaptureSession()
        session.beginConfiguration()

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
            output.metadataObjectTypes = [.qr]
        }

        session.commitConfiguration()

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        context.coordinator.session = session
        context.coordinator.previewLayer = previewLayer

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.session?.stopRunning()
    }

    // MARK: Coordinator

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onScan: (String) -> Void
        var session: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        private var hasFired = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !hasFired,
                  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let stringValue = object.stringValue,
                  !stringValue.isEmpty else { return }

            hasFired = true
            session?.stopRunning()
            onScan(stringValue)
        }
    }
}

// MARK: – Viewfinder Corners

private struct ViewfinderCorners: View {
    var body: some View {
        ZStack {
            // Top-left
            corner.offset(x: -90, y: -90)
            // Top-right
            corner.rotationEffect(.degrees(90)).offset(x: 90, y: -90)
            // Bottom-right
            corner.rotationEffect(.degrees(180)).offset(x: 90, y: 90)
            // Bottom-left
            corner.rotationEffect(.degrees(270)).offset(x: -90, y: 90)
        }
    }

    private var corner: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(EPTheme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        .frame(width: 20, height: 20)
    }
}
