# Committee bill records

Decode the nested committee bill envelope without inventing bill details.

## Envelope and identity

```swift
let page = try JSONDecoder().decode(CommitteeBillPage.self, from: bytes)
print(page.count, page.url, page.pagination.count)
for bill in page.bills {
  print(bill.congress, bill.type.rawValue, bill.number)
}
```

``CommitteeBillPage`` reads the bills array, count and URL inside `committee-bills`.
Its pagination and request metadata come from the outer response. The two counts remain
separate even if they differ; no resource URL is rewritten or followed. The `items` view
retains all source relationships in order, including duplicate bill identities.

``CommitteeBill`` requires an integer Congress, string number and open ``BillType``.
Bill type case and number spelling remain unchanged. Relationship labels, action dates,
update dates and URLs are optional source strings. Missing and null optional fields
decode as nil while their original presence stays in `rawFields`. There is no title
projection or inference from committee chamber, resource links or relationship labels.

## Requests and raw preservation

``CommitteeBillQuery`` accepts page bounds and source date strings. It uses the validated
``CommitteeIdentifier`` for House, Senate or Joint request paths. Unsupported sort and
Congress filters are absent from this query. Date strings are encoded safely, including
literal plus signs, without parsing them or reconstructing history.

Every record and the complete envelope retain original JSON fields, including unknown
nested values and explicit nulls. Encoding emits that retained JSON. SDK receipts provide
exact original bytes when byte-level provenance matters.

``CommitteeBillPage`` uses ordinary strict ``CongressContinuation`` validation.
Neither a special overrun nor a different consumed-record count is applied.
The recorded finite-window chain contains 60/49 rows against pagination count 109.
