# ``SwiftCongressSenateVotesModels``

Preserve Senate XML records without an HTTP dependency.

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
