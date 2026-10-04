# Looking up laws and browsing enacted bills

Retrieve a law's originating bill and traverse public or private law inventories.

## Law numbers and bill identities

The law route returns the provider's existing bill envelope. A law number is distinct
from its bill number: public law 119-1 returns bill 119/S/5, and private law 117-1
returns bill 117/HR/681. The SDK preserves both the bill identity and each source
citation in `Bill.laws`; it does not fetch a bill URL after looking up a law.

```swift
let identifier = try LawIdentifier(congress: 119, number: "1", type: .public)
let detail = try await client.law(identifier)
print(detail.bill.number) // "5" in the recorded response
for citation in detail.bill.laws ?? [] {
  print(citation.number ?? "", citation.type ?? "")
}
```

Only the documented public/private categories construct law routes. Citation labels such as
`Public Law` remain open source strings; they are not the route tokens `pub` and `priv`.
Dates, URLs, and unknown fields remain source metadata. No historical completeness is promised.

## Lazy inventories and receipts

```swift
let query = try LawQuery(congress: 117, limit: 1, type: .private)
for try await receipt in client.lawPages(matching: query) {
  persist(receipt.body, headers: receipt.headers)
  for bill in receipt.value.bills { print(bill.title) }
}
for try await bill in client.laws(matching: query) {
  print(bill.number, bill.laws ?? [])
}
```

Omitting `type` selects the combined Congress inventory. Queries accept page sizes 1 through
250 and nonnegative offsets; they do not accept date windows or sorting. Detail requests send
only JSON format. Congress numbers must be positive, with no library historical cutoff.

The captured private-law inventory is a complete linked 1/1/1 chain for Congress 117.
Public and combined inventory fixtures are first-page samples, not complete inventories.
Traversal uses ordinary strict bill-page continuation: origin, Congress, law category, page
size, filters, and progress must remain consistent. Invalid continuation fails before the
affected page is yielded. Counts can change between requests.

Pages and items are lazy, preserve order and duplicates, never prefetch, and check cancellation
even with buffered items. Early termination does not establish completeness. Iteration throws
`CongressDataError` for invalid continuation, transport, HTTP, cancellation, or decoding failures.

## Reusable requests and consumer endpoints

```swift
let request = CongressRequest.laws(matching: query)
let first = try await client.value(for: request)
let same = try await client.send(Endpoint.laws(matching: query))
let detailRequest = CongressRequest.law(identifier)
let detailAgain = try await client.value(for: detailRequest)
let receipt = try await client.response(for: Endpoint.law(identifier))
```

Value and endpoint execution fetch one response. Built-in collection requests drive lazy
traversal; wrapping an endpoint in `CongressRequest(endpoint:)` remains a single response.
Consumers may name reusable requests or supply their own decodable endpoint response type.
Congress.gov data stays independent of Bioguide, House votes, and Senate votes.
