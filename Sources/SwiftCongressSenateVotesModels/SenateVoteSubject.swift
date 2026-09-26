/// What the Senate associated with a roll call, read from its `document` and `amendment` elements.
///
/// The subject identifies the item the vote concerned; it never states an outcome. Whether the
/// Senate invoked cloture, confirmed, ratified, agreed, or rejected stays on the roll call's
/// `question` and `result`. Every case keeps the published elements reachable, and a shape this
/// module does not recognize is ``unknown(_:)`` rather than a guess. See
/// ``SenateRollCall/subject`` for the order in which the cases are selected.
///
/// ```swift
/// switch rollCall.subject {
/// case .amendment(let amendment)?: print(amendment.number)
/// case .bill(let bill)?: print(bill.measureType.rawValue, bill.number ?? "")
/// case .nomination(let nomination)?: print("PN", nomination.number ?? "")
/// case .treaty(let treaty)?: print("Treaty Doc.", treaty.number ?? "")
/// case .unknown(let unknown)?: print(unknown.reason)
/// case nil: print("no subject metadata published")
/// }
/// ```
public enum SenateVoteSubject: Hashable, Sendable {
  /// An amendment, selected by a nonempty `amendment_number`.
  case amendment(SenateAmendmentSubject)
  /// A bill or resolution, selected by a documented `document_type` code.
  case bill(SenateBillSubject)
  /// A nomination, selected by the `document_type` `PN`.
  case nomination(SenateNominationSubject)
  /// A treaty document, selected by the `document_type` `Treaty Doc.`.
  case treaty(SenateTreatySubject)
  /// Substantive metadata in a shape this module does not recognize.
  case unknown(SenateUnknownSubject)
}
