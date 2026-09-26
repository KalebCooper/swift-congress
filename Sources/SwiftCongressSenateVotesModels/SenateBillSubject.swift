/// A bill or resolution the Senate associated with a roll call.
///
/// The subject is selected only when the `document_type` equals one of the eight codes in
/// ``SenateMeasureType``, so ``measureType`` is always one of those constants. Every other
/// document field stays as published: ``number`` may be empty when the Senate published no
/// number, and no field is validated, filled in, or joined to another service. The subject says
/// what the vote concerned, not that the measure passed; the roll call's `question` and `result`
/// carry that.
///
/// ```swift
/// if case .bill(let bill)? = rollCall.subject {
///   print(bill.measureType.rawValue, bill.number ?? "no number", bill.document.name ?? "")
/// }
/// ```
public struct SenateBillSubject: Hashable, Sendable {
  /// The complete published document view.
  public let document: SenateDocumentReference
  /// The recognized kind, read from the document's `document_type`.
  public let measureType: SenateMeasureType

  /// The `document_number` text exactly as published, the same value as `document.number`.
  public var number: String? { document.number }

  init(document: SenateDocumentReference, measureType: SenateMeasureType) {
    self.document = document
    self.measureType = measureType
  }
}
