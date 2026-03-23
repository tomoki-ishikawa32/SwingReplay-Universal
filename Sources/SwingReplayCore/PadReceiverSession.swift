import Foundation
import MultipeerConnectivity
import OSLog

public final class PadReceiverSession: NSObject, @unchecked Sendable {
    public private(set) var state: ConnectionState = .searching {
        didSet { stateDidChange?(state) }
    }

    public var stateDidChange: ((ConnectionState) -> Void)?
    public var didReceiveData: ((Data, MCPeerID) -> Void)?

    private let peerID: MCPeerID
    private let session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private let logger = Logger(subsystem: "SwingReplay", category: "PadReceiver")
    private var activePairingToken: String?

    public init(peerID: MCPeerID = PeerIdentity.makePeerID(prefix: "pad")) {
        self.peerID = peerID
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        super.init()
        session.delegate = self
    }

    public func start(pairingToken: String) {
        activePairingToken = pairingToken
        let advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: [MultipeerConfig.pairingTokenKey: pairingToken],
            serviceType: MultipeerConfig.serviceType
        )
        advertiser.delegate = self
        self.advertiser = advertiser
        advertiser.startAdvertisingPeer()
        state = .searching
        logger.info("Advertising started for pairing token \(pairingToken, privacy: .private(mask: .hash))")
    }

    public func stop() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        session.disconnect()
        activePairingToken = nil
        state = .searching
        logger.info("Receiver stopped")
    }

    private func reAdvertise() {
        guard let pairingToken = activePairingToken else { return }
        advertiser?.stopAdvertisingPeer()
        let advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: [MultipeerConfig.pairingTokenKey: pairingToken],
            serviceType: MultipeerConfig.serviceType
        )
        advertiser.delegate = self
        self.advertiser = advertiser
        advertiser.startAdvertisingPeer()
        state = .reconnecting
        logger.notice("Re-advertising after disconnect for pairing token \(pairingToken, privacy: .private(mask: .hash))")
    }
}

extension PadReceiverSession: MCNearbyServiceAdvertiserDelegate {
    public func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        let pairingToken = String(data: context ?? Data(), encoding: .utf8)
        let shouldAccept = !session.connectedPeers.isEmpty ? false : pairingToken == activePairingToken
        if shouldAccept {
            state = .connecting
            invitationHandler(true, session)
            logger.info("Invitation accepted from \(peerID.displayName, privacy: .public)")
        } else {
            invitationHandler(false, nil)
            logger.notice("Invitation rejected from \(peerID.displayName, privacy: .public)")
        }
    }

    public func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: Error
    ) {
        state = .error(message: error.localizedDescription)
        logger.error("Advertising failed: \(error.localizedDescription, privacy: .public)")
    }
}

extension PadReceiverSession: MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .notConnected:
            reAdvertise()
        case .connecting:
            self.state = .connecting
        case .connected:
            advertiser?.stopAdvertisingPeer()
            self.state = .connected(peerName: peerID.displayName)
        @unknown default:
            self.state = .error(message: "Unknown session state")
        }
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        didReceiveData?(data, peerID)
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
