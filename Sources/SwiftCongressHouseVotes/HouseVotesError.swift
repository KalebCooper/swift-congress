// Public SDK signatures expose the transport vocabulary.
@_exported import HTTPCore
import SwiftCongressHouseVotesModels

/// A House source execution or decoding failure.
public enum HouseVotesError: Error {
  /// The source bytes failed bounded decoding.
  case decoding(HouseDecodingError)
  /// Invalid caller-supplied year or roll coordinates.
  case input(HouseInputError)
  /// A link does not belong to the permitted source origin.
  case invalidLink
  /// The streamed document exceeded the client's byte limit.
  case responseTooLarge
  /// Transport, HTTP status, retry, or cancellation failure, retaining source headers.
  case transport(TransportError)
}
