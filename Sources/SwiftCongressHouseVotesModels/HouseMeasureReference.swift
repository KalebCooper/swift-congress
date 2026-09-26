/// A bill or resolution recognized from a House roll call's `legis-num` label.
///
/// The Congress is the roll call's own `congress` element, never inferred from the label. The
/// number is the label's trailing digits as published. This identifies the measure within the
/// House Clerk's publication; it is evidence for a caller to consider, not a Congress.gov
/// identifier, and it is not joined to any other service.
///
/// ```swift
/// if let measure = rollCall.legislationReference?.measure {
///   print(measure.measureType.rawValue, measure.number, "in Congress", measure.congress)
/// }
/// ```
public struct HouseMeasureReference: Hashable, Sendable {
  /// The Congress the roll call's document declares.
  public let congress: Int
  /// The kind of measure named by the label's leading words.
  public let measureType: HouseMeasureType
  /// The label's trailing digits exactly as published.
  public let number: String

  init(congress: Int, measureType: HouseMeasureType, number: String) {
    self.congress = congress
    self.measureType = measureType
    self.number = number
  }
}
