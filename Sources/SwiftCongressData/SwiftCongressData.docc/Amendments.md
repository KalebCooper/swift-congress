# Amendment inventories and detail

Browse Congress.gov amendments, inspect independent targets and retrieve bill-associated lists.

## Queries and execution

```swift
let query = try AmendmentQuery(limit: 2, scope: .congress(117))
let stored = CongressRequest.amendments(matching: query)
let first = try await client.value(for: stored)
for try await receipt in client.amendmentPages(matching: query) {
  print(receipt.value.amendments.count)
  break
}
let identifier = try AmendmentIdentifier(congress: 117, number: "2564", type: .senateAmendment)
let detail = try await client.amendment(identifier)
let same = try await client.send(Endpoint.amendment(identifier))
```

`AmendmentQuery.Scope` supports all available Congresses, one Congress and one Congress/type.
Known `AmendmentType` values are House, Senate and Senate unprinted amendments. Decoded type
spelling remains unchanged; validated request identifiers normalize safe ASCII letter codes
to lowercase and preserve positive ASCII decimal number strings. Unknown safe codes remain
usable. SUAMDT coverage is documented for Congresses 97 and 98, but the request API accepts
other positive Congresses without claiming the provider has records for them.

`AmendmentQuery` and `BillAmendmentQuery` carry pagination and optional modification windows.
Timestamp strings are encoded for source-side validation. There is no sort parameter. The
recorded examples do not establish live date-window filtering behavior.

```swift
let bill = try BillIdentifier(congress: 117, number: "3076", type: .houseBill)
let query = try BillAmendmentQuery(limit: 16)
let stored = CongressRequest.amendments(for: bill, matching: query)
for try await amendment in client.amendments(for: bill, matching: query) {
  print(amendment.congress, amendment.type.rawValue, amendment.number)
}
```

The bill entry point also accepts `BillSourceIdentifier`. `AmendmentPage` preserves the same
sparse `amendments` envelope used by inventories. Bill lists may omit description, purpose and
latest action; these remain unavailable rather than synthesized. The recorded bill chain has
16/16/16 records against count 48 and follows the exact returned links.

Everyday methods, stored/contextual requests and typed endpoints use the same executor.
Consumer-defined constrained factories can name either requests or endpoints:

```swift
extension CongressRequest where Response == AmendmentDetail {
  static func amendmentForArchive(_ identifier: AmendmentIdentifier) -> Self {
    .amendment(identifier)
  }
}
extension Endpoint where Response == AmendmentDetail {
  static func amendmentForArchive(_ identifier: AmendmentIdentifier) -> Self {
    .amendment(identifier)
  }
}
let detail = try await client.value(for: .amendmentForArchive(identifier))
let receipt = try await client.response(for: .amendmentForArchive(identifier))
```

`value(for:)`, `send(_:)` and custom endpoint-backed requests fetch one response. Page and item
sequences are lazy and independent, never prefetch, and check cancellation before requests and
buffered items. Invalid origin, scope, filters, bounds or nonprogressing continuation fails
before yielding that page. The initial and later response receipts retain exact bytes, headers
and status. Earlier pages do not establish completeness after a later failure, and inventories
can change during traversal. Amendment pages use ordinary strict continuation.

## Targets and source interpretation

`AmendmentDetail.amendment` keeps amended bill, amendment and treaty fields independently.
Recorded Senate amendment 117/2564 has both a bill and amendment target. Treaty amendment
116/946 uses the integer `treatyNumber` key. No target triggers a request or implies graph
ancestry. The bill target reuses the compatible `Bill` record; extra nested fields such as
`originChamberCode` and `updateDateIncludingText` remain in that record's `rawFields`.

Description and purpose, submission and proposal dates, sponsors and on-behalf members, notes,
and resource counts/links remain separate. Cosponsor metadata exposes its independent
`countIncludingWithdrawnCosponsors`. Action links retain raw vote names and URLs without
fetching a chamber vote or deriving an outcome. Historical SUAMDT 97/3 retains its API number
3 even though its recorded latest-action text/link names SP 2. No identity is inferred from
that text or URL. Source ordering, duplicates, unknown values, nulls and omissions survive.

Actions, child-amendment, cosponsor and text resource links are metadata here. This directory
surface does not retrieve those subresources, recurse through targets or download text assets.
Congress.gov, House votes, Senate votes and Bioguide remain independent services.

## Offline example

CongressDataDemo accepts `--amendments` for either inventory or bill-list fixtures and
`--amendment` for a detail fixture, followed by an absolute file path. Output preserves source
identity and prints each present target separately. No credential is needed for offline decoding.
