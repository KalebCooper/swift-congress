# ``SwiftCongressData``

Discover Congresses and retrieve bill records and actions through Congress.gov.

## Overview

Supply an API.data.gov key and application identity explicitly. On Apple platforms:

```swift
let client = CongressDataClient(apiKey: key, userAgent: "MyCivicApp/1.0")
let key = try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill)
let detail = try await client.bill(key)
```

Everyday methods delegate to immutable requests and typed endpoints. A stored request
can be inspected, reused, or given a consumer-defined name:

```swift
let request = CongressRequest.bill(key)
let detail = try await client.value(for: request)
let same = try await client.send(Endpoint.bill(key))
```

On Linux and Android, enable the HTTPPortable trait and inject a transport. Each SDK
is independent; this product imports no chamber or Bioguide service.

## Inventories and receipts

```swift
for try await congress in client.congresses() {
  print(congress.name)
}
let query = try BillQuery(congress: 6, limit: 100)
for try await receipt in client.billPages(matching: query) {
  persist(receipt.body, headers: receipt.headers)
  for bill in receipt.value.bills { print(bill.title) }
}
```

Each page retains the exact bytes decoded, response headers including repeated names,
and HTTP status. Single endpoints expose the same receipt through `response(for:)`.
The caller supplies retrieval timestamps and durable hashes. No second request or
re-encoding is used to obtain original bytes.

Sequences are lazy and independent, never prefetch, and preserve source order and
duplicates. Item iteration checks cancellation even while records remain buffered.
Malformed, missing, or nonprogressing continuations fail before yielding that page.
Failures end an iterator; earlier pages do not establish a complete inventory.
Custom endpoint requests yield just one response unless a built-in collection
request explicitly describes pagination.

## Access policy and limits

Congress.gov documents a default page size of 20, a maximum of 250, and 5,000
requests per hour for standard keys. Demo-key limits are lower. Returned inventories
can change during traversal and are not stable snapshots. Bill queries support
provider modification windows; the library does not claim complete historical coverage.

Credentials are sent only through X-Api-Key. Endpoint construction rejects another
origin, URL credentials, fragments, and api_key query parameters. Redirects are
refused. Retry policy defaults to disabled and can be injected with a clock; there
is no second retry loop. HTTP errors retain status, bytes, and quota/Retry-After
headers in the transport error. Callers coordinate credentials and sync policy.

Responses are buffered by the networking layer. Use bounded page sizes; this SDK
does not provide a streaming bulk importer for Congress.gov JSON.

## Historical interpretation

Early bills can carry surrogate source numbers. Use BillSourceIdentifier without
asserting those numbers are official. Older law records may omit sponsors and
other modern fields. Congress discovery includes chamber-specific sessions and
nullable session numbers. Dates stay source strings; unknown fields remain in
each record's rawFields. Source overlap is not independent corroboration.

## Topics

### Execution

- ``CongressDataClient``
- ``CongressDataConfiguration``
- ``CongressDataError``

### Lazy traversal

- ``CongressPageSequence``
- ``CongressItemSequence``
