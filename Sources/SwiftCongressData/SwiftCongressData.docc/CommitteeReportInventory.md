# Standalone committee reports

Browse report inventories, retrieve every part in one detail response, and inspect text-format
metadata without downloading document assets.

## Inventory and detail

```swift
let query = try CommitteeReportInventoryQuery(limit: 96,
  scope: .type(congress: 117, type: .senateReport))
let stored = CongressRequest.committeeReports(matching: query)
let first = try await client.value(for: stored)
for try await receipt in client.committeeReportPages(matching: query) {
  print(receipt.value.reports.count)
  break
}
let report = try CommitteeReportIdentifier(congress: 109, number: "519", type: .houseReport)
let detail = try await client.committeeReport(report)
for part in detail.committeeReports {
  print(part.citation ?? "No citation", part.part as Any)
}
```

Inventory scopes are all reports, one Congress, and one Congress/report type. Request identifiers
accept positive Congresses and decimal numbers with safe open report codes. Known request types
are executive, House and Senate reports. No historical completeness is promised.

`CommitteeReportInventoryQuery` is separate from the committee-associated `CommitteeReportQuery`
used in <doc:CommitteeReports>. Inventory records reuse `CommitteeReportReference` without
changing its source number, part or type. A reference can supply Congress, stringified report
number and open type to `CommitteeReportIdentifier`; construction does not fetch the report.

A detail response uses the ordered `committeeReports` array. The recorded 109/hrpt/519 response
contains parts 1 and 2 with distinct committees and citations. The detail method returns both;
there is no invented part route or automatic resource traversal. Associated bills retain string
numbers, while treaty numbers are integers and optional treaty parts remain strings.

`conference: nil` omits the filter. True and false send explicit source values. The recorded
Congress 117 comparison returned matching first records/count 1013 for omitted and false,
and an empty/count-zero true response. This observation does not establish broader filter
semantics; the separate recorded 116/hrpt/333 detail explicitly has a true conference flag.
Date-window strings are encoded unchanged for source validation, without interpreting dates.

## Strict text metadata traversal

```swift
let page = try CongressQuery(limit: 1)
let stored = CongressRequest.textVersions(for: report, page: page)
let first = try await client.send(Endpoint.textVersions(for: report, page: page))
for try await version in client.committeeReportTextVersions(for: report, page: page) {
  for format in version.formats ?? [] {
    print(format.type ?? "No type", format.isErrata ?? "Unknown", format.url ?? "No link")
  }
}
```

`committeeReportTextPages` yields exact page receipts; `committeeReportTextVersions` yields
ordered records with nested formats. This route returns `text`, not `textVersions`. No date,
version label or structured report-part field is synthesized. Asset filenames never establish
part identity. `isErrata` is an open string, not a Boolean. Raw links remain unchanged, including
relative links if supplied; the SDK does not guess a base or fetch HTML/PDF assets.

Both inventories and text use ordinary strict continuation with no bill-text overrun allowance.
Sequences fetch only on demand, never prefetch, buffer only the current page, and keep iterators
independent. Cancellation is checked before requests and buffered items. Changed origin, route,
filters or page bounds, credential queries, duplicate parameters, missing links and nonprogressing
links fail before a page is yielded. A later failure preserves earlier receipts but does not
establish completeness. Counts may change between responses.

Everyday methods, contextual or stored requests, consumer-defined constrained factories and typed
endpoints share execution. `value(for:)`, `send(_:)` and a custom endpoint-backed request perform
one HTTP operation even when a next link exists. `response(for:)` retains exact bytes and headers.
No Congress.gov operation calls the independent House votes, Senate votes or Bioguide services.

The recorded inventory chain is 96/96/94 against count 286; the text chain is 1/1/1/1 against
count 4. All observed text errata values are N. Positive errata, relative asset links and treaty
letter parts are covered only by labeled policy mutations, not production claims.

## Offline examples

The existing CongressDataDemo accepts `--committee-reports`, `--committee-report` and
`--committee-report-text` with an absolute recorded-fixture path. Inventory output preserves
report references; detail output prints every part and separate bill/treaty references; text
output prints each nested format and original errata/link values. No credentials are needed.
