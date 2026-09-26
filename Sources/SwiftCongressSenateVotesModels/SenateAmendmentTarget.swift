/// A conservative reading of an amendment's published `amendment_to_document_number` label.
///
/// The label is read exactly, without trimming, case folding, or normalization. It is split at its
/// last space: leading words equal to one ``SenateMeasureType`` code followed by an ASCII decimal
/// number with no leading zero read as ``bill(_:number:)``, as `S. 4668` does; leading words equal
/// to `Treaty Doc.` followed by any nonempty text read as ``treaty(number:)``, as
/// `Treaty Doc. 111-5` does, and the number is kept whole. Every other label, including one with
/// no space, a trailing space, an amendment code, or a zero-padded number, is ``unknown(label:)``
/// with its text retained. The raw label is always also available as
/// ``SenateAmendmentSubject/targetDocumentNumber``. Nothing is guessed: no Congress, title, or
/// document beyond the label is produced.
///
/// ```swift
/// switch amendment.target {
/// case .bill(let type, let number)?: print(type.rawValue, number)
/// case .treaty(let number)?: print("Treaty Doc.", number)
/// case .unknown(let label)?: print("unrecognized", label)
/// case nil: print("no target document published")
/// }
/// ```
public enum SenateAmendmentTarget: Hashable, Sendable {
  /// A bill or resolution named by a documented code and a decimal number.
  case bill(SenateMeasureType, number: String)
  /// A treaty document named by `Treaty Doc.` and its complete number.
  case treaty(number: String)
  /// A nonempty label this module does not read, kept verbatim.
  case unknown(label: String)

  /// Reads a published label, or returns nil for an empty one.
  init?(label: String) {
    guard !label.isEmpty else { return nil }
    guard let separator = label.lastIndex(of: " ") else {
      self = .unknown(label: label)
      return
    }
    let words = String(label[..<separator])
    let remainder = String(label[label.index(after: separator)...])
    if words == "Treaty Doc." {
      self = remainder.isEmpty ? .unknown(label: label) : .treaty(number: remainder)
    } else if let measureType = SenateMeasureType.recognized(words), Self.isDecimal(remainder) {
      self = .bill(measureType, number: remainder)
    } else {
      self = .unknown(label: label)
    }
  }

  private static func isDecimal(_ text: String) -> Bool {
    guard let first = text.utf8.first, first >= UInt8(ascii: "1"), first <= UInt8(ascii: "9")
    else { return false }
    return text.utf8.allSatisfy { $0 >= UInt8(ascii: "0") && $0 <= UInt8(ascii: "9") }
  }
}
