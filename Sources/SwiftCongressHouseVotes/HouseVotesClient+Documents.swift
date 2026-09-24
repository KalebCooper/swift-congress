#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressHouseVotesModels

extension HouseVotesClient {
  /// Retrieves one discovered section index from an official HTTPS link.
  public func index(at link: URL) async throws(HouseVotesError) -> HouseVoteIndex {
    guard let endpoint = Endpoint<HouseVoteIndex>(link: link) else { throw .invalidLink }
    return try await value(for: HouseVoteRequest(endpoint: endpoint))
  }

  /// Retrieves one year index; section inventories remain independent requests.
  public func index(year: Int) async throws(HouseVotesError) -> HouseVoteIndex {
    let request: HouseVoteRequest<HouseVoteIndex>
    do { request = try .index(year: year) } catch { throw .input(error) }
    return try await value(for: request)
  }

  /// Retrieves a House roll call, including procedural and quorum calls.
  public func rollCall(_ identifier: HouseVoteIdentifier) async throws(HouseVotesError)
    -> HouseRollCall
  {
    try await value(for: .rollCall(identifier))
  }

  /// Validates coordinates before retrieving one House roll call.
  public func rollCall(number: Int, year: Int) async throws(HouseVotesError) -> HouseRollCall {
    let identifier: HouseVoteIdentifier
    do { identifier = try HouseVoteIdentifier(number: number, year: year) } catch {
      throw .input(error)
    }
    return try await value(for: .rollCall(identifier))
  }
}
