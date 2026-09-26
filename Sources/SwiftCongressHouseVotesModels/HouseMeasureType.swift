/// The kind of bill or resolution named by a recognized House `legis-num` label.
///
/// The raw value is the label's leading words exactly as the Clerk publishes them, such as
/// `H R` or `S CON RES`. The eight constants cover every kind the Clerk's legislation
/// dictionary lists. The type is open so a consumer can name a form this module does not
/// recognize; the projection in ``HouseLegislationReference`` never produces one on its own.
///
/// ```swift
/// if rollCall.legislationReference?.measure?.measureType == .senateBill {
///   print("a Senate bill")
/// }
/// ```
public struct HouseMeasureType: Hashable, RawRepresentable, Sendable {
  /// The label's leading words, without normalization.
  public let rawValue: String

  /// A House bill, published as `H R`.
  public static let houseBill = Self(rawValue: "H R")
  /// A House concurrent resolution, published as `H CON RES`.
  public static let houseConcurrentResolution = Self(rawValue: "H CON RES")
  /// A House joint resolution, published as `H J RES`.
  public static let houseJointResolution = Self(rawValue: "H J RES")
  /// A House simple resolution, published as `H RES`.
  public static let houseResolution = Self(rawValue: "H RES")
  /// A Senate bill, published as `S`.
  public static let senateBill = Self(rawValue: "S")
  /// A Senate concurrent resolution, published as `S CON RES`.
  public static let senateConcurrentResolution = Self(rawValue: "S CON RES")
  /// A Senate joint resolution, published as `S J RES`.
  public static let senateJointResolution = Self(rawValue: "S J RES")
  /// A Senate simple resolution, published as `S RES`.
  public static let senateResolution = Self(rawValue: "S RES")

  /// Creates a known or consumer-defined measure type without normalization.
  public init(rawValue: String) { self.rawValue = rawValue }
}
