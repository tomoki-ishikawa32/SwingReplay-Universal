import AVFoundation
import Combine
import Foundation
import SwingReplayCore

@MainActor
final class PhoneRuntimeController: ObservableObject {
    @Published private(set) var connectionText: String = "Scan Ready"
    @Published private(set) var metricsText: String = "sent=0 dropped=0 queue=0"
    @Published private(set) var errorText: String?
    @Published private(set) var isConnected = false

    private let senderSession = PhoneSenderSession()
    private let transport = SenderTransportPipeline()
    private let capture = CameraCaptureService()
    private let encoder = RealtimeH264Encoder()

    private var metricsTimer: Timer?
    private var started = false

    var captureSession: AVCaptureSession {
        capture.session
    }

    init() {
        senderSession.stateDidChange = { [weak self] state in
            Task { @MainActor in
                self?.isConnected = {
                    if case .connected = state {
                        return true
                    }
                    return false
                }()
                self?.connectionText = Self.describe(state: state)
            }
        }

        capture.onSampleBuffer = { [weak self] sampleBuffer in
            self?.encoder.encode(sampleBuffer)
        }

        encoder.onFrameEncoded = { [weak self] frame in
            guard let self else { return }
            self.transport.send(encodedFrame: frame, sender: self.senderSession, reliably: true)
        }
    }

    func start(pairingPayload: PairingPayload) {
        guard !started else { return }
        started = true
        errorText = nil
        connectionText = "Connecting"
        isConnected = false

        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else { return }
            Task { @MainActor in
                if !granted {
                    self.errorText = "Camera permission denied"
                    self.started = false
                    return
                }
                do {
                    try self.capture.configureSession()
                    try self.encoder.start()
                    self.senderSession.start(pairingToken: pairingPayload.pairingToken)
                    self.capture.startRunning()
                    self.startMetricsTimer()
                } catch {
                    self.errorText = error.localizedDescription
                    self.started = false
                }
            }
        }
    }

    func stop() {
        metricsTimer?.invalidate()
        metricsTimer = nil
        capture.stopRunning()
        encoder.flush()
        encoder.invalidate()
        senderSession.stop()
        isConnected = false
        connectionText = "Scan Ready"
        metricsText = "sent=0 dropped=0 queue=0"
        errorText = nil
        started = false
    }

    private func startMetricsTimer() {
        metricsTimer?.invalidate()
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let metrics = self.transport.metrics()
                self.metricsText = "sent=\(metrics.sentFrames) dropped=\(metrics.droppedFrames) queue=\(metrics.queueLength)"
            }
        }
    }

    private static func describe(state: ConnectionState) -> String {
        switch state {
        case .searching:
            return "Searching"
        case .connecting:
            return "Connecting"
        case .connected(let peerName):
            return "Connected: \(peerName)"
        case .reconnecting:
            return "Reconnecting"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}
