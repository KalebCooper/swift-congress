/// One subject response with legislative subjects and its separate policy area.
public struct BillSubjectPage: Codable, Hashable, Sendable {
  /// Legislative subjects in source order; policy area is never inserted here.
  public let legislativeSubjects: [BillSubject]
  /// Original source count, including a policy-area record when published.
  public let pagination: Pagination
  /// The separate policy area on this page; absence does not imply none on other pages.
  public let policyArea: BillSubject?
  /// Every original envelope field, including nested unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original request metadata, when published.
  public let request: JSONValue?

  /// Decodes the nested source subjects object without changing the source count.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let subjects = try c.nestedContainer(keyedBy: SubjectKeys.self, forKey: .subjects)
    legislativeSubjects = try subjects.decode([BillSubject].self, forKey: .legislativeSubjects)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    policyArea = try subjects.decodeIfPresent(BillSubject.self, forKey: .policyArea)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes the original envelope, including the nested subjects object.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case pagination
    case request
    case subjects
  }

  private enum SubjectKeys: String, CodingKey {
    case legislativeSubjects
    case policyArea
  }
}

extension BillSubjectPage: CongressCollection {
  /// Legislative subjects only, preserving order and duplicates.
  public var items: [BillSubject] { legislativeSubjects }
}

extension BillSubjectPage: CongressPageRecords {
  var consumedRecordCount: Int { legislativeSubjects.count + (policyArea == nil ? 0 : 1) }
}
