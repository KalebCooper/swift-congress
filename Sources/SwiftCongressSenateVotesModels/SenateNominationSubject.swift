/// A nomination the Senate associated with a roll call.
///
/// The subject is selected when the `document_type` is `PN`. ``number`` is the published
/// `document_number` as one string, so `128`, `999-1`, and any future form survive without
/// parsing, and it may be empty when the Senate published none. The document's Congress is
/// ``SenateDocumentReference/congress``, which historical records omit; the roll call's own
/// Congress remains on its `identifier` and is never copied here. No Congress.gov URL or record is
/// inferred. Confirmation, cloture, and other questions stay on the roll call's `question`.
///
/// ```swift
/// if case .nomination(let nomination)? = rollCall.subject {
///   print("PN", nomination.number ?? "unnumbered", nomination.document.title ?? "")
/// }
/// ```
public struct SenateNominationSubject: Hashable, Sendable {
  /// The complete published document view.
  public let document: SenateDocumentReference

  /// The `document_number` text exactly as published, the same value as `document.number`.
  public var number: String? { document.number }

  init(document: SenateDocumentReference) { self.document = document }
}
