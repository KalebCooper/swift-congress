# Bill summaries and publication updates

Read summary versions for one bill, or browse the publication feed within a chosen window.

## Bill versions

```swift
let bill = try BillSourceIdentifier(congress: 119, number: "1", type: .houseBill)
let bounds = try CongressQuery(limit: 2)
for try await summary in client.summaries(for: bill, page: bounds) {
  print(summary.versionCode as Any, summary.actionDate as Any, summary.text as Any)
}
```

The numbered `BillIdentifier` overload uses the same source request. Versions preserve provider
order and repeats. No version is chosen as latest. `text` retains original HTML, while
`versionCode` preserves leading zeros and unknown codes. The action date and record update
timestamp describe different source facts. Optional accessors leave absent and null values as nil;
`rawFields` retains the distinction. A successful historical response may contain no summaries.

## Publication feed

```swift
let query = try SummaryQuery(
  fromDateTime: "2026-09-01T00:00:00Z", limit: 2, scope: .congress(119),
  toDateTime: "2026-09-02T00:00:00Z")
for try await receipt in client.summaryUpdatePages(matching: query) {
  print(receipt.status, receipt.body.count)
  for update in receipt.value.summaries {
    print(update.bill.title, update.lastSummaryUpdateDate as Any)
  }
}
```

The feed has `.all`, `.congress(Int)`, and `.billType(congress:type:)` scopes. Each entry includes
its source bill, chamber fields, and last-summary-update timestamp. Per-bill summaries do not
synthesize these feed fields.

Omitted date bounds retain Congress.gov's recent-day default. A Congress filter does not turn
that default into an all-time inventory. Use finite windows for backfills, and coordinate windows,
durable receipts, and ingestion schedules in the caller. Counts may change during traversal.

## Requests and receipts

```swift
let request = CongressRequest.summaries(for: bill, page: bounds)
let first = try await client.value(for: request)
let endpoint = Endpoint.summaryUpdates(matching: query)
let feed = try await client.send(endpoint)
```

`value(for:)`, `send(_:)`, and consumer endpoint-backed requests each retrieve one response.
`summaryPages(for:page:)` and `summaryUpdatePages(matching:)` yield receipts with the exact bytes
decoded. Item and page sequences fetch only on demand and never prefetch.

Continuation must preserve origin, route, page size, and filters. Invalid metadata fails before
its page is yielded. Recorded sorted feed responses changed a plus in the sort value to a space
on a later next link; that traversal fails explicitly without rewriting the provider URL.
A partial traversal is not a complete window. A separately recorded finite window without
optional sort follows four provider-linked pages to a terminal response, retaining seven entries
in source order. That sample does not establish a stable snapshot or historical completeness.
Summary pages retain strict page-size limits; the separate bill-text overrun exception does not apply.

The existing Data demo accepts `--summaries <absolute-path>` and
`--summary-updates <absolute-path>` for offline inspection of recorded pages.
