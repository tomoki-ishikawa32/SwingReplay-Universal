import AVFoundation
import CoreImage.CIFilterBuiltins
import SwingReplayCore
import SwiftUI
import UIKit

struct SwingReplayRootView: View {
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                ReceiverRootFlow()
            } else {
                SenderRootFlow()
            }
        }
    }
}

private struct SenderRootFlow: View {
    private enum Phase {
        case home
        case scanning
        case active
    }

    @StateObject private var runtime = PhoneRuntimeController()
    @State private var phase: Phase = .home
    @State private var scanErrorMessage: String?
    @State private var scannerResetID = UUID()

    var body: some View {
        Group {
            switch phase {
            case .home:
                PhoneHomeStartView {
                    startScanning()
                }

            case .scanning:
                QRScanStartView(
                    accentColor: Color(red: 0.11, green: 0.73, blue: 0.42),
                    errorMessage: scanErrorMessage,
                    resetID: scannerResetID,
                    onCancel: endSession,
                    onRescan: {
                        scanErrorMessage = nil
                        scannerResetID = UUID()
                    },
                    onScannerError: { message in
                        scanErrorMessage = message
                    },
                    onCodeScanned: handleScannedCode
                )

            case .active:
                PhoneRootView(runtime: runtime, onExit: endSession)
            }
        }
    }

    private func startScanning() {
        scanErrorMessage = nil
        scannerResetID = UUID()
        phase = .scanning
    }

    private func handleScannedCode(_ code: String) {
        guard let payload = PairingPayload.parse(qrString: code) else {
            scanErrorMessage = "Swing Replay の iPad に表示されたQRコードを読み取ってください。"
            scannerResetID = UUID()
            return
        }

        scanErrorMessage = nil
        runtime.start(pairingPayload: payload)
        phase = .active
    }

    private func endSession() {
        runtime.stop()
        scanErrorMessage = nil
        phase = .home
    }
}

private struct PhoneHomeStartView: View {
    let onStart: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 80)

                VStack(spacing: 14) {
                    Text("Swing Replay")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.13, green: 0.14, blue: 0.18))

                    Text("iPhoneでスイングを撮影")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.35))
                }

                Spacer()

                Button(action: onStart) {
                    Text("接続する")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(
                            Color(red: 0.20, green: 0.81, blue: 0.50),
                            in: Capsule(style: .continuous)
                        )
                        .contentShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .shadow(color: Color(red: 0.20, green: 0.81, blue: 0.50).opacity(0.16), radius: 14, y: 7)

                Text("※ iPad側もアプリを開いてください")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.28))
                    .padding(.top, 24)

                Spacer(minLength: 140)
            }
        }
    }
}

private struct ReceiverRootFlow: View {
    private enum Phase {
        case home
        case waiting
        case active
    }

    @StateObject private var runtime = PadRuntimeController()
    @State private var phase: Phase = .home

    var body: some View {
        Group {
            switch phase {
            case .home:
                PadHomeStartView {
                    runtime.start()
                    phase = .waiting
                }

            case .waiting:
                ReceiverPairingView(
                    runtime: runtime,
                    onExit: endSession,
                    onRegenerate: runtime.regeneratePairing
                )
                .onChange(of: runtime.isConnected) { _, isConnected in
                    if isConnected {
                        phase = .active
                    }
                }

            case .active:
                PadRootView(runtime: runtime, onExit: endSession)
            }
        }
    }

    private func endSession() {
        runtime.stop()
        phase = .home
    }
}

private struct PadHomeStartView: View {
    let onStart: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 120)

                VStack(spacing: 14) {
                    Text("Swing Replay")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.13, green: 0.14, blue: 0.18))

                    Text("iPadで映像を確認")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.35))
                }

                Spacer()

                Button(action: onStart) {
                    Text("受信を開始する")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(
                            Color(red: 0.10, green: 0.41, blue: 0.84),
                            in: Capsule(style: .continuous)
                        )
                        .contentShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 110)
                .shadow(color: Color(red: 0.10, green: 0.41, blue: 0.84).opacity(0.16), radius: 14, y: 7)

                Text("※ iPhone側もアプリを開いてください。")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.28))
                    .padding(.top, 24)

                Spacer(minLength: 220)
            }
        }
    }
}

private struct HomeStartView: View {
    let title: String
    let roleTitle: String
    let description: String
    let steps: [String]
    let buttonTitle: String
    let accentColor: Color
    let symbolName: String
    let footerText: String
    let onStart: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.03, green: 0.07, blue: 0.12),
                        Color(red: 0.06, green: 0.12, blue: 0.17),
                        accentColor.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(accentColor.opacity(0.18))
                    .frame(width: proxy.size.width * 0.92)
                    .blur(radius: 28)
                    .offset(x: proxy.size.width * 0.24, y: -proxy.size.height * 0.22)

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: proxy.size.width * 0.58)
                    .blur(radius: 18)
                    .offset(x: -proxy.size.width * 0.3, y: proxy.size.height * 0.28)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        Spacer(minLength: 24)

                        Image(systemName: symbolName)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.white, accentColor.opacity(0.95))
                            .frame(width: 72, height: 72)
                            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                        VStack(alignment: .leading, spacing: 10) {
                            Text(title)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text(roleTitle)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.95))

                            Text(description)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.82))
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text("使い方")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.92))

                            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.white)
                                        .frame(width: 28, height: 28)
                                        .background(accentColor, in: Circle())

                                    Text(step)
                                        .font(.body)
                                        .foregroundStyle(.white.opacity(0.88))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(20)
                        .background(.ultraThinMaterial.opacity(0.42), in: RoundedRectangle(cornerRadius: 28, style: .continuous))

                        Button(action: onStart) {
                            HStack(spacing: 10) {
                                Text(buttonTitle)
                                    .font(.headline.weight(.semibold))
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(accentColor)

                        Text(footerText)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, proxy.size.width > 700 ? 48 : 24)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 720, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

private struct QRScanStartView: View {
    let accentColor: Color
    let errorMessage: String?
    let resetID: UUID
    let onCancel: () -> Void
    let onRescan: () -> Void
    let onScannerError: (String) -> Void
    let onCodeScanned: (String) -> Void
    @State private var isScannerActive = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.04, green: 0.08, blue: 0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                QRScannerViewRepresentable(
                    onCodeScanned: onCodeScanned,
                    onError: onScannerError
                )
                .id(resetID)
                .ignoresSafeArea()

                Color.black.opacity(0.42).ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Button(action: onCancel) {
                            Label("ホーム", systemImage: "chevron.backward")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 18)

                    Spacer(minLength: max(24, proxy.safeAreaInsets.top + 8))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("iPadのQRコードを読み取る")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 42)

                    Spacer(minLength: 42)

                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.white.opacity(0.10))

                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.92), lineWidth: 3)

                        Color.clear
                            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                            .overlay(Color.black.opacity(0.16))

                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 66, weight: .regular))
                            .foregroundStyle(accentColor)
                    }
                    .frame(width: min(proxy.size.width - 76, 320), height: min(proxy.size.width - 76, 320))

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.red.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 36)
                            .padding(.top, 24)
                    } else {
                        Text("QRコードを枠内に合わせてください。")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.58))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 36)
                            .padding(.top, 24)
                    }

                    Spacer(minLength: 48)

                    Button(action: startOrResetScanner) {
                        Text("再スキャン")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 62)
                            .background(
                                accentColor,
                                in: Capsule(style: .continuous)
                            )
                            .contentShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 38)
                    .shadow(color: accentColor.opacity(0.18), radius: 14, y: 7)

                    Spacer(minLength: 64)
                }
            }
        }
        .onAppear {
            isScannerActive = true
        }
    }

    private func startOrResetScanner() {
        onRescan()
    }
}

private struct ReceiverPairingView: View {
    @ObservedObject var runtime: PadRuntimeController
    let onExit: () -> Void
    let onRegenerate: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()

                HStack {
                    Button(action: onExit) {
                        Label("ホーム", systemImage: "chevron.backward")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(red: 0.13, green: 0.14, blue: 0.18))

                    Spacer()

                    Button("QRを再生成", action: onRegenerate)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 42)
                        .background(
                            Color(red: 0.10, green: 0.41, blue: 0.84),
                            in: Capsule(style: .continuous)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)

                VStack(spacing: 88) {
                    Text("iPhoneでQRコードを読み取る")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.13, green: 0.14, blue: 0.18))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    PairingQRCodeView(payload: runtime.currentPairingPayload)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, min(max(proxy.size.height * 0.18, 180), 220))
            }
        }
    }
}

private struct PairingQRCodeView: View {
    let payload: PairingPayload?

    var body: some View {
        if let payload {
            if let image = QRCodeRenderer.makeImage(from: payload.qrString) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260, height: 260)
                    .padding(18)
                    .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: Color.black.opacity(0.06), radius: 18, y: 10)
            } else {
                ProgressView()
                    .tint(Color(red: 0.10, green: 0.41, blue: 0.84))
                    .frame(width: 260, height: 260)
            }
        } else {
            ProgressView()
                .tint(Color(red: 0.10, green: 0.41, blue: 0.84))
                .frame(width: 260, height: 260)
        }
    }
}

private enum QRCodeRenderer {
    private static let context = CIContext()

    static func makeImage(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage?
            .transformed(by: CGAffineTransform(scaleX: 12, y: 12)),
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

private struct QRScannerViewRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    let onError: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodeScanned = onCodeScanned
        controller.onError = onError
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        uiViewController.onCodeScanned = onCodeScanned
        uiViewController.onError = onError
    }
}

@MainActor
private final class QRScannerViewController: UIViewController, @preconcurrency AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    var onError: ((String) -> Void)?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isConfigured = false
    private var didEmitCode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureAuthorization()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    private func configureAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSessionIfNeeded()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureSessionIfNeeded()
                    } else {
                        self?.onError?("QRコードを読み取るにはカメラの許可が必要です。")
                    }
                }
            }
        case .denied, .restricted:
            onError?("QRコードを読み取るにはカメラの許可が必要です。")
        @unknown default:
            onError?("カメラの状態を確認できませんでした。")
        }
    }

    private func configureSessionIfNeeded() {
        guard !isConfigured else {
            startSession()
            return
        }

        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(input) else {
            onError?("カメラを起動できませんでした。")
            return
        }

        captureSession.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(output) else {
            onError?("QRコード読み取りを開始できませんでした。")
            return
        }

        captureSession.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        isConfigured = true
        startSession()
    }

    private func startSession() {
        guard !captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    private func stopSession() {
        guard captureSession.isRunning else { return }
        captureSession.stopRunning()
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !didEmitCode,
              let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let value = metadataObject.stringValue else {
            return
        }

        didEmitCode = true
        stopSession()
        onCodeScanned?(value)
    }
}
