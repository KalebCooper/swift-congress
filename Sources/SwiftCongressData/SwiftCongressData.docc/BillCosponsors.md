# Browse bill cosponsors

Read published cosponsorship records, including withdrawals, with lazy pages or items.

```swift
let bill = try BillIdentifier(congress: 117, number: "3580", type: .senateBill)
let query = try BillCosponsorQuery(limit: 15)
for try await cosponsor in client.cosponsors(for: bill, matching: query) {
  print(cosponsor.fullName ?? cosponsor.bioguideId)
  print(cosponsor.sponsorshipWithdrawnDate ?? "No withdrawal date published")
}
let request = CongressRequest.cosponsors(for: bill, matching: query)
let first = try await client.value(for: request)
let same = try await client.send(Endpoint.cosponsors(for: bill, matching: query))
for try await receipt in client.cosponsorPages(for: bill, matching: query) {
  persist(receipt.body, headers: receipt.headers)
}
```

Both bill identifier forms are supported. Queries provide page bounds, optional source update
windows, and ascending or descending update sorting. Timestamp strings are passed through for
source-side validation; no client-side date filtering occurs. Continuations must retain the route,
page size, and filters. Invalid links and inconsistent counts fail before yielding the affected page.

No request occurs until demand. Traversals are independent, buffer only their current page, check
cancellation even while buffered, never prefetch, and preserve source order and repeated rows.
Receipts retain the original bytes, HTTP status, and headers. A later error leaves earlier pages
usable but does not establish a complete inventory.

## Active and inclusive counts

The recorded 117/s/3580 chain returns 15, 15, and 1 records at offsets 0, 15, and 30. Its active
`pagination.count` is 30, while `countIncludingWithdrawnCosponsors` is 31. This page type uses
the inclusive count for continuation when present, retaining both source totals unchanged.
Missing or null inclusive counts fall back to the active count. Negative totals or an inclusive
total below the active count are rejected before yielding a page. Other collection types retain
their existing count contract, including consumer collections on this route.

Cosponsorship does not establish a vote, endorsement of every provision, or current cosponsor
status from row presence alone. Missing withdrawal dates are not converted into a status flag.
Counts can change during traversal; these records do not establish a stable or complete historical
snapshot. Member URLs are metadata and are never fetched automatically.

See the [official bill endpoint guide](https://github.com/LibraryOfCongress/api.congress.gov/blob/main/Documentation/BillEndpoint.md)
for route documentation. Attributed September 30, 2026 fixtures cover a complete historical chain,
an empty 119/hr/1 response, and a single House row with an integer district. Missing/null mutation
tests describe decoder behavior, not additional observed provider responses.
