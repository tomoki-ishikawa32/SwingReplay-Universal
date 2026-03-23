import AVFoundation
import SwiftUI

struct PhoneRootView: View {
    @ObservedObject var runtime: PhoneRuntimeController
    let onExit: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                PhoneCameraPreviewView(session: runtime.captureSession)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.15),
                        Color.black.opacity(0.45)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Button(action: onExit) {
                            Label("ホーム", systemImage: "chevron.backward")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.black.opacity(0.35))

                        Spacer()
                    }
                    Spacer()

                    if let error = runtime.errorText {
                        Text(error)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.8), in: Capsule(style: .continuous))
                            .padding(.bottom, 14)
                    }

                    Text("送信中")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.black.opacity(0.28), in: Capsule(style: .continuous))
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        }
                        .frame(maxWidth: .infinity)
                }
                .padding(24)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            }
        }
    }
}

private struct PhoneCameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.attach(session: session)
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        uiView.attach(session: session)
    }
}

private final class PreviewContainerView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    func attach(session: AVCaptureSession) {
        if previewLayer.session !== session {
            previewLayer.session = session
        }
        previewLayer.videoGravity = .resizeAspectFill
        if let connection = previewLayer.connection,
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        backgroundColor = .black
    }
}
