# Standalone report records

Decode report inventories, every detail part, and nested text metadata without a transport.

```swift
let inventory = try JSONDecoder().decode(CommitteeReportPage.self, from: inventoryBytes)
let detail = try JSONDecoder().decode(CommitteeReportDetail.self, from: detailBytes)
let text = try JSONDecoder().decode(CommitteeReportTextPage.self, from: textBytes)
for part in detail.committeeReports {
  print(part.number, part.part as Any, part.title as Any)
}
```

``CommitteeReportPage`` reuses ``CommitteeReportReference`` because both standalone inventories
and committee-associated lists publish `reports` with compatible scalar types. Congress and report
number are integers; the optional report part is a separate integer. Type spelling, citations,
raw timestamps and unknown `cmte_rpt_id` values are retained without reconstruction.

``CommitteeReportDetail`` preserves the entire ordered `committeeReports` array in one response,
including distinct citations, committees, text resource links and dates for each
``CommitteeReportPart``. No part is selected implicitly. Required identity fields reject missing,
null or wrong scalar values; optional metadata remains nil while `rawFields` distinguishes
missing keys from explicit nulls and empty arrays.

The singular source key `associatedBill` contains an array of ``CommitteeReportBill`` records
with string numbers. ``CommitteeReportTreaty`` keeps integer numbers and optional string parts.
These arrays stay independent. ``CommitteeReference`` and ``ResourceLink`` preserve compatible
nested committee and text-link metadata. A published empty committee array remains empty.

``CommitteeReportTextPage`` decodes the `text` array into ``CommitteeReportTextVersion`` records.
Each record preserves its nested ``CommitteeReportTextFormat`` array and source ordering.
The format's `isErrata` is an open string; `type` and `url` are original optional strings.
Unknown format labels, errata values and raw links survive encoding. There is no URL-derived
part, guessed URL resolution, document retrieval, or bill-text pagination exception.

All records retain their original dictionaries. Encoding emits those dictionaries, preserving
unknown keys and source scalar types. Use SDK response receipts for exact original bytes; model
encoding is a semantic round trip, not a promise of identical whitespace or key order.

Sixteen attributed responses cover all five routes, a complete 96/96/94 inventory chain,
1/1/1/1 text chain, House/Senate/executive details, two report parts, bill/treaty references,
and explicit true/false conference details. The omitted/false/true inventory comparison is an
observation of those exact responses. Date-window encoding is documented but was not captured.
Only N errata and absolute text links were observed. Labeled mutations exercise Y/unknown errata,
relative links and treaty letter parts without claiming production coverage for those shapes.

## Topics

### Detail and references

- ``CommitteeReportBill``
- ``CommitteeReportDetail``
- ``CommitteeReportPart``
- ``CommitteeReportReference``
- ``CommitteeReportTreaty``

### Queries and requests

- ``CommitteeReportIdentifier``
- ``CommitteeReportInventoryQuery``
- ``CommitteeReportType``

### Text records

- ``CommitteeReportTextFormat``
- ``CommitteeReportTextPage``
- ``CommitteeReportTextVersion``
