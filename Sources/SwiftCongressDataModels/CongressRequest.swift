/// A reusable Congress.gov operation whose construction performs no I/O.
///
/// ```swift
/// let request = CongressRequest.bills(matching: try BillQuery(congress: 6))
/// ```
public struct CongressRequest<Response>: Hashable, Sendable {
  /// An inspectable operation for the SDK or a consumer's executor.
  public enum Resolution: Hashable, Sendable {
    /// Follow validated pagination metadata from an inventory endpoint.
    case collection(Endpoint<Response>)
    /// Execute exactly one endpoint.
    case endpoint(Endpoint<Response>)
  }
  /// The described operation.
  public let resolution: Resolution

  /// Creates a consumer-defined single-response operation.
  public init(endpoint: Endpoint<Response>) { resolution = .endpoint(endpoint) }

  private init(collection: Endpoint<Response>) { resolution = .collection(collection) }
}

extension CongressRequest where Response == AmendmentDetail {
  /// Describes one amendment response without fetching any nested resource.
  public static func amendment(_ identifier: AmendmentIdentifier) -> Self {
    Self(endpoint: .amendment(identifier))
  }
}

extension CongressRequest where Response == AmendmentPage {
  /// Describes amendments for a source bill, using ordinary strict continuation.
  public static func amendments(
    for identifier: BillSourceIdentifier, matching query: BillAmendmentQuery
  ) -> Self {
    Self(collection: .amendments(for: identifier, matching: query))
  }

  /// Describes the same operation for a numbered bill through its source identifier.
  public static func amendments(
    for identifier: BillIdentifier, matching query: BillAmendmentQuery
  ) -> Self {
    amendments(for: identifier.source, matching: query)
  }

  /// Describes one inventory page across the three documented amendment scopes.
  public static func amendments(matching query: AmendmentQuery) -> Self {
    Self(collection: .amendments(matching: query))
  }
}

extension CongressRequest where Response == BillActionPage {
  /// Describes lazy actions for a source bill record.
  public static func actions(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> Self
  {
    Self(collection: .actions(for: identifier, page: page))
  }
}

extension CongressRequest where Response == BillCommitteePage {
  /// Describes source committees for a bill.
  public static func committees(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> Self
  {
    Self(collection: .committees(for: identifier, page: page))
  }

  /// Describes the same operation for a numbered bill through its source identifier.
  public static func committees(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> Self
  {
    committees(for: identifier.source, page: page)
  }
}

extension CongressRequest where Response == BillCosponsorPage {
  /// Describes published cosponsors for a source bill, retaining withdrawals.
  public static func cosponsors(
    for identifier: BillSourceIdentifier, matching query: BillCosponsorQuery
  ) -> Self {
    Self(collection: .cosponsors(for: identifier, matching: query))
  }

  /// Describes cosponsors for a numbered bill through its source identifier.
  public static func cosponsors(
    for identifier: BillIdentifier, matching query: BillCosponsorQuery
  ) -> Self {
    cosponsors(for: identifier.source, matching: query)
  }
}

extension CongressRequest where Response == BillDetail {
  /// Describes a historical or modern source bill record.
  public static func bill(_ identifier: BillSourceIdentifier) -> Self {
    Self(endpoint: .bill(identifier))
  }
  /// Describes a numbered bill.
  public static func bill(_ identifier: BillIdentifier) -> Self { bill(identifier.source) }

  /// Describes the originating bill detail for a public or private law number.
  public static func law(_ identifier: LawIdentifier) -> Self {
    Self(endpoint: .law(identifier))
  }
}

extension CongressRequest where Response == BillPage {
  /// Describes lazy bill pages; value execution retrieves only the initial page.
  public static func bills(matching query: BillQuery) -> Self {
    Self(collection: .bills(matching: query))
  }

  /// Describes lazy law inventory pages containing bills; value execution fetches one page.
  public static func laws(matching query: LawQuery) -> Self {
    Self(collection: .laws(matching: query))
  }
}

extension CongressRequest where Response == BillSubjectPage {
  /// Describes legislative subjects and the separate policy area for a bill.
  public static func subjects(
    for identifier: BillSourceIdentifier, matching query: BillSubjectQuery
  ) -> Self {
    Self(collection: .subjects(for: identifier, matching: query))
  }

  /// Describes the same operation for a numbered bill through its source identifier.
  public static func subjects(for identifier: BillIdentifier, matching query: BillSubjectQuery)
    -> Self
  {
    subjects(for: identifier.source, matching: query)
  }
}

extension CongressRequest where Response == BillSummaryPage {
  /// Describes lazy bill summary pages; value execution retrieves only the first page.
  public static func summaries(
    for identifier: BillSourceIdentifier, page: CongressQuery = .init()
  ) -> Self {
    Self(collection: .summaries(for: identifier, page: page))
  }

  /// Describes summary versions for a numbered bill through its source identifier.
  public static func summaries(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> Self
  {
    summaries(for: identifier.source, page: page)
  }
}

extension CongressRequest where Response == BillSummaryUpdatePage {
  /// Describes lazy publication-feed pages; value execution retrieves only the first page.
  /// Omitted date bounds retain the provider's recent-day default.
  public static func summaryUpdates(matching query: SummaryQuery) -> Self {
    Self(collection: .summaryUpdates(matching: query))
  }
}

extension CongressRequest where Response == BillTextVersionPage {
  /// Describes lazy text-version metadata for a source bill record.
  ///
  /// Value execution retrieves only the initial page. Format links are supplied metadata; no
  /// executor retrieves the linked text.
  public static func textVersions(
    for identifier: BillSourceIdentifier, page: CongressQuery = .init()
  ) -> Self {
    Self(collection: .textVersions(for: identifier, page: page))
  }
  /// Describes lazy text-version metadata for a numbered bill.
  public static func textVersions(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> Self
  {
    textVersions(for: identifier.source, page: page)
  }
}

extension CongressRequest where Response == CommitteeBillPage {
  /// Describes lazy pages of a committee's bill relationships.
  public static func committeeBills(
    for identifier: CommitteeIdentifier, matching query: CommitteeBillQuery
  ) -> Self {
    Self(collection: .committeeBills(for: identifier, matching: query))
  }
}

extension CongressRequest where Response == CommitteeDetail {
  /// Describes one committee profile without fetching related resources.
  /// - Throws: `CongressInputError.invalidQuery` for a nonpositive Congress.
  public static func committee(_ identifier: CommitteeIdentifier, congress: Int? = nil)
    throws(CongressInputError) -> Self
  {
    Self(endpoint: try .committee(identifier, congress: congress))
  }
}

extension CongressRequest where Response == CommitteeHouseCommunicationPage {
  /// Describes lazy pages of a House committee's communication references.
  /// - Throws: `CongressInputError.unsupportedCommitteeResource` for Senate or Joint identifiers.
  public static func committeeHouseCommunications(
    for identifier: CommitteeIdentifier, page: CongressQuery = .init()
  ) throws(CongressInputError) -> Self {
    Self(collection: try .committeeHouseCommunications(for: identifier, page: page))
  }
}

extension CongressRequest where Response == CommitteeNominationPage {
  /// Describes lazy pages of a Senate committee's nomination references.
  /// - Throws: `CongressInputError.unsupportedCommitteeResource` for House or Joint identifiers.
  public static func committeeNominations(
    for identifier: CommitteeIdentifier, page: CongressQuery = .init()
  ) throws(CongressInputError) -> Self {
    Self(collection: try .committeeNominations(for: identifier, page: page))
  }
}

extension CongressRequest where Response == CommitteePage {
  /// Describes lazy directory pages; value execution retrieves only the initial page.
  public static func committees(matching query: CommitteeQuery) -> Self {
    Self(collection: .committees(matching: query))
  }
}

extension CongressRequest where Response == CommitteeReportDetail {
  /// Describes one response containing all report parts, without fetching linked resources.
  public static func committeeReport(_ identifier: CommitteeReportIdentifier) -> Self {
    Self(endpoint: .committeeReport(identifier))
  }
}

extension CongressRequest where Response == CommitteeReportPage {
  /// Describes one standalone inventory page; lazy traversal follows validated links.
  public static func committeeReports(matching query: CommitteeReportInventoryQuery) -> Self {
    Self(collection: .committeeReports(matching: query))
  }

  /// Describes lazy pages of a committee's report references.
  public static func committeeReports(
    for identifier: CommitteeIdentifier, matching query: CommitteeReportQuery
  ) -> Self {
    Self(collection: .committeeReports(for: identifier, matching: query))
  }
}

extension CongressRequest where Response == CommitteeReportTextPage {
  /// Describes report text metadata; format assets are never retrieved automatically.
  public static func textVersions(
    for identifier: CommitteeReportIdentifier, page: CongressQuery = .init()
  ) -> Self {
    Self(collection: .textVersions(for: identifier, page: page))
  }
}

extension CongressRequest where Response == CommitteeSenateCommunicationPage {
  /// Describes lazy pages of a Senate committee's communication references.
  /// - Throws: `CongressInputError.unsupportedCommitteeResource` for House or Joint identifiers.
  public static func committeeSenateCommunications(
    for identifier: CommitteeIdentifier, page: CongressQuery = .init()
  ) throws(CongressInputError) -> Self {
    Self(collection: try .committeeSenateCommunications(for: identifier, page: page))
  }
}

extension CongressRequest where Response == CongressPage {
  /// Describes lazy all-era Congress discovery.
  public static func congresses(matching query: CongressQuery = .init()) -> Self {
    Self(collection: .congresses(matching: query))
  }
}

extension CongressRequest where Response == CosponsoredLegislationPage {
  /// Describes lazy pages of a member's cosponsored legislation.
  public static func cosponsoredLegislation(
    for identifier: MemberIdentifier, page: CongressQuery = .init()
  )
    -> Self
  {
    Self(collection: .cosponsoredLegislation(for: identifier, page: page))
  }
}

extension CongressRequest where Response == CRSReportDetail {
  /// Describes one CRS report detail, including supplied links without fetching assets.
  public static func crsReport(_ identifier: CRSReportIdentifier) -> Self {
    Self(endpoint: .crsReport(identifier))
  }
}

extension CongressRequest where Response == CRSReportPage {
  /// Describes lazy pages of CRS report summaries.
  public static func crsReports(matching query: CRSReportQuery) -> Self {
    Self(collection: .crsReports(matching: query))
  }
}

extension CongressRequest where Response == MemberDetail {
  /// Describes one member detail record.
  public static func member(_ identifier: MemberIdentifier) -> Self {
    Self(endpoint: .member(identifier))
  }
}

extension CongressRequest where Response == MemberPage {
  /// Describes lazy geographic member pages; value execution retrieves only the initial page.
  public static func members(matching query: MemberGeographyQuery) -> Self {
    Self(collection: .members(matching: query))
  }

  /// Describes lazy member pages; value execution retrieves only the initial page.
  public static func members(matching query: MemberQuery) -> Self {
    Self(collection: .members(matching: query))
  }
}

extension CongressRequest where Response == RelatedBillPage {
  /// Describes source relatedBills for a bill.
  public static func relatedBills(
    for identifier: BillSourceIdentifier, page: CongressQuery = .init()
  ) -> Self {
    Self(collection: .relatedBills(for: identifier, page: page))
  }

  /// Describes the same operation for a numbered bill through its source identifier.
  public static func relatedBills(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> Self
  {
    relatedBills(for: identifier.source, page: page)
  }
}

extension CongressRequest where Response == SponsoredLegislationPage {
  /// Describes lazy pages of a member's sponsored legislation.
  public static func sponsoredLegislation(
    for identifier: MemberIdentifier, page: CongressQuery = .init()
  )
    -> Self
  {
    Self(collection: .sponsoredLegislation(for: identifier, page: page))
  }
}
