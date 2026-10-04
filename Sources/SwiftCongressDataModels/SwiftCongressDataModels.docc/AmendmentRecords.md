# Amendment records

Decode sparse inventories and detailed amendments while retaining the complete source response.

```swift
let page = try JSONDecoder().decode(AmendmentPage.self, from: listBytes)
let detail = try JSONDecoder().decode(AmendmentDetail.self, from: detailBytes)
let amendment = detail.amendment
print(amendment.description as Any, amendment.purpose as Any)
```

``AmendmentSummary`` represents inventory, bill-list and amended-amendment references. Congress
is an integer; number and open type are strings. Description, purpose, latest action, update
date and URL can be absent. ``AmendmentPage`` retains ordered `amendments`, pagination and request
metadata. ``AmendmentDetail`` contains one ``Amendment`` under the singular `amendment` key.

``Amendment`` preserves each target independently: compatible ``Bill``, ``AmendmentSummary``
and ``AmendmentTreaty``. A bill and amendment target may coexist. Treaty identity keeps the
integer `treatyNumber` source field. Nested Bill fields not projected by that existing model,
such as `originChamberCode` and `updateDateIncludingText`, remain accessible in its `rawFields`.
No cross-service type or transport is required, and target links never trigger a lookup.

``AmendmentMember`` preserves sponsor identity and optional integer district. Members under
`onBehalfOfSponsor` retain their open `type` role separately from the sponsors array. Submission
and proposal timestamps remain independent raw strings. ``AmendmentNote`` retains ordered notes.
``AmendmentCosponsorResource`` keeps active/source and withdrawal-inclusive counts separately;
``ResourceLink`` models compatible action, child and text counts/URLs. Missing resources remain
unknown, not fabricated empty collections.

``AmendmentAction`` is amendment-specific and retains source date, time, text and ordered
``AmendmentActionLink`` values. Vote references remain raw, without inferring an outcome or
performing a chamber request. SUAMDT 97/3 keeps number 3 despite the recorded latest-action link
and text naming SP 2. No URL-derived identity replaces the provider's record.

Every model stores its original dictionary. Required identity fields reject missing, null or
incorrect scalar values; optional fields project omissions/nulls to nil while `rawFields`
distinguishes them. Encoding preserves semantic JSON, including unknown fields, array order and
duplicates. Exact original bytes require SDK response receipts, not re-encoding.

Twelve attributed captures cover all five directory/detail/bill-list routes, House, Senate and
Senate unprinted records, independent bill/amendment/treaty targets, notes and on-behalf roles,
sparse summaries and the complete 16/16/16 bill chain. Window serialization is documented but
has no live comparison capture. Labeled mutation tests exercise future values, duplicates,
nulls and malformed types without presenting them as additional official observations.

## Topics

### Records

- ``Amendment``
- ``AmendmentAction``
- ``AmendmentActionLink``
- ``AmendmentCosponsorResource``
- ``AmendmentDetail``
- ``AmendmentMember``
- ``AmendmentNote``
- ``AmendmentSummary``
- ``AmendmentTreaty``

### Requests and pages

- ``AmendmentIdentifier``
- ``AmendmentPage``
- ``AmendmentQuery``
- ``AmendmentType``
- ``BillAmendmentQuery``
