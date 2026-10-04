# Committee House communication references

Retrieve a House committee's published communications with their original types and dates.

## Request one response or traverse lazily

```swift
let committee = try CommitteeIdentifier(chamber: .house, code: "hsso00")
let page = try CongressQuery(limit: 5)
let request = try CongressRequest.committeeHouseCommunications(for: committee, page: page)
let first = try await client.value(for: request)
let same = try await client.send(Endpoint.committeeHouseCommunications(for: committee, page: page))
let pages = try client.committeeHouseCommunicationPages(for: committee, page: page)
for try await receipt in pages {
  print(receipt.value.houseCommunications)
  break
}
let communications = try client.committeeHouseCommunications(for: committee, page: page)
for try await communication in communications {
  print(communication.number, communication.communicationType.code, communication.referralDate as Any)
  break
}
```

This route accepts `CongressQuery` page bounds only. It has no Congress, date-window or sort
filter. Factories and sequence construction throw `CongressInputError.unsupportedCommitteeResource`
synchronously for Senate or Joint identifiers, before HTTP. Iteration uses `CongressDataError`
for execution, decoding, cancellation and continuation failures.

Each traversal is independent and lazy, with no prefetch. Page receipts retain exact response bytes,
headers and status. Generic `pages(for:)` and `items(for:)` traverse the same built-in collection;
a manually constructed `CongressRequest(endpoint:)` still describes only one response.
Cancellation is checked before I/O and each buffered item. Invalid origin, identity, filters,
paging or counts fail before that page is yielded. Quota failures retain response headers and
status. Failure ends an iterator; earlier pages do not prove complete coverage.

## Preserve reference meaning

Congress, number and communication type remain distinct identity fields. The open type code and
optional name preserve source vocabulary, including EC/Executive Communication and PT/Petition.
Referral dates and modification dates have different meanings and remain unchanged strings.
No chamber, name, date or URL is inferred. Order and duplicate records survive. Links are metadata
only; no standalone communication detail or document asset is automatically fetched.

Four House Ethics captures include a partial discovery page and a complete exact-link 5/5/5
chain with count 15. It contains twelve Executive Communications and three Petitions across
Congresses 114 through 119. These captures do not establish historical completeness or a stable
snapshot. Senate committee communications are a separate route.

Run the offline Data demo with `--committee-house-communications <absolute fixture path>` to
inspect Congress, number, type, name, chamber, referral/update dates, URL and source count.
