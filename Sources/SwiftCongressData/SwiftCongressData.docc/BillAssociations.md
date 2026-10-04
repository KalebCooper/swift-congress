# Bill associations

Traverse source related bills, subjects, and committee associations without following their metadata links.

## Request and endpoint levels

```swift
let bill = try BillIdentifier(congress: 119, number: "5", type: .senateBill)
let page = try CongressQuery(limit: 2)
let request = CongressRequest.relatedBills(for: bill, page: page)
let first = try await client.value(for: request)
let same = try await client.send(Endpoint.relatedBills(for: bill, page: page))
for try await related in client.relatedBills(for: bill, page: page) {
  print(related.number, related.relationshipDetails ?? [])
  break
}
```

Each route accepts either `BillIdentifier` or `BillSourceIdentifier`. Early source keys
are not promoted to authoritative bill numbers. Related-bill numbers are source integers;
relationship descriptions and identifying authorities remain open strings. Repeated rows
and multiple assertions are preserved without inferring equivalent text or a symmetric graph.

## Pages and items

```swift
let query = try BillSubjectQuery(limit: 6)
for try await receipt in client.subjectPages(for: bill, matching: query) {
  print(receipt.value.policyArea?.name ?? "(not on this page)")
  for subject in receipt.value.items { print(subject.name) }
  persist(receipt.body, headers: receipt.headers)
}
for try await subject in client.subjects(for: bill, matching: query) {
  print(subject.name)
  break
}
for try await receipt in client.committeePages(for: bill, page: page) {
  for committee in receipt.value.items {
    print(committee.name ?? "", committee.activities ?? [])
  }
  break
}
```

`relatedBillPages`, `subjectPages`, and `committeePages` yield the exact bytes, headers,
status and decoded page. `relatedBills`, `subjects`, and `committees` yield source items.
Subject items contain legislative subjects only; the separate policy-area record is
available on pages. A policy-only page is visible during page traversal. Item traversal
skips it and requests the following page on the same item demand, without fabricating a row.

Construction and iterator creation perform no I/O. Each iterator is independent, only the
current page is buffered, and no page is prefetched. Early exit sends no further request.
Cancellation is checked before requests and while buffered. Invalid count, link, identity,
filter, limit or offset metadata throws `CongressDataError.invalidContinuation` before the
affected page is yielded. Transport failures retain status and quota headers and terminate
the iterator. Earlier results do not establish a complete inventory.

The subject source count includes a policy record when present, while its item sequence
excludes that record. Raw pagination remains unchanged; other collection contracts remain
strict. Counts can change between requests, so no stable snapshot is promised.

`value(for:)`, `send(_:)`, and consumer endpoint-backed requests retrieve one response
even when it contains a next link. Related URLs and subcommittee links are metadata only.
The caller owns joins, synchronization, identity resolution and further retrieval.
