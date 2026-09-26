/// A read-only view of a Bioguide position's source `job` object.
///
/// The view is derived from the retained JSON and never replaces it: ``BioguidePosition/job``
/// keeps the original value, and ``rawFields`` keeps every key of the object, including unknown
/// ones. A field that is absent, null, or not a string reads as nil here. The job name is not a
/// chamber and implies nothing about dates of service.
///
/// ```swift
/// if let job = position.jobDetails, job.name == .senator {
///   print(job.jobType ?? "no job type")
/// }
/// ```
public struct BioguideJob: Hashable, Sendable {
  /// The source `jobType` string, such as `CongressMemberJob`; nil when absent or not a string.
  public let jobType: String?
  /// The source `name`, preserved in its exact spelling; nil when absent or not a string.
  public let name: BioguideJobName?
  /// Every field of the source `job` object, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]

  init(rawFields: [String: JSONValue]) {
    jobType = rawFields["jobType"]?.string
    name = rawFields["name"]?.string.map(BioguideJobName.init(rawValue:))
    self.rawFields = rawFields
  }
}
