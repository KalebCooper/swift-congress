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
