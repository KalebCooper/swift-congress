# Reading vote subjects

Read what a roll call concerned directly from the same document, with no separate request
and no join to another service.

## Read the associated item

```swift
let vote = try await client.rollCall(congress: 111, number: 298, session: 2)
switch vote.subject {
case .amendment(let amendment)?: print(amendment.number)
case .bill(let bill)?: print(bill.measureType.rawValue, bill.number ?? "")
case .nomination(let nomination)?: print("PN", nomination.number ?? "")
case .treaty(let treaty)?: print("Treaty Doc.", treaty.number ?? "")
case .unknown(let unknown)?: print(unknown.reason)
case nil: print("no subject metadata published")
}
```

`subject` identifies the item the Senate associated with the vote; it never states an outcome.
Whether the roll call invoked cloture, confirmed, ratified, agreed, or rejected stays on the raw
`question` and `result`, independently of which subject case is read. A ratification vote and a
confirmation vote can both carry a `.treaty` or a `.nomination` subject; the case names the item,
the question names what happened to it.

## Classification order

A nonempty `amendment_number` selects `amendment(_:)` before anything else is examined; a merely
present or published-empty amendment element, as the recorded nomination, bill, and treaty files
do, does not. Otherwise the roll call's `document_type` decides: `PN` selects
`nomination(_:)`, `Treaty Doc.` selects `treaty(_:)`, and one of the eight bill and resolution
codes selects `bill(_:)`. Any other nonempty substantive metadata, on either element, is
`unknown(_:)` with a reason naming the exact shape that prevented recognition. When neither
element publishes a substantive field, `subject` is nil.

## Empty versus missing, and what is not inferred

A property is nil when its source element is absent and the empty string when the element is
published empty, so a caller can tell an omission from a published blank apart; a document's
`congress` alone and the boilerplate `amendment_purpose` text are never treated as substantive on
their own. Reading `subject` infers nothing beyond what is published: no amendment number is read
from the vote title, no document Congress is derived from the roll call's own coordinates, and no
Congress.gov URL or record is built from a nomination, treaty, or bill label. A subject this module
cannot recognize keeps its original `document` and `amendment` elements on `unknown(_:)` rather
than being guessed into one of the four typed cases, and a caller that wants a Congress.gov record
still has to resolve one itself from the recognized fields.

Historical LIS voter identities are a separate, dated inventory: matching one against a roll call's
recorded votes is independent of `subject`, and most historical identities remain unresolved.
