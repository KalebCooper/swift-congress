# swift-congress

![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)

Independent Swift libraries for published United States congressional records.

## Status

Congress.gov discovery, bill detail, bill lists, and action lists are implemented with portable
models, typed requests/endpoints, lazy page and item sequences, and exact source response receipts.
Fixtures cover Congresses 6, 82, and 119 and the earliest Congress discovery page. Unknown fields,
null values, and historical source identifiers are preserved. No historical completeness,
stable snapshot, freshness, availability, or identity matching is guaranteed.

Bioguide supplied-file import verifies bounded profile reads, inventory counts, SHA-256, source IDs,
and predecessor-body affiliations. A full 13,056-profile official snapshot has passed the importer.
House year/section discovery and roll calls are implemented independently, including historical
rows without member IDs. Senate session inventories, roll calls, and the dated current LIS-to-Bioguide crosswalk are
also independent services. Historical identity gaps remain unresolved. No package release exists.
Member and bill-text-version operations remain pending official payload verification after rate limiting.
See [implementation readiness](IMPLEMENTATION_READINESS.md) for validation status.

## Usage

```swift
import SwiftCongressData
import SwiftCongressDataModels

let client = CongressDataClient(apiKey: key, userAgent: "MyCivicApp/1.0")
let source = try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill)
let detail = try await client.bill(source)
let reusable = CongressRequest.bill(source)
let same = try await client.value(for: reusable)

for try await bill in client.bills(matching: try BillQuery(congress: 6)) {
  print(bill.title)
}
```

Use `response(for:)` for one endpoint receipt and `billPages(matching:)` for page receipts.
Each receipt contains the exact decoded bytes, status, and repeated headers. Configure transports
explicitly off Apple platforms. API keys are required and are sent only through X-Api-Key.

## Example

`Examples/CongressDataDemo` decodes an official recorded bill from a supplied file path.
Its Apple live mode accepts `--live` and an explicit API key. The demo never supplies a default key.
The deterministic example input is `Sources/SwiftCongressDataTestSupport/Fixtures/bill6.json`.

`Examples/CongressBioguideDemo` validates every profile in a staged export directory. Prepare a
supplied official all-profile ZIP with `Scripts/prepare-bioguide.py`; provide the actual retrieval
instant and a new output directory. Refresh scheduling and snapshot promotion belong to the caller.

`Examples/CongressHouseVotesDemo` reads a supplied House roll-call XML file, or uses `--live` on Apple.

`Examples/CongressSenateVotesDemo` reads a supplied Senate XML vote, or uses `--live` on Apple.

## Products

| Product | Responsibility |
| --- | --- |
| SwiftCongressBioguide | Bounded supplied-file import, manifest and digest validation |
| SwiftCongressBioguideModels | Profiles, source service affiliations, and archive provenance |
| SwiftCongressData | Congress.gov execution, lazy traversal, and response capture |
| SwiftCongressDataModels | Portable records, source identities, requests, endpoints, and continuation validation |

| SwiftCongressHouseVotes | Bounded House index and roll-call retrieval |
| SwiftCongressHouseVotesModels | Independent HTML inventories, XML records, typed requests and endpoints |

| SwiftCongressSenateVotes | Bounded Senate inventory, vote, and current identity retrieval |
| SwiftCongressSenateVotesModels | Independent Senate XML records, source identities, requests and endpoints |

## Requirements

Swift tools 6.2, Swift 6, and iOS, macOS, tvOS, visionOS, or watchOS 26.
Linux and Android use the optional HTTPPortable trait and an injected transport.
No transport dependency is required to use a models product.

## Installation

This repository is local and unreleased. Add it as a local Swift package and select the required
library products. The HTTP SDK requires the verified public swifty-networking 1.3.1 or later.

## License

MIT. See [LICENSE](LICENSE). The package license does not grant rights to upstream portraits or
other separately restricted source assets. Recorded sources are attributed in fixture manifests.
