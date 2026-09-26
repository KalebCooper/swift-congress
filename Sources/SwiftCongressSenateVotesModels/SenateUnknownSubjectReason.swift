/// Why a roll call's substantive subject metadata was not recognized.
///
/// Each case names one exact shape of the published `document` and `amendment` elements. The
/// reasons are bounded by this module's classification rules, so the enum is closed; the elements
/// themselves stay on ``SenateUnknownSubject`` for a caller to read.
///
/// ```swift
/// if case .unknown(let unknown)? = rollCall.subject, unknown.reason == .documentTypeUnrecognized {
///   print("unrecognized code", unknown.document?.type ?? "")
/// }
/// ```
public enum SenateUnknownSubjectReason: Hashable, Sendable {
  /// The `document_type` is `S.Amdt.` but `amendment_number` is empty or absent, or a target
  /// field of the `amendment` element is nonempty while `amendment_number` is empty or absent.
  case amendmentNumberMissing
  /// The `document_number`, `document_name`, `document_title`, or `document_short_title` is
  /// nonempty but `document_type` is empty or absent.
  case documentTypeMissing
  /// The `document_type` is nonempty and is not `PN`, `Treaty Doc.`, `S.Amdt.`, or one of the
  /// eight ``SenateMeasureType`` codes.
  case documentTypeUnrecognized
}
