/// A House roll call's published `legis-num` label beside its conservative reading.
///
/// ``rawValue`` is the label's complete text, without trimming or normalization. ``measure`` is
/// set only when the whole label is one of the eight spaced forms this projection recognizes,
/// patterned on the two observed in recorded Clerk files (`S 2403`, `H R 2190`) and the eight
/// kinds the Clerk's DTD lists, `H R`, `H RES`, `H J RES`, `H CON RES`, `S`, `S RES`, `S J RES`,
/// or `S CON RES`, followed by one space and a decimal number with no leading zero, such as
/// `S 2403` or `H R 2190`. Every other
/// label keeps its text and has a nil ``measure``: procedural labels such as `QUORUM 1`, an
/// empty label, a label with more or fewer words, different spacing or case, a non-numeric or
/// zero-padded number, and the dotted spellings the Clerk's DTD also documents (`H.R. 1514`,
/// `S.J.RES. 42`), which this projection does not recognize. A caller that needs one of those
/// reads ``rawValue``. Nothing is guessed: no bill identity, Congress, or measure type is
/// produced from an unrecognized label.
///
/// ```swift
/// if let reference = rollCall.legislationReference {
///   print(reference.rawValue, reference.measure?.number ?? "no recognized measure")
/// }
/// ```
public struct HouseLegislationReference: Hashable, Sendable {
  /// The recognized measure, or nil when the label is not one of the anchored forms.
  public let measure: HouseMeasureReference?
  /// The label's complete published text.
  public let rawValue: String

  init(congress: Int, rawValue: String) {
    self.rawValue = rawValue
    measure = Self.measure(in: rawValue, congress: congress)
  }

  private static let recognizedTypes: [HouseMeasureType] = [
    .houseBill, .houseConcurrentResolution, .houseJointResolution, .houseResolution,
    .senateBill, .senateConcurrentResolution, .senateJointResolution, .senateResolution,
  ]

  private static func measure(in label: String, congress: Int) -> HouseMeasureReference? {
    guard let separator = label.lastIndex(of: " ") else { return nil }
    let words = String(label[..<separator])
    let number = label[label.index(after: separator)...]
    guard let measureType = recognizedTypes.first(where: { $0.rawValue == words }),
      let first = number.utf8.first, first >= UInt8(ascii: "1"), first <= UInt8(ascii: "9"),
      number.utf8.allSatisfy({ $0 >= UInt8(ascii: "0") && $0 <= UInt8(ascii: "9") })
    else { return nil }
    return HouseMeasureReference(
      congress: congress, measureType: measureType, number: String(number))
  }
}
