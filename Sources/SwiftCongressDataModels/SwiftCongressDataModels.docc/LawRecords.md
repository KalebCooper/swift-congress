# Law routes and source citations

Keep lookup coordinates separate from the bill returned by Congress.gov.

## Request identity

```swift
let identifier = try LawIdentifier(congress: 119, number: "1", type: .public)
let detail = Endpoint.law(identifier)
let inventory = Endpoint.laws(
  matching: try LawQuery(congress: 117, limit: 1, type: .private))
```

``LawIdentifier`` validates a positive Congress and positive ASCII decimal law number.
It retains decimal spelling without converting it to a bill identifier or imposing a
historical cutoff. ``LawType`` exposes only the documented `pub` and `priv` route tokens.
``LawQuery`` selects one Congress and optionally one category, with page bounds only.

## Existing bill envelopes

All three law route shapes use existing envelopes: inventories decode as ``BillPage``,
and number lookup decodes as ``BillDetail``. The recorded public law 119-1 resolves to
119/S/5; private law 117-1 resolves to 117/HR/681; historical public law 93-1 resolves to
93/HJRES/1. The bill's number remains its own source number.

``Bill/laws`` is an optional ordered array of ``BillLawReference`` values. Each citation
retains the source number, such as `119-1`, and the open label, such as `Public Law`.
These strings are never split into a new identity, translated into route codes, or used
to fabricate a URL. Unknown keys and explicit nulls survive encoding through raw fields.
Missing/null arrays remain nil; missing/null citation scalars remain nil. Array order and
duplicates remain unchanged.

No null law fields were observed in the eight captures. Explicitly labeled mutation tests
exercise missing, null, and unknown values; they are not extra provider evidence. Recorded
fixtures establish only their own payloads and do not imply corpus completeness.

## Continuation

The private inventory's original links yield offsets 0, 1, and 2, with one bill per page
and count 3, terminating without a next link. These pages use ordinary strict
``CongressContinuation`` checks. Laws have no page-overrun or alternate-count exception.
A reusable built-in law inventory request describes a collection, while detail and
consumer endpoint requests describe one response. No network dependency is added to models.
