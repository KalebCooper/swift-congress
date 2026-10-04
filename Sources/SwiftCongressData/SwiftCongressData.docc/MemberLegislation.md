# Member legislation

Browse a member's sponsored and cosponsored legislative records in provider order.

## Traverse records or retain receipts

```swift
let member = try MemberIdentifier(rawValue: "C001136")
let page = try CongressQuery(limit: 100)
for try await record in client.sponsoredLegislation(for: member, page: page) {
  print(record.title ?? "(no source title)")
}
for try await receipt in client.cosponsoredLegislationPages(for: member, page: page) {
  persist(receipt.body, headers: receipt.headers)
}
```

These APIs construct lazy, independent traversals. Only demand sends requests; iteration buffers
one page and never prefetches. Cancellation is checked while buffered. Invalid continuation fails
before its page is yielded, and later HTTP failures retain typed status and quota headers.
Following the last link does not promise a stable snapshot or historical completeness.

## Describe or execute one operation

```swift
let request = CongressRequest.sponsoredLegislation(for: member, page: page)
let first = try await client.value(for: request)
let same = try await client.send(Endpoint.sponsoredLegislation(for: member, page: page))
```

Built-in requests support `pages(for:)` and `items(for:)`. A consumer-created
`CongressRequest(endpoint:)` executes a single response even when that response includes a next
link. Endpoints remain usable with a caller's own executor and response type.

## Preserve bill and amendment distinctions

The two envelopes share a MemberLegislation record. Bill rows expose their source number, title,
open type, introduction date, latest action, and raw policy area. Former-member responses can
instead contain `amendmentNumber`, null type/latest action, and no bill number or title.
No bill identifier or amendment type is inferred from the URL. Unknown fields, explicit nulls,
source spelling, duplicate rows, and original order survive decoding and encoding.

Presence in a member's inventory does not establish a vote, endorsement of every provision,
or current cosponsorship status.

Ten official captures include complete three-page sponsored and cosponsored chains for C001136
and sparse amendment records for L000174. They prove those responses, not all member history.
Use the offline demo's `--sponsored-legislation` and `--cosponsored-legislation` file modes.
