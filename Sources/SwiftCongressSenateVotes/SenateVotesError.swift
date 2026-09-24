// Public SDK signatures expose the transport vocabulary.
@_exported import HTTPCore
import SwiftCongressSenateVotesModels

/// A Senate source execution or decoding failure.
public enum SenateVotesError: Error {
  /// The source bytes failed bounded decoding.
  case decoding(SenateDecodingError)
  /// Invalid caller-supplied year or roll coordinates.
  case input(SenateInputError)
  /// A link does not belong to the permitted source origin.
  case invalidLink
  /// The streamed document exceeded the client's byte limit.
  case responseTooLarge
  /// Transport, HTTP status, retry, or cancellation failure, retaining source headers.
  case transport(TransportError)
}
