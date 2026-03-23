import Foundation
import MultipeerConnectivity
import OSLog

public final class PhoneSenderSession: NSObject, @unchecked Sendable {
    public private(set) var state: ConnectionState = .searching {
        didSet { stateDidChange?(state) }
    }

    public var stateDidChange: ((ConnectionState) -> Void)?

    private let peerID: MCPeerID
    private let session: MCSession
    private var browser: MCNearbyServiceBrowser?
    private let logger = Logger(subsystem: "SwingReplay", category: "PhoneSender")
    private var targetPairingToken: String?
    private var lastInviteAtByPeer: [String: Date] = [:]
    private let inviteCooldown: TimeInterval = 3

    public init(peerID: MCPeerID = PeerIdentity.makePeerID(prefix: "phone")) {
        self.peerID = peerID
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        super.init()
        session.delegate = self
    }

    public func start(pairingToken: String) {
        targetPairingToken = pairingToken
        lastInviteAtByPeer.removeAll()
        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: MultipeerConfig.serviceType)
        browser.delegate = self
        self.browser = browser
        browser.startBrowsingForPeers()
        state = .searching
        logger.info("Browsing started for pairing token \(pairingToken, privacy: .private(mask: .hash))")
    }

    public func stop() {
        browser?.stopBrowsingForPeers()
        browser = nil
        session.disconnect()
        targetPairingToken = nil
        lastInviteAtByPeer.removeAll()
        state = .searching
        logger.info("Sender stopped")
    }

    public func send(_ data: Data, reliably: Bool) throws {
        guard !session.connectedPeers.isEmpty else {
            throw SenderError.noConnectedPeer
        }

        let mode: MCSessionSendDataMode = reliably ? .reliable : .unreliable
        try session.send(data, toPeers: session.connectedPeers, with: mode)
    }

    private func reBrowse() {
        guard let pairingToken = targetPairingToken else { return }
        browser?.stopBrowsingForPeers()
        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: MultipeerConfig.serviceType)
        browser.delegate = self
        self.browser = browser
        browser.startBrowsingForPeers()
        state = .reconnecting
        logger.notice("Re-browsing after disconnect for pairing token \(pairingToken, privacy: .private(mask: .hash))")
    }
}

public enum SenderError: Error {
    case noConnectedPeer
}

extension PhoneSenderSession: MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .notConnected:
            lastInviteAtByPeer.removeValue(forKey: peerID.displayName)
            reBrowse()
        case .connecting:
            self.state = .connecting
        case .connected:
            browser?.stopBrowsingForPeers()
            self.state = .connected(peerName: peerID.displayName)
        @unknown default:
            self.state = .error(message: "Unknown session state")
        }
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        logger.debug("Unexpected data received on sender side size=\(data.count)")
    }

    public func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        logger.debug("Stream ignored: \(streamName, privacy: .public)")
    }

    public func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        logger.debug("Resource receiving started: \(resourceName, privacy: .public)")
    }

    public func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: (any Error)?
    ) {
        logger.debug("Resource receiving finished: \(resourceName, privacy: .public)")
    }
}

extension PhoneSenderSession: MCNearbyServiceBrowserDelegate {
    public func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        guard session.connectedPeers.isEmpty else { return }
        guard let targetPairingToken else { return }
        guard info?[MultipeerConfig.pairingTokenKey] == targetPairingToken else { return }

        let now = Date()
        if let lastInviteAt = lastInviteAtByPeer[peerID.displayName],
           now.timeIntervalSince(lastInviteAt) < inviteCooldown {
            return
        }

        lastInviteAtByPeer[peerID.displayName] = now
        state = .connecting
        browser.invitePeer(
            peerID,
            to: session,
            withContext: Data(targetPairingToken.utf8),
            timeout: 10
        )
        logger.info("Inviting matched peer \(peerID.displayName, privacy: .public)")
    }

    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        lastInviteAtByPeer.removeValue(forKey: peerID.displayName)
        if session.connectedPeers.isEmpty {
            reBrowse()
        }
    }

    public func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        state = .error(message: error.localizedDescription)
        logger.error("Browsing failed: \(error.localizedDescription, privacy: .public)")
    }
}
