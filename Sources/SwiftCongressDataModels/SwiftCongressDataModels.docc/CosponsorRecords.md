# Decode bill cosponsor records

Preserve source identity, dates, withdrawal information, and the original envelope.

```swift
let page = try JSONDecoder().decode(BillCosponsorPage.self, from: sourceBytes)
print(page.pagination.count)
print(page.countIncludingWithdrawnCosponsors as Any)
for row in page.cosponsors {
  print(row.bioguideId, row.sponsorshipDate as Any, row.sponsorshipWithdrawnDate as Any)
}
```

``BillCosponsor`` requires the source member identifier. Other typed fields retain missing/null
values as nil: source names, party, state, district, original-cosponsor flag, sponsorship and
withdrawal dates, and URL. Dates and codes remain open strings. A missing Senate district is not
converted to zero; the recorded House district is an integer. No names or identifiers are inferred.
Every record and envelope preserves unknown fields and explicit nulls in `rawFields`; encoding
emits those retained values. Use SDK receipts when exact original bytes are required.

``BillCosponsorPage/countIncludingWithdrawnCosponsors`` reads the nested pagination field,
while ``Pagination/count`` remains the source active total. The built-in page uses the inclusive
total for continuation when present, falling back only for missing/null. Invalid totals fail
continuation before a page is yielded. This rule is internal to this page type, with no change
to consumer-defined collections or the separate text-page overrun rule.

The [official bill endpoint guide](https://github.com/LibraryOfCongress/api.congress.gov/blob/main/Documentation/BillEndpoint.md)
and unchanged September 30, 2026 fixtures establish the 117/s/3580 chain: 31 returned rows,
active count 30, inclusive count 31, and one published withdrawal. Row presence does not establish
a vote, endorsement of every provision, or current status. Counts can change between requests.

## Topics

- ``BillCosponsor``
- ``BillCosponsorPage``
- ``BillCosponsorQuery``
