/// The kind of bill or resolution named by a Senate `document_type` code.
///
/// The raw value is the code exactly as the Senate publishes it, dotted and without spaces, such
/// as `H.R.` or `S.Con.Res.`. The eight constants are the codes this module recognizes: the two
/// recorded in its fixtures (`H.R.` and `S.`) and the six other bill and resolution kinds spelled
/// the same dotted way; a spelling not on the list is `.unknown` and stays readable on its nodes.
/// The type is open so a consumer can name a code this module does not recognize; the
/// classification in ``SenateRollCall/subject`` and ``SenateAmendmentTarget`` never produces one
/// on its own.
///
/// ```swift
/// if case .bill(let bill)? = rollCall.subject, bill.measureType == .houseBill {
///   print("a House bill numbered", bill.document.number ?? "unknown")
/// }
/// ```
public struct SenateMeasureType: Hashable, RawRepresentable, Sendable {
  /// The published code, without normalization.
  public let rawValue: String

  /// A House bill, published as `H.R.`.
  public static let houseBill = Self(rawValue: "H.R.")
  /// A House concurrent resolution, published as `H.Con.Res.`.
  public static let houseConcurrentResolution = Self(rawValue: "H.Con.Res.")
  /// A House joint resolution, published as `H.J.Res.`.
  public static let houseJointResolution = Self(rawValue: "H.J.Res.")
  /// A House simple resolution, published as `H.Res.`.
  public static let houseResolution = Self(rawValue: "H.Res.")
  /// A Senate bill, published as `S.`.
  public static let senateBill = Self(rawValue: "S.")
  /// A Senate concurrent resolution, published as `S.Con.Res.`.
  public static let senateConcurrentResolution = Self(rawValue: "S.Con.Res.")
  /// A Senate joint resolution, published as `S.J.Res.`.
  public static let senateJointResolution = Self(rawValue: "S.J.Res.")
  /// A Senate simple resolution, published as `S.Res.`.
  public static let senateResolution = Self(rawValue: "S.Res.")

  /// The eight documented codes, the only ones classification recognizes.
  static let recognized: [Self] = [
    .houseBill, .houseConcurrentResolution, .houseJointResolution, .houseResolution,
    .senateBill, .senateConcurrentResolution, .senateJointResolution, .senateResolution,
  ]

  /// Creates a known or consumer-defined measure type without normalization.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// Returns the documented type whose code equals the text, or nil for any other text.
  static func recognized(_ code: String) -> Self? {
    recognized.first { $0.rawValue == code }
  }
}
