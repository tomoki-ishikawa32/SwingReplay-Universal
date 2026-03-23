import Foundation
import MultipeerConnectivity

public enum PeerIdentity {
    public static func makePeerID(prefix: String) -> MCPeerID {
        let baseName = ProcessInfo.processInfo.processName
        let suffix = ProcessInfo.processInfo.globallyUniqueString.prefix(8)
        let rawName = "\(baseName)-\(suffix)"

        let sanitized = rawName
            .replacingOccurrences(of: " ", with: "-")
            .prefix(30)

        return MCPeerID(displayName: "\(prefix)-\(sanitized)")
    }
}

public enum MultipeerConfig {
    public static let serviceType = "swing-replay"
    public static let pairingTokenKey = "pairingToken"
    public static let payloadVersion = 1
}

public struct PairingPayload: Codable, Equatable, Sendable {
    public let version: Int
    public let serviceType: String
    public let pairingToken: String

    public init(version: Int = MultipeerConfig.payloadVersion, serviceType: String = MultipeerConfig.serviceType, pairingToken: String) {
        self.version = version
        self.serviceType = serviceType
        self.pairingToken = pairingToken
    }

    public static func make() -> PairingPayload {
        PairingPayload(pairingToken: UUID().uuidString.replacingOccurrences(of: "-", with: ""))
    }

    public var displayCode: String {
        String(pairingToken.prefix(6)).uppercased()
    }

    public var qrString: String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return ""
        }
        return string
    }

    public static func parse(qrString: String) -> PairingPayload? {
        guard let data = qrString.data(using: .utf8),
              let payload = try? JSONDecoder().decode(PairingPayload.self, from: data),
              payload.serviceType == MultipeerConfig.serviceType,
              payload.version == MultipeerConfig.payloadVersion,
              !payload.pairingToken.isEmpty else {
            return nil
        }
        return payload
    }
}
