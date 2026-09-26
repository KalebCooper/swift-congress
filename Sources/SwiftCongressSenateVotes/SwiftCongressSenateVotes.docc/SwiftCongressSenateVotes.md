# ``SwiftCongressSenateVotes``

Retrieve independent Senate inventories, roll calls, and current identity records.

## Overview

Senate vote identities use Congress, session, and vote number. They are distinct from
House year/roll identities and Congress.gov bill keys. Source inventories enumerate
explicit votes; no assumed numeric range is generated and no linked vote is prefetched.

```swift
let identifier = try SenateVoteIdentifier(congress: 101, number: 1, session: 1)
let endpoint = Endpoint.rollCall(identifier)
let request = SenateVoteRequest.rollCall(identifier)
```

Records retain nominations, amendments and their target documents, procedural questions,
majority requirements, source totals, and open position codes. XML trees preserve mixed
text, nested measure elements, namespaces, attributes, unknown fields, and empty values.
Dates remain source strings. Original bytes are available from SDK response receipts.

## Identity boundaries

The current LIS-to-Bioguide inventory is a separately retrieved and dated source.
Its `lastUpdate` metadata stays attached to that document. The library exposes only
explicit LIS and optional Bioguide fields and never matches names or applies current
party or state metadata to historical votes. Duplicate rows remain distinct.
The recorded current inventory matches only two LIS IDs in the 1989 fixture; it is not
a complete historical crosswalk. Unmatched identities must stay unresolved.

## Bounds and source coverage

The system XML codec bounds bytes, depth, and element count, supports declared source
encodings, and never resolves external entities. Entity declaration markers are rejected
before parsing, including literal markers inside comments or CDATA. This conservative
restriction prevents silent entity omission in platform XML implementations.

Official source: [Senate XML availability](https://www.senate.gov/general/XML.htm).
Fixtures include the 1989 nomination vote, a 2026 amendment cloture vote, historical and
current inventories, and the current identity export. Each recording includes its URL,
retrieval time, HTTP metadata, byte count, and SHA-256 in the fixture manifest.
These samples do not establish complete historical coverage or future availability.

## Execution

On Apple platforms:

```swift
let client = SenateVotesClient(userAgent: "MyCivicApp/1.0")
let index = try await client.index(congress: 119, session: 2)
let vote = try await client.rollCall(identifier)
let same = try await client.value(for: request)
let receipt = try await client.response(for: endpoint)
let currentIdentities = try await client.memberIdentities()
```

Other platforms inject a swifty-networking transport; HTTPPortable is opt-in.
Custom `SenateResponse` conformances share the same execution path through validated
origin-constrained endpoints. Redirects are refused. Retries default to disabled and
can be configured with an injected clock. The default 16 MiB body limit is enforced
while consuming response chunks. Size, cancellation, source-decoding, and HTTP failures
return no partial value. HTTP errors preserve quota and Retry-After headers.

The caller supplies receipt timestamps, hashing, storage, refresh policy, and completion
accounting. No service imports the House, Congress.gov, or Bioguide SDK.

Non-success HTTP responses use HTTPCore's separate 64 KiB error-body capture bound.
Their headers and status remain available in the transport error.

## Topics

- ``SenateVotesClient``
- ``SenateVotesError``
- <doc:VoteSubjects>
