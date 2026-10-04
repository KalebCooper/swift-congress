# Committee bill relationships

Retrieve a committee's published bill associations while retaining relationship labels and dates.

## Requests and traversal

```swift
let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
let query = try CommitteeBillQuery(
  fromDateTime: "2015-12-07T16:53:38Z", limit: 60,
  toDateTime: "2015-12-07T16:53:40Z")
for try await receipt in client.committeeBillPages(for: identifier, matching: query) {
  persist(receipt.body, headers: receipt.headers)
  for bill in receipt.value.bills {
    print(bill.type.rawValue, bill.number, bill.relationshipType ?? "(not supplied)")
  }
}
```

The route accepts House, Senate and Joint committee identifiers. The query supports page
bounds and unparsed modification timestamps; it has no sort or Congress filter. Bill chamber
is independent of committee chamber: the recorded House committee includes a Senate bill.

Store `CongressRequest.committeeBills(for:matching:)` for reuse. `value(for:)` retrieves
one response; `pages(for:)` and `items(for:)` traverse the built-in collection lazily.
`committeeBillPages(for:matching:)` and `committeeBills(for:matching:)` delegate to those
operations. `send(Endpoint.committeeBills(for:matching:))` retrieves one response.
Consumer-defined endpoint requests remain single-response operations.

Each traversal is independent, preserves source order and duplicates, and fetches without
prefetching. Cancellation is checked before HTTP and while items remain buffered. Malformed
continuation fails before yielding the affected page and ends that iterator. Transport
errors retain status and quota headers. Counts may change; no stable snapshot is promised.

## Source meaning and coverage

A relationship record retains its source Congress, string bill number, open bill type,
relationship label, action date, update date and URL. It has no inferred title and does not
retrieve linked bill detail. Action and modification dates have different meanings and stay
verbatim. Relationships include referrals, markup, reporting and other provider labels;
they do not imply passage, endorsement or membership.

The nested `committee-bills` object has its own count and URL, separate from top-level
pagination and request metadata. The recorded finite window completes an exact 60/49 chain
against count 109 with ordinary strict continuation. Smaller samples remain partial.
Those captures do not establish all-time or historical completeness.

The offline demo accepts `--committee-bills <path>`, printing nested metadata and each
published relationship. Directory/profile and bill-association demo modes are separate.
