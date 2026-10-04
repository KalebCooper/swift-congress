# Committee House communication records

Decode communication references while preserving open type codes and separate source dates.

## Envelope and fields

``CommitteeHouseCommunicationPage`` decodes the top-level `houseCommunications` array,
`pagination`, and optional `request` metadata. Its collection items are those same ordered
references.

``CommitteeHouseCommunication`` requires integer `congress` and `number` plus an object
`communicationType`. ``CommitteeHouseCommunicationType`` requires its source `code` string and
retains an optional `name`. Codes are open strings; EC and PT are recorded examples, not a
closed vocabulary. Number alone is not a cross-type identity.

Chamber, referral date, update date and URL are optional original strings on the outer record.
The actual wire shape places those fields outside `communicationType`, despite the guide's
indentation. No nested aliases or defaults are introduced. Referral and update dates remain
separate and unparsed. Missing/null policy is tested through labeled mutations, not claimed
as observed sparse provider responses.

Each model retains every original field in `rawFields`, including unknown keys and explicit nulls.
Encoding emits that original object. Optional typed values expose both absent and null fields as
nil, while raw fields preserve the distinction. Arrays retain source order and duplicates.

## Requests and continuation

``CongressQuery`` accepts a limit from 1 through 250 and a nonnegative offset. This route supports
House ``CommitteeIdentifier`` values only. Both factories throw typed
``CongressInputError/unsupportedCommitteeResource`` for Senate or Joint identifiers.

```swift
let committee = try CommitteeIdentifier(chamber: .house, code: "hsso00")
let page = try CongressQuery(limit: 5)
let request = try CongressRequest.committeeHouseCommunications(for: committee, page: page)
let endpoint = try Endpoint.committeeHouseCommunications(for: committee, page: page)
```

The built-in collection uses unchanged ordinary strict continuation. The recorded 5/5/5 chain
ends at count 15 without an exception. No date-window, Congress or sort filter is advertised by
this factory. One-response decoding does not establish exhaustion, historical completeness or a
stable snapshot. Applications own durable receipts and any separately requested linked retrieval.
