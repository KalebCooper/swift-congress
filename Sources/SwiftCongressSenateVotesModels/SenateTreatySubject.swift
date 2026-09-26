/// A treaty document the Senate associated with a roll call.
///
/// The subject is selected when the `document_type` is `Treaty Doc.`. ``number`` is the published
/// `document_number` as one string, so a compound value such as `111-5` is never split into a
/// Congress and a bill number, and a suffix survives verbatim. The number may be empty when the
/// Senate published none. Ratification, cloture, and amendment questions stay on the roll call's
/// `question`; an amendment to a treaty is a separate ``SenateAmendmentSubject`` whose target
/// names the treaty.
///
/// ```swift
/// if case .treaty(let treaty)? = rollCall.subject {
///   print("Treaty Doc.", treaty.number ?? "unnumbered")
/// }
/// ```
public struct SenateTreatySubject: Hashable, Sendable {
  /// The complete published document view.
  public let document: SenateDocumentReference

  /// The `document_number` text exactly as published, the same value as `document.number`.
  public var number: String? { document.number }

  init(document: SenateDocumentReference) { self.document = document }
}
