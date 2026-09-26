/// Substantive subject metadata this module does not recognize.
///
/// The published `document` and `amendment` elements are kept as they were read, so a caller can
/// interpret a code this module does not, and ``reason`` names the exact shape that prevented
/// recognition. No identity is inferred: an unrecognized code is not guessed to be a bill, and a
/// number without a type is not typed by its form.
///
/// ```swift
/// if case .unknown(let unknown)? = rollCall.subject {
///   print(unknown.reason, unknown.document?.rawNode.text ?? "no document element")
/// }
/// ```
public struct SenateUnknownSubject: Hashable, Sendable {
  /// The roll call's `amendment` element, when published.
  public let amendment: SenateXMLNode?
  /// The roll call's `document` element as a typed view, when published.
  public let document: SenateDocumentReference?
  /// The shape that prevented recognition.
  public let reason: SenateUnknownSubjectReason

  init(
    amendment: SenateXMLNode?, document: SenateDocumentReference?,
    reason: SenateUnknownSubjectReason
  ) {
    self.amendment = amendment
    self.document = document
    self.reason = reason
  }
}
