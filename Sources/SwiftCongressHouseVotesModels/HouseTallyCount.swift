/// One published House tally field, kept as its source text beside an optional numeric view.
///
/// The Clerk publishes every count as element text. ``rawValue`` is that text exactly, and
/// ``value`` is derived from it: it is set only when the text is a complete nonnegative decimal
/// made of ASCII digits that fits `Int`. Empty, signed, whitespace-padded, fractional, or
/// overflowing text keeps its ``rawValue`` and has a nil ``value``. Leading zeros are read as the
/// decimal they denote, so `007` has the value `7`; compare ``rawValue`` when the exact spelling
/// matters. A published zero reads as `0`, which is distinct from a field the source does not
/// publish at all. Nothing here is summed or recomputed.
///
/// ```swift
/// if let yeas = rollCall.tallies?.byVote.first?.yea {
///   print(yeas.value.map(String.init) ?? "unparsed: \(yeas.rawValue)")
/// }
/// ```
public struct HouseTallyCount: Hashable, Sendable {
  /// The source element's local name, such as `yea-total` or `candidate-total`.
  ///
  /// The original qualified name remains in the enclosing element's `rawNode`.
  public let name: String
  /// The element's complete text, without trimming or normalization.
  public let rawValue: String
  /// The count parsed from ``rawValue``, or nil when the text is not a complete nonnegative
  /// decimal that fits `Int`.
  ///
  /// This is a derived view of the published text, not a separately published number.
  public let value: Int?

  init(node: HouseXMLNode) {
    name = node.localName
    rawValue = node.text
    value =
      rawValue.utf8.allSatisfy { $0 >= UInt8(ascii: "0") && $0 <= UInt8(ascii: "9") }
      ? Int(rawValue) : nil
  }
}
