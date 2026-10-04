#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// An immutable single HTTP operation on api.congress.gov, independent of networking.
///
/// ```swift
/// let key = try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill)
/// let endpoint = Endpoint.bill(key)
/// ```
public struct Endpoint<Response>: Hashable, Sendable {
  /// The encoded path and query relative to https://api.congress.gov.
  public let path: String

  /// Accepts an HTTPS provider link with no credential, fragment, or credential query.
  public init?(link: URL) {
    guard let c = URLComponents(url: link, resolvingAgainstBaseURL: false),
      c.scheme?.lowercased() == "https", c.host?.lowercased() == "api.congress.gov",
      c.port == nil || c.port == 443, c.user == nil, c.password == nil, c.fragment == nil
    else { return nil }
    self.init(path: c.percentEncodedPath + (c.percentEncodedQuery.map { "?" + $0 } ?? ""))
  }

  /// Accepts an encoded v3 path; rejects dot segments, credentials, controls and fragments.
  /// `api_key` is never accepted in a URL. The SDK supplies it as an explicit header.
  public init?(path: String) {
    guard path.hasPrefix("/v3/"),
      path.utf8.allSatisfy({ (33...126).contains($0) && $0 != 35 && $0 != 92 }),
      let c = URLComponents(string: "https://api.congress.gov" + path),
      c.percentEncodedPath + (c.percentEncodedQuery.map { "?" + $0 } ?? "") == path,
      !c.path.contains("%"), !c.path.contains("\\"), !c.path.contains("//"),
      !c.path.utf8.contains(where: { $0 < 32 || $0 == 127 }),
      !c.path.split(separator: "/").contains(where: { $0 == "." || $0 == ".." }),
      !(c.queryItems ?? []).contains(where: { $0.name.lowercased() == "api_key" })
    else { return nil }
    self.path = path
  }

  static func builtIn(_ path: String) -> Self {
    guard let endpoint = Self(path: path) else {
      preconditionFailure("Fixed v3 paths with validated components are valid endpoints.")
    }
    return endpoint
  }
}

extension Endpoint where Response == AmendmentDetail {
  /// Describes one amendment response without fetching any nested resource.
  public static func amendment(_ identifier: AmendmentIdentifier) -> Self {
    builtIn(
      "/v3/amendment/\(identifier.congress)/\(identifier.type.rawValue)/\(identifier.number)?format=json"
    )
  }
}

extension Endpoint where Response == AmendmentPage {
  /// Describes amendments for a source bill, using ordinary strict continuation.
  public static func amendments(
    for identifier: BillSourceIdentifier, matching query: BillAmendmentQuery
  ) -> Self {
    builtIn(query.path(for: identifier))
  }

  /// Describes the same operation for a numbered bill through its source identifier.
  public static func amendments(
    for identifier: BillIdentifier, matching query: BillAmendmentQuery
  ) -> Self {
    amendments(for: identifier.source, matching: query)
  }

  /// Describes one inventory page across the three documented amendment scopes.
  public static func amendments(matching query: AmendmentQuery) -> Self {
    builtIn(query.path)
  }
}

extension Endpoint where Response == BillActionPage {
  /// Describes one page of actions for a bill source record.
  public static func actions(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> Self
  {
    builtIn(
      "/v3/bill/\(identifier.congress)/\(identifier.type.rawValue)/\(identifier.number)/actions?format=json&limit=\(page.limit)&offset=\(page.offset)"
    )
  }
}

extension Endpoint where Response == BillCommitteePage {
  /// Describes source committees for a bill.
  public static func committees(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> Self
  {
    builtIn(
      "/v3/bill/\(identifier.congress)/\(identifier.type.rawValue)/\(identifier.number)/committees?format=json&limit=\(page.limit)&offset=\(page.offset)"
    )
  }

  /// Describes the same operation for a numbered bill through its source identifier.
  public static func committees(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> Self
  {
    committees(for: identifier.source, page: page)
  }
}

extension Endpoint where Response == BillCosponsorPage {
  /// Describes published cosponsors for a source bill, retaining withdrawals.
  public static func cosponsors(
    for identifier: BillSourceIdentifier, matching query: BillCosponsorQuery
  ) -> Self {
    builtIn(query.path(for: identifier))
  }

  /// Describes cosponsors for a numbered bill through its source identifier.
  public static func cosponsors(
    for identifier: BillIdentifier, matching query: BillCosponsorQuery
  ) -> Self {
    cosponsors(for: identifier.source, matching: query)
  }
}

extension Endpoint where Response == BillDetail {
  /// Describes one bill by its Congress.gov source key, including historical surrogates.
  public static func bill(_ identifier: BillSourceIdentifier) -> Self {
    builtIn(
      "/v3/bill/\(identifier.congress)/\(identifier.type.rawValue)/\(identifier.number)?format=json"
    )
  }
  /// Describes one numbered bill.
  public static func bill(_ identifier: BillIdentifier) -> Self { bill(identifier.source) }

  /// Describes one originating bill detail by Congress, law category, and law number.
  public static func law(_ identifier: LawIdentifier) -> Self {
    builtIn(
      "/v3/law/\(identifier.congress)/\(identifier.type.rawValue)/\(identifier.number)?format=json"
    )
  }
}

extension Endpoint where Response == BillPage {
  /// Describes one page of the matching bill inventory.
  public static func bills(matching query: BillQuery) -> Self { builtIn(query.path) }

  /// Describes one law inventory page containing its originating bills.
  public static func laws(matching query: LawQuery) -> Self { builtIn(query.path) }
}

extension Endpoint where Response == BillSubjectPage {
  /// Describes legislative subjects and the separate policy area for a bill.
  public static func subjects(
    for identifier: BillSourceIdentifier, matching query: BillSubjectQuery
  ) -> Self {
    builtIn(query.path(for: identifier))
  }

  /// Describes the same operation for a numbered bill through its source identifier.
  public static func subjects(for identifier: BillIdentifier, matching query: BillSubjectQuery)
    -> Self
  {
    subjects(for: identifier.source, matching: query)
  }
}

extension Endpoint where Response == BillSummaryPage {
  /// Describes one page of summary versions for a source bill.
  public static func summaries(
    for identifier: BillSourceIdentifier, page: CongressQuery = .init()
  ) -> Self {
    builtIn(
      "/v3/bill/\(identifier.congress)/\(identifier.type.rawValue)/\(identifier.number)/summaries?format=json&limit=\(page.limit)&offset=\(page.offset)"
    )
  }

  /// Describes summary versions for a numbered bill through its source identifier.
  public static func summaries(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> Self
  {
    summaries(for: identifier.source, page: page)
  }
}

extension Endpoint where Response == BillSummaryUpdatePage {
  /// Describes one publication-feed page.
  /// Omitted date bounds retain the provider's recent-day default.
  public static func summaryUpdates(matching query: SummaryQuery) -> Self {
    builtIn(query.path)
  }
}

extension Endpoint where Response == BillTextVersionPage {
  /// Describes one page of text-version metadata for a bill source record.
  public static func textVersions(
    for identifier: BillSourceIdentifier, page: CongressQuery = .init()
  ) -> Self {
    builtIn(
      "/v3/bill/\(identifier.congress)/\(identifier.type.rawValue)/\(identifier.number)/text?format=json&limit=\(page.limit)&offset=\(page.offset)"
    )
  }
  /// Describes one page of text-version metadata for a numbered bill.
  public static func textVersions(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> Self
  {
    textVersions(for: identifier.source, page: page)
  }
}

extension Endpoint where Response == CommitteeBillPage {
  /// Describes one page of a committee's bill relationships.
  public static func committeeBills(
    for identifier: CommitteeIdentifier, matching query: CommitteeBillQuery
  ) -> Self {
    builtIn(query.path(for: identifier))
  }
}

extension Endpoint where Response == CommitteeDetail {
  /// Describes one committee detail, optionally scoped to a positive Congress.
  /// - Throws: `CongressInputError.invalidQuery` for a nonpositive Congress.
  public static func committee(_ identifier: CommitteeIdentifier, congress: Int? = nil)
    throws(CongressInputError) -> Self
  {
    if let congress, congress <= 0 { throw .invalidQuery }
    let scope = congress.map { "\($0)/" } ?? ""
    return builtIn(
      "/v3/committee/\(scope)\(identifier.chamber.rawValue)/\(identifier.code)?format=json")
  }
}

extension Endpoint where Response == CommitteeHouseCommunicationPage {
  /// Describes one page of a House committee's communication references.
  /// - Throws: `CongressInputError.unsupportedCommitteeResource` for Senate or Joint identifiers.
  public static func committeeHouseCommunications(
    for identifier: CommitteeIdentifier, page: CongressQuery = .init()
  ) throws(CongressInputError) -> Self {
    guard identifier.chamber == .house else { throw .unsupportedCommitteeResource }
    return builtIn(
      "/v3/committee/house/\(identifier.code)/house-communication?format=json&limit=\(page.limit)&offset=\(page.offset)"
    )
  }
}

extension Endpoint where Response == CommitteeNominationPage {
  /// Describes one page of a Senate committee's nomination references.
  /// - Throws: `CongressInputError.unsupportedCommitteeResource` for House or Joint identifiers.
  public static func committeeNominations(
    for identifier: CommitteeIdentifier, page: CongressQuery = .init()
  ) throws(CongressInputError) -> Self {
    guard identifier.chamber == .senate else { throw .unsupportedCommitteeResource }
    return builtIn(
      "/v3/committee/senate/\(identifier.code)/nominations?format=json&limit=\(page.limit)&offset=\(page.offset)"
    )
  }
}

extension Endpoint where Response == CommitteePage {
  /// Describes one committee directory page.
  public static func committees(matching query: CommitteeQuery) -> Self {
    builtIn(query.path())
  }
}

extension Endpoint where Response == CommitteeReportDetail {
  /// Describes one response containing all report parts, without fetching linked resources.
  public static func committeeReport(_ identifier: CommitteeReportIdentifier) -> Self {
    builtIn(
      "/v3/committee-report/\(identifier.congress)/\(identifier.type.rawValue)/\(identifier.number)?format=json"
    )
  }
}

extension Endpoint where Response == CommitteeReportPage {
  /// Describes one standalone inventory page; lazy traversal follows validated links.
  public static func committeeReports(matching query: CommitteeReportInventoryQuery) -> Self {
    builtIn(query.path)
  }

  /// Describes one page of a committee's report references.
  public static func committeeReports(
    for identifier: CommitteeIdentifier, matching query: CommitteeReportQuery
  ) -> Self {
    builtIn(query.path(for: identifier))
  }
}

extension Endpoint where Response == CommitteeReportTextPage {
  /// Describes report text metadata; format assets are never retrieved automatically.
  public static func textVersions(
    for identifier: CommitteeReportIdentifier, page: CongressQuery = .init()
  ) -> Self {
    builtIn(
      "/v3/committee-report/\(identifier.congress)/\(identifier.type.rawValue)/\(identifier.number)/text?format=json&limit=\(page.limit)&offset=\(page.offset)"
    )
  }
}

extension Endpoint where Response == CommitteeSenateCommunicationPage {
  /// Describes one page of a Senate committee's communication references.
  /// - Throws: `CongressInputError.unsupportedCommitteeResource` for House or Joint identifiers.
  public static func committeeSenateCommunications(
    for identifier: CommitteeIdentifier, page: CongressQuery = .init()
  ) throws(CongressInputError) -> Self {
    guard identifier.chamber == .senate else { throw .unsupportedCommitteeResource }
    return builtIn(
      "/v3/committee/senate/\(identifier.code)/senate-communication?format=json&limit=\(page.limit)&offset=\(page.offset)"
    )
  }
}

extension Endpoint where Response == CongressPage {
  /// Describes one page of the all-era Congress inventory.
  public static func congresses(matching query: CongressQuery = .init()) -> Self {
    builtIn("/v3/congress?format=json&limit=\(query.limit)&offset=\(query.offset)")
  }
}

extension Endpoint where Response == CosponsoredLegislationPage {
  /// Describes one page of a member's cosponsored legislation.
  public static func cosponsoredLegislation(
    for identifier: MemberIdentifier, page: CongressQuery = .init()
  )
    -> Self
  {
    builtIn(
      "/v3/member/\(identifier.rawValue)/cosponsored-legislation?format=json&limit=\(page.limit)&offset=\(page.offset)"
    )
  }
}

extension Endpoint where Response == CRSReportDetail {
  /// Describes one CRS report detail, including supplied links without fetching assets.
  public static func crsReport(_ identifier: CRSReportIdentifier) -> Self {
    builtIn("/v3/crsreport/\(identifier.rawValue)?format=json")
  }
}

extension Endpoint where Response == CRSReportPage {
  /// Describes one page of CRS report summaries.
  public static func crsReports(matching query: CRSReportQuery) -> Self {
    builtIn(query.path())
  }
}

extension Endpoint where Response == MemberDetail {
  /// Describes one member record by its validated identifier, spelled as supplied.
  public static func member(_ identifier: MemberIdentifier) -> Self {
    builtIn("/v3/member/\(identifier.rawValue)?format=json")
  }
}

extension Endpoint where Response == MemberPage {
  /// Describes one geographic member page without following continuation links.
  public static func members(matching query: MemberGeographyQuery) -> Self { builtIn(query.path) }
  /// Describes one page of the matching member inventory.
  public static func members(matching query: MemberQuery) -> Self { builtIn(query.path) }
}

extension Endpoint where Response == RelatedBillPage {
  /// Describes source relatedBills for a bill.
  public static func relatedBills(
    for identifier: BillSourceIdentifier, page: CongressQuery = .init()
  ) -> Self {
    builtIn(
      "/v3/bill/\(identifier.congress)/\(identifier.type.rawValue)/\(identifier.number)/relatedbills?format=json&limit=\(page.limit)&offset=\(page.offset)"
    )
  }

  /// Describes the same operation for a numbered bill through its source identifier.
  public static func relatedBills(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> Self
  {
    relatedBills(for: identifier.source, page: page)
  }
}

extension Endpoint where Response == SponsoredLegislationPage {
  /// Describes one page of a member's sponsored legislation.
  public static func sponsoredLegislation(
    for identifier: MemberIdentifier, page: CongressQuery = .init()
  )
    -> Self
  {
    builtIn(
      "/v3/member/\(identifier.rawValue)/sponsored-legislation?format=json&limit=\(page.limit)&offset=\(page.offset)"
    )
  }
}
