import SwiftCongressSenateVotesModels

extension SenateVotesClient {
  /// Retrieves one Congress/session inventory without fetching its votes.
  public func index(congress: Int, session: Int) async throws(SenateVotesError) -> SenateVoteIndex {
    let request: SenateVoteRequest<SenateVoteIndex>
    do { request = try .index(congress: congress, session: session) } catch { throw .input(error) }
    return try await value(for: request)
  }

  /// Retrieves the dated current identity inventory without applying it to any vote.
  public func memberIdentities() async throws(SenateVotesError) -> SenateMemberIdentities {
    try await value(for: .memberIdentities)
  }

  /// Retrieves one Senate roll call, including nomination and amendment votes.
  public func rollCall(_ identifier: SenateVoteIdentifier) async throws(SenateVotesError)
    -> SenateRollCall
  {
    try await value(for: .rollCall(identifier))
  }

  /// Validates source coordinates before retrieving one vote.
  public func rollCall(congress: Int, number: Int, session: Int) async throws(SenateVotesError)
    -> SenateRollCall
  {
    let identifier: SenateVoteIdentifier
    do {
      identifier = try SenateVoteIdentifier(congress: congress, number: number, session: session)
    } catch { throw .input(error) }
    return try await value(for: .rollCall(identifier))
  }
}
