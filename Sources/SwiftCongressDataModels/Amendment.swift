/// An amendment with independent targets, source dates and resource metadata.
public struct Amendment: Codable, Hashable, Sendable {
  /// Action count and link, without fetching its records.
  public let actions: ResourceLink?
  /// Independent amendment target; a bill or treaty may also be present.
  public let amendedAmendment: AmendmentSummary?
  /// Independent bill target. Additional nested bill fields remain in rawFields.
  public let amendedBill: Bill?
  /// Independent treaty target, without graph or ancestry inference.
  public let amendedTreaty: AmendmentTreaty?
  /// Child-amendment count and link, without recursive fetching.
  public let amendmentsToAmendment: ResourceLink?
  /// Open source chamber label.
  public let chamber: String?
  /// Original Congress number.
  public let congress: Int
  /// Separate source cosponsor counts and resource link.
  public let cosponsors: AmendmentCosponsorResource?
  /// Source description, distinct from purpose; omitted or null remains nil.
  public let description: String?
  /// Latest published action, without inferring a vote outcome.
  public let latestAction: AmendmentAction?
  /// Published notes in source order, preserving duplicates.
  public let notes: [AmendmentNote]?
  /// Source amendment number, without numeric coercion.
  public let number: String
  /// On-behalf members and roles, kept separate from sponsors.
  public let onBehalfOfSponsor: [AmendmentMember]?
  /// Original proposed timestamp, distinct from submission.
  public let proposedDate: String?
  /// Original purpose when supplied, distinct from description.
  public let purpose: String?
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Published sponsors in source order, without profile lookups.
  public let sponsors: [AmendmentMember]?
  /// Original submitted timestamp, distinct from proposal.
  public let submittedDate: String?
  /// Text metadata count and link, without retrieving metadata or assets.
  public let textVersions: ResourceLink?
  /// Open amendment code, retaining original spelling.
  public let type: AmendmentType
  /// Original modification timestamp, unparsed.
  public let updateDate: String?
  /// Original reference URL; no linked response is fetched.
  public let url: String?

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    actions = try c.decodeIfPresent(ResourceLink.self, forKey: .actions)
    amendedAmendment = try c.decodeIfPresent(AmendmentSummary.self, forKey: .amendedAmendment)
    amendedBill = try c.decodeIfPresent(Bill.self, forKey: .amendedBill)
    amendedTreaty = try c.decodeIfPresent(AmendmentTreaty.self, forKey: .amendedTreaty)
    amendmentsToAmendment = try c.decodeIfPresent(ResourceLink.self, forKey: .amendmentsToAmendment)
    chamber = try c.decodeIfPresent(String.self, forKey: .chamber)
    congress = try c.decode(Int.self, forKey: .congress)
    cosponsors = try c.decodeIfPresent(AmendmentCosponsorResource.self, forKey: .cosponsors)
    description = try c.decodeIfPresent(String.self, forKey: .description)
    latestAction = try c.decodeIfPresent(AmendmentAction.self, forKey: .latestAction)
    notes = try c.decodeIfPresent([AmendmentNote].self, forKey: .notes)
    number = try c.decode(String.self, forKey: .number)
    onBehalfOfSponsor = try c.decodeIfPresent([AmendmentMember].self, forKey: .onBehalfOfSponsor)
    proposedDate = try c.decodeIfPresent(String.self, forKey: .proposedDate)
    purpose = try c.decodeIfPresent(String.self, forKey: .purpose)
    sponsors = try c.decodeIfPresent([AmendmentMember].self, forKey: .sponsors)
    submittedDate = try c.decodeIfPresent(String.self, forKey: .submittedDate)
    textVersions = try c.decodeIfPresent(ResourceLink.self, forKey: .textVersions)
    type = try c.decode(AmendmentType.self, forKey: .type)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case actions
    case amendedAmendment
    case amendedBill
    case amendedTreaty
    case amendmentsToAmendment
    case chamber
    case congress
    case cosponsors
    case description
    case latestAction
    case notes
    case number
    case onBehalfOfSponsor
    case proposedDate
    case purpose
    case sponsors
    case submittedDate
    case textVersions
    case type
    case updateDate
    case url
  }
}
