# Committee nomination records

Decode nomination references without converting source parts to numbers or inferring missing metadata.

## Envelope and fields

``CommitteeNominationPage`` decodes the top-level `nominations` array, `pagination`, and optional
`request` metadata. Its collection items are those same ordered references.

``CommitteeNomination`` requires integer `congress` and `number` plus string `partNumber`.
Parts `00` and `09` retain their leading zeroes. Citation, description, received date, update
date and URL are optional original strings. The captured PN1983 reference has part `00` and
URL `/nomination/118/1983?format=json`; no identity component is derived from that link.

``CommitteeNominationAction`` exposes optional source `actionDate` and `text` without classifying
status. ``CommitteeNominationType`` exposes optional Boolean `isCivilian` and `isMilitary`.
The actual wire key is `isMilitary`; the guide's `inMilitary` spelling is not a decoder alias.
The nested objects themselves are optional. Missing/null policy is tested through labeled
mutations, not claimed as observed sparse provider responses.

Each model retains every original field in `rawFields`, including unknown keys and explicit nulls.
Encoding emits that original object. Optional typed values expose both absent and null fields as
nil, while raw fields preserve the distinction. Arrays retain source order and duplicates.

## Requests and continuation

``CongressQuery`` accepts a limit from 1 through 250 and a nonnegative offset. This route supports
Senate ``CommitteeIdentifier`` values only. Both factories throw typed
``CongressInputError/unsupportedCommitteeResource`` for House or Joint identifiers.

```swift
let committee = try CommitteeIdentifier(chamber: .senate, code: "slia00")
let page = try CongressQuery(limit: 32)
let request = try CongressRequest.committeeNominations(for: committee, page: page)
let endpoint = try Endpoint.committeeNominations(for: committee, page: page)
```

The built-in collection uses unchanged ordinary strict continuation. The captured 32/32/32 chain
ends at count 96 without an exception. No date-window, Congress or sort filter is advertised by
this factory. One-response decoding does not establish exhaustion, historical completeness or a
stable snapshot. Applications own durable receipts and any separately requested linked retrieval.
