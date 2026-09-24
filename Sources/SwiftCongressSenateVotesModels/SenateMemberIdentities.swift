#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The Senate's current LIS-to-Bioguide crosswalk; it is not a historical identity catalog.
public struct SenateMemberIdentities: Codable, Hashable, SenateResponse, Sendable {
  /// Explicit identities, preserving source order and duplicates.
  public let identities: [SenateMemberIdentity]
  /// Source update date and time elements, without timezone inference.
  public let lastUpdate: SenateXMLNode?
  /// Complete source tree.
  public let rawNode: SenateXMLNode

  /// Reads only explicit source identities. No names are matched or normalized.
  public static func decode(_ data: Data, sourceURL: URL) throws(SenateDecodingError) -> Self {
    let root = try SenateXMLCodec.decode(data)
    guard root.localName == "senators" else { throw .invalidDocument }
    var identities: [SenateMemberIdentity] = []
    for node in root.children(named: "senator") {
      guard let lis = node.attributes["lis_member_id"], !lis.isEmpty else { throw .invalidDocument }
      identities.append(
        SenateMemberIdentity(
          bioguideID: node.child("bioguideId")?.text, lisMemberID: lis, rawNode: node))
    }
    return Self(identities: identities, lastUpdate: root.child("lastUpdate"), rawNode: root)
  }
}

extension Endpoint where Response == SenateMemberIdentities {
  /// Describes the independent current Senate crosswalk.
  public static var memberIdentities: Self {
    builtIn("/legislative/LIS_MEMBER/cvc_member_data.xml")
  }
}
extension SenateVoteRequest where Response == SenateMemberIdentities {
  /// Describes the current identity inventory, not a historical lookup.
  public static var memberIdentities: Self { Self(endpoint: .memberIdentities) }
}
