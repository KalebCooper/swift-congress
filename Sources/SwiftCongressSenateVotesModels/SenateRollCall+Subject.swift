extension SenateRollCall {
  /// The item the Senate associated with this vote, computed on each access from `document` and
  /// `amendment`.
  ///
  /// The cases are selected in order, comparing element text exactly and without trimming. A
  /// nonempty `amendment_number` selects ``SenateVoteSubject/amendment(_:)``; a merely present or
  /// empty `amendment` element, as the recorded nomination, bill, and treaty files do, does not.
  /// Otherwise the `document_type` decides: `PN` selects ``SenateVoteSubject/nomination(_:)``,
  /// `Treaty Doc.` selects ``SenateVoteSubject/treaty(_:)``, and one of the eight
  /// ``SenateMeasureType`` codes selects ``SenateVoteSubject/bill(_:)``. Any other nonempty
  /// substantive metadata, meaning a nonempty type, number, name, title, or short title of the
  /// document or a nonempty target field of the amendment, is ``SenateVoteSubject/unknown(_:)``
  /// with a ``SenateUnknownSubjectReason``. When neither element publishes such a field, the value
  /// is nil; a `document_congress` alone and the boilerplate `amendment_purpose` are not
  /// substantive. Reading this property changes no stored value and no `Codable` output, and no
  /// identity is inferred from the vote title, the roll call's coordinates, or any other service.
  ///
  /// ```swift
  /// if case .treaty(let treaty)? = rollCall.subject {
  ///   print(treaty.number ?? "unnumbered", rollCall.question ?? "")
  /// }
  /// ```
  public var subject: SenateVoteSubject? {
    let document = self.document.map(SenateDocumentReference.init(node:))
    if let amendment, let number = amendment.child("amendment_number")?.text, !number.isEmpty {
      return .amendment(SenateAmendmentSubject(document: document, node: amendment, number: number))
    }
    let documentIsSubstantive = document?.isSubstantive == true
    let amendmentIsSubstantive = amendment.map(SenateAmendmentSubject.hasTargetFields) == true
    guard documentIsSubstantive || amendmentIsSubstantive else { return nil }
    func unknown(_ reason: SenateUnknownSubjectReason) -> SenateVoteSubject {
      .unknown(SenateUnknownSubject(amendment: amendment, document: document, reason: reason))
    }
    guard let document, let type = document.type, !type.isEmpty else {
      return unknown(documentIsSubstantive ? .documentTypeMissing : .amendmentNumberMissing)
    }
    switch type {
    case "PN": return .nomination(SenateNominationSubject(document: document))
    case "S.Amdt.": return unknown(.amendmentNumberMissing)
    case "Treaty Doc.": return .treaty(SenateTreatySubject(document: document))
    default:
      guard let measureType = SenateMeasureType.recognized(type) else {
        return unknown(.documentTypeUnrecognized)
      }
      return .bill(SenateBillSubject(document: document, measureType: measureType))
    }
  }
}
