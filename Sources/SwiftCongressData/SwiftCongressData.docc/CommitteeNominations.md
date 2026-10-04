# Committee nomination references

Retrieve a Senate committee's published nominations while preserving each source number and part.

## Request one response or traverse lazily

```swift
let committee = try CommitteeIdentifier(chamber: .senate, code: "slia00")
let page = try CongressQuery(limit: 32)
let request = try CongressRequest.committeeNominations(for: committee, page: page)
let first = try await client.value(for: request)
let same = try await client.send(Endpoint.committeeNominations(for: committee, page: page))
let pages = try client.committeeNominationPages(for: committee, page: page)
for try await receipt in pages {
  print(receipt.value.nominations)
  break
}
let nominations = try client.committeeNominations(for: committee, page: page)
for try await nomination in nominations {
  print(nomination.number, nomination.partNumber, nomination.latestAction?.text as Any)
  break
}
```

This route accepts `CongressQuery` page bounds only. It has no Congress, date-window or sort
filter. Factories and sequence construction throw `CongressInputError.unsupportedCommitteeResource`
synchronously for House or Joint identifiers, before HTTP. Iteration uses `CongressDataError`
for execution, decoding, cancellation and continuation failures.

Each traversal is independent and lazy, with no prefetch. Pages retain exact decoded bytes,
headers and status. Generic `pages(for:)` and `items(for:)` traverse the same built-in collection;
a manually constructed `CongressRequest(endpoint:)` still describes only one response.
Cancellation is checked before I/O and each buffered item. Invalid origin, identity, filters,
paging or counts fail before that page is yielded. Quota failures retain response headers and
status. Failure ends an iterator; earlier pages do not prove complete coverage.

## Preserve reference meaning

A nomination's integer number and string part remain separate. Leading zeroes in parts `00`
and `09` survive. Citation, description, received/update dates, latest action and civilian/military
flags retain their source meaning. No current status is inferred from action text, and no part
is inferred from a URL. Order and duplicate records survive. Links are metadata only; no
nomination detail or document asset is automatically fetched.

Four Senate Indian Affairs captures include one partial discovery page and a complete exact-link
32/32/32 chain with count 96. The chain spans Congresses 97 through 119 with gaps, and includes
confirmation, withdrawal and return-to-President actions. All recorded type flags are civilian
true and military false; this does not constrain other source records or establish historical
completeness or a stable snapshot.

Run the offline Data demo with `--committee-nominations <absolute fixture path>` to inspect
number, unchanged part, citation, received/update dates, URL and source count.
