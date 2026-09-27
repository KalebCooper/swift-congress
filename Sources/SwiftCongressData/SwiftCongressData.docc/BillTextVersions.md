# Browsing bill text versions

Read a bill's published text versions and their format links through the same typed requests
and lazy traversal used for bill and member inventories.

## Browse the text-version inventories

``CongressDataClient/textVersionPages(for:page:)-(BillIdentifier,_)`` yields page receipts and
``CongressDataClient/textVersions(for:page:)-(BillIdentifier,_)`` yields version records, for both
`BillSourceIdentifier` and `BillIdentifier`. Each loop below reads a bounded prefix; without the
`break`, a loop fetches every page of the inventory, one request per page.

```swift
let identifier = try BillIdentifier(congress: 119, number: "1", type: .houseBill)
for try await receipt in client.textVersionPages(for: identifier) {
  print(receipt.value.pagination.count)
  break
}
var remaining = 5
for try await version in client.textVersions(for: identifier) {
  print(version.type ?? "unnamed", version.date ?? "undated")
  remaining -= 1
  if remaining == 0 { break }
}
```

## Format links are supplied metadata

`BillTextFormat.url` is the source's published link string, never a fetched byte stream; this
library sends no request to it. The format `type` string, such as `PDF` or `Formatted Text`, is
the provider's own label, not a MIME type, and neither it nor the link's file extension may be
used to infer one. `parsedURL` is a convenience parse of `url` for a consumer that wants a `URL`
value; it performs no I/O and is nil whenever `url` is absent or cannot be parsed as an absolute
link with a scheme and host.

## Coverage is only what is recorded

Fixtures cover text versions for three bills: the historical House bill at Congress 6 (`hr 1`,
one version), the Senate bill at Congress 82 (`s 677`, one version), and the modern House bill at
Congress 119 (`hr 1`, six versions across three pages). Nothing beyond these recorded bills and
pages is claimed, and no statement here generalizes to Congress.gov's text-version coverage for
other bills.

The recorded Congress 119 pages (limit 2) each carried one version beyond the requested limit: a
page with a `next` link held three versions instead of two, with the third identical to the
inventory's final, terminal version. `BillTextVersionPage` accepts this recorded overrun and
still advances the offset by the requested limit. Versions are never de-duplicated, so a full
traversal of a page shaped this way yields that repeated final version more than once. This is
stated only as the recorded behavior for these fixtures; whether it holds for every text-version
inventory is not asserted.

## Dates are unparsed

`BillTextVersion.date` is the source string exactly as published, at its own precision, and is
never parsed into a date value. A recorded version can publish it as null.
