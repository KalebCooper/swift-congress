# Browsing CRS reports

Retrieve a report's metadata and traverse published report summaries.

## Retrieve one report

```swift
let identifier = try CRSReportIdentifier(rawValue: "R47175")
let detail = try await client.crsReport(identifier)
print(detail.report.title)
for format in detail.report.formats ?? [] {
  print(format.format ?? "", format.url ?? "")
}
```

Identifiers support safe path components without restricting prefixes to R. Observed records
also use RS and IF. Identifiers retain case; this is not a search or version-selection API.
Format and related-material links are supplied metadata. The client never fetches linked assets.

## Traverse summaries

```swift
let query = try CRSReportQuery(
  fromDateTime: "2026-10-03T00:00:00Z", limit: 5,
  toDateTime: "2026-10-04T00:00:00Z")
for try await receipt in client.crsReportPages(matching: query) {
  persist(receipt.body, headers: receipt.headers)
  for report in receipt.value.reports { print(report.id, report.title) }
}
for try await report in client.crsReports(matching: query) {
  print(report.id)
}
```

Requests are also available through `CongressRequest.crsReports(matching:)` and
`Endpoint.crsReports(matching:)`. Value execution retrieves one page; built-in page and item
sequences follow strictly validated source links. Each traversal is independent and lazy,
checks cancellation, and preserves source order and duplicates. A failure ends that iterator.
Breaking early does not establish a complete inventory.

The query accepts page size, initial offset and optional source date bounds. It has no sort
control. Source timestamps remain strings; the client does not re-filter results or correct
time zones. A recorded narrow window returned an update timestamp outside its requested bounds.
The separate recorded daily inventory forms a complete 5/4 chain against count 9, but neither
sample guarantees stable snapshots, search coverage, or date-window semantics beyond the source.

## Interpret metadata

List `version` and detail `currentVersion` are separate source fields. One recorded IF10199
list has version 41 while its detail has currentVersion 49. No historical version availability
is inferred. Publication and update dates remain independent, and status/content categories
remain open strings.

Authors, topics, format links and related materials preserve source order and raw fields.
Related numbers may be string law citations or numeric bill numbers; null titles and duplicate
references survive. Source overlap does not provide independent corroboration or identity joins.
