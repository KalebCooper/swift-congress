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

extension CongressRequest where Response == BillDetail {
  /// Describes a historical or modern source bill record.
  public static func bill(_ identifier: BillSourceIdentifier) -> Self {
    Self(endpoint: .bill(identifier))
  }
  /// Describes a numbered bill.
  public static func bill(_ identifier: BillIdentifier) -> Self { bill(identifier.source) }
}

extension CongressRequest where Response == BillPage {
  /// Describes lazy bill pages; value execution retrieves only the initial page.
  public static func bills(matching query: BillQuery) -> Self {
    Self(collection: .bills(matching: query))
  }
}

extension CongressRequest where Response == CongressPage {
  /// Describes lazy all-era Congress discovery.
  public static func congresses(matching query: CongressQuery = .init()) -> Self {
    Self(collection: .congresses(matching: query))
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

extension CongressRequest where Response == MemberDetail {
  /// Describes one member detail record.
  public static func member(_ identifier: MemberIdentifier) -> Self {
    Self(endpoint: .member(identifier))
  }
}

extension CongressRequest where Response == MemberPage {
  /// Describes lazy member pages; value execution retrieves only the initial page.
  public static func members(matching query: MemberQuery) -> Self {
    Self(collection: .members(matching: query))
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
