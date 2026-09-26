/// An amendment the Senate associated with a roll call.
///
/// The subject is selected when the `amendment` element publishes a nonempty `amendment_number`;
/// the text is compared without trimming, so a whitespace-only number still selects it. Every
/// other field reads one child of that element and is nil when the child is absent, as the
/// short title is in 2010 records, or the empty string when published empty. The roll call's
/// top-level `document` element, which may publish the amendment code with an empty number or
/// nothing but a Congress, stays separately in ``document``. ``target`` reads the target document
/// label conservatively; the label itself is always in ``targetDocumentNumber``. The published
/// `amendment_purpose`, often the boilerplate `No Statement of Purpose on File.`, is kept verbatim
/// and never used for classification. Nothing beyond the published fields is produced: no
/// amendment number from the vote title, no target beyond the label, and no chain of amendments.
///
/// ```swift
/// if case .amendment(let amendment)? = rollCall.subject {
///   print(amendment.number, "to", amendment.targetDocumentNumber ?? "no target published")
/// }
/// ```
public struct SenateAmendmentSubject: Hashable, Sendable {
  /// The roll call's top-level `document` element, when published.
  public let document: SenateDocumentReference?
  /// The `amendment_number` text exactly as published, such as `S.Amdt. 6776`.
  public let number: String
  /// The `amendment_purpose` text, verbatim.
  public let purpose: String?
  /// The complete `amendment` element, including unknown children.
  public let rawNode: SenateXMLNode
  /// The reading of ``targetDocumentNumber``, or nil when that label is absent or empty.
  public let target: SenateAmendmentTarget?
  /// The `amendment_to_amendment_number` text, the amendment this one amends.
  public let targetAmendmentNumber: String?
  /// The `amendment_to_amendment_to_amendment_number` text, the amendment that one amends.
  public let targetAmendmentTargetNumber: String?
  /// The `amendment_to_document_number` text, the target document's label as published.
  public let targetDocumentNumber: String?
  /// The `amendment_to_document_short_title` text.
  public let targetDocumentShortTitle: String?

  init(document: SenateDocumentReference?, node: SenateXMLNode, number: String) {
    self.document = document
    self.number = number
    purpose = node.child("amendment_purpose")?.text
    rawNode = node
    let label = node.child("amendment_to_document_number")?.text
    target = label.flatMap(SenateAmendmentTarget.init(label:))
    targetAmendmentNumber = node.child("amendment_to_amendment_number")?.text
    targetAmendmentTargetNumber = node.child("amendment_to_amendment_to_amendment_number")?.text
    targetDocumentNumber = label
    targetDocumentShortTitle = node.child("amendment_to_document_short_title")?.text
  }

  /// Whether the element names any target without a number, which classification treats as
  /// substantive but unrecognized.
  static func hasTargetFields(_ node: SenateXMLNode) -> Bool {
    [
      "amendment_to_amendment_number", "amendment_to_amendment_to_amendment_number",
      "amendment_to_document_number", "amendment_to_document_short_title",
    ].contains { node.child($0)?.text.isEmpty == false }
  }
}
