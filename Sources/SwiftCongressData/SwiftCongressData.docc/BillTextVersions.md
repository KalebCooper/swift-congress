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
Congress 119 (`hr 1`), whose provider count is six. Three of its limit-2 pages are recorded: offset
0, offset 2 from the provider's `next` link, and offset 5 requested directly. They hold 3, 3, and 1
versions, five distinct by type. The page at offset 4 is not recorded. Nothing beyond these
recorded bills and pages is claimed, and no statement here generalizes to Congress.gov's
text-version coverage for other bills.

The two recorded Congress 119 pages with a `next` link each held three versions instead of two,
the third identical to the only version on the recorded page at offset 5. `BillTextVersionPage`
accepts at most one version beyond the limit; a page that carries the extra version advances the
offset by the requested limit, and any other page by its returned count. Versions are never
de-duplicated, so a traversal over pages shaped this way can yield the same version more than
once. This is stated only as the recorded behavior for these fixtures; whether it holds for every
text-version inventory is not asserted.

## Dates are unparsed

`BillTextVersion.date` is the source string exactly as published, at its own precision, and is
never parsed into a date value. A recorded version can publish it as null.
