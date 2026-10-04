# Committee Senate communication records

Decode communication references while preserving open type codes and separate source dates.

## Envelope and fields

``CommitteeSenateCommunicationPage`` decodes the top-level `senateCommunications` array,
`pagination`, and optional `request` metadata. Its collection items are those same ordered
references.

``CommitteeSenateCommunication`` requires integer `congress` and `number` plus an object
`communicationType`. ``CommitteeSenateCommunicationType`` requires its source `code` string and
retains an optional `name`. Codes are open strings; EC, PM and POM are recorded examples, not a
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
Senate ``CommitteeIdentifier`` values only. Both factories throw typed
``CongressInputError/unsupportedCommitteeResource`` for House or Joint identifiers.

```swift
let committee = try CommitteeIdentifier(chamber: .senate, code: "slet00")
let page = try CongressQuery(limit: 11)
let request = try CongressRequest.committeeSenateCommunications(for: committee, page: page)
let endpoint = try Endpoint.committeeSenateCommunications(for: committee, page: page)
```

The built-in collection uses unchanged ordinary strict continuation. The recorded 11/11/9 chain
ends at count 31 without an exception. No date-window, Congress or sort filter is advertised by
this factory. One-response decoding does not establish exhaustion, historical completeness or a
stable snapshot. Applications own durable receipts and any separately requested linked retrieval.
