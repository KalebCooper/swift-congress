/// A Senate roll call's published `document` element as a typed view.
///
/// Each property reads one direct child of the element: `document_congress`, `document_name`,
/// `document_number`, `document_short_title`, `document_title`, and `document_type`. A property
/// is nil when its element is absent, as `document_congress` is in 1989 records, and the empty
/// string when the element is published empty, so a caller can tell the two apart. Text is the
/// element's complete character content without trimming or normalization; a number such as
/// `111-5` or `999-1` stays one string. The Congress is the document's own declaration, never the
/// roll call's coordinates. The view describes what the Senate associated with the vote; it is not
/// a Congress.gov identifier and it is joined to no other service.
///
/// ```swift
/// if case .treaty(let treaty)? = rollCall.subject {
///   print(treaty.document.number ?? "no number", treaty.document.congress ?? "no congress")
/// }
/// ```
public struct SenateDocumentReference: Hashable, Sendable {
  /// The `document_congress` text, absent in historical records.
  public let congress: String?
  /// The `document_name` text, such as `PN128` or `H.R. 3082`.
  public let name: String?
  /// The `document_number` text exactly as published, such as `128`, `3082`, or `111-5`.
  public let number: String?
  /// The complete `document` element, including unknown children.
  public let rawNode: SenateXMLNode
  /// The `document_short_title` text.
  public let shortTitle: String?
  /// The `document_title` text.
  public let title: String?
  /// The `document_type` text, such as `PN`, `Treaty Doc.`, or `H.R.`.
  public let type: String?

  init(node: SenateXMLNode) {
    congress = node.child("document_congress")?.text
    name = node.child("document_name")?.text
    number = node.child("document_number")?.text
    rawNode = node
    shortTitle = node.child("document_short_title")?.text
    title = node.child("document_title")?.text
    type = node.child("document_type")?.text
  }

  /// Whether any identifying field is nonempty; the Congress alone identifies nothing.
  var isSubstantive: Bool {
    [name, number, shortTitle, title, type].contains { $0?.isEmpty == false }
  }
}
