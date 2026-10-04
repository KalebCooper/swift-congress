# Committee report references

Retrieve a committee's published report references with page bounds and modification windows.

## Request one response or traverse lazily

```swift
let committee = try CommitteeIdentifier(chamber: .house, code: "hspw00")
let query = try CommitteeReportQuery(
  fromDateTime: "2015-03-20T00:04:12Z", limit: 12,
  toDateTime: "2015-03-20T00:06:53Z")
let request = CongressRequest.committeeReports(for: committee, matching: query)
let first = try await client.value(for: request)
let same = try await client.send(Endpoint.committeeReports(for: committee, matching: query))
for try await receipt in client.committeeReportPages(for: committee, matching: query) {
  print(receipt.value.reports)
  break
}
for try await report in client.committeeReports(for: committee, matching: query) {
  print(report.citation as Any, report.part as Any)
  break
}
```

The query accepts paging and optional source modification bounds for House, Senate and
Joint committees. It has no Congress or sort filter. Dates pass through to the provider;
the client does not normalize response timestamps or locally filter records.

Each traversal is independent and lazy, with no prefetch. Pages retain the exact decoded
bytes, headers and status. Generic `pages(for:)` and `items(for:)` use the same built-in
collection request; a manually constructed `CongressRequest(endpoint:)` still describes
one response. Cancellation is checked before I/O and before each buffered item. Changed
scope, origin, filters, page size or inconsistent counts fail before yielding that page.
Quota failures retain status and response headers. A failure ends that iterator.

## Keep report parts and links separate

The report number is an integer, separate from its optional integer part. Citation, chamber,
type, update date and URL retain source spelling. A captured reference to report 109/HRPT/519
has part 2 and citation `H. Rept. 109-519,Part 2`; its URL has no part component. Rows stay in
source order with duplicates intact. A shared URL is not a reason to collapse report parts.
No title is inferred and no report detail or document asset is automatically fetched.

Four House committee captures include a complete exact-link 12/12 chain against count 24.
Unfiltered and smaller-window samples remain partial. These observations do not establish
all-time coverage or a stable snapshot; Senate and Joint request support follows the advertised
route contract, without claiming recorded report responses for those chambers.

Run the offline Data demo with `--committee-report-references <absolute fixture path>` to
inspect the recorded number, part, citation, raw timestamp and link.
