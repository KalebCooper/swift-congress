/// One history entry in its published order.
public struct CommitteeHistory: Codable, Hashable, Sendable {
  /// The source `committeeTypeCode` string, without interpretation.
  public let committeeTypeCode: String?
  /// The source `endDate` string, without interpretation.
  public let endDate: String?
  /// The source `establishingAuthority` string, without interpretation.
  public let establishingAuthority: String?
  /// The source `libraryOfCongressName` string, without interpretation.
  public let libraryOfCongressName: String?
  /// The source `locLinkedDataId` string, without interpretation.
  public let locLinkedDataId: String?
  /// The source `naraId` string, without interpretation.
  public let naraId: String?
  /// The source `officialName` string, without interpretation.
  public let officialName: String?
  /// Every original source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `startDate` string, without interpretation.
  public let startDate: String?
  /// The source `superintendentDocumentNumber` string, without interpretation.
  public let superintendentDocumentNumber: String?
  /// The source `updateDate` string, without interpretation.
  public let updateDate: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    committeeTypeCode = try c.decodeIfPresent(String.self, forKey: .committeeTypeCode)
    endDate = try c.decodeIfPresent(String.self, forKey: .endDate)
    establishingAuthority = try c.decodeIfPresent(String.self, forKey: .establishingAuthority)
    libraryOfCongressName = try c.decodeIfPresent(String.self, forKey: .libraryOfCongressName)
    locLinkedDataId = try c.decodeIfPresent(String.self, forKey: .locLinkedDataId)
    naraId = try c.decodeIfPresent(String.self, forKey: .naraId)
    officialName = try c.decodeIfPresent(String.self, forKey: .officialName)
    startDate = try c.decodeIfPresent(String.self, forKey: .startDate)
    superintendentDocumentNumber = try c.decodeIfPresent(
      String.self, forKey: .superintendentDocumentNumber)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case committeeTypeCode
    case endDate
    case establishingAuthority
    case libraryOfCongressName
    case locLinkedDataId
    case naraId
    case officialName
    case startDate
    case superintendentDocumentNumber
    case updateDate
  }
}
