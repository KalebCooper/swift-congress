# Committee report records

Decode report references without collapsing source parts or inventing missing metadata.

## Envelope and identity

``CommitteeReportPage`` decodes the top-level `reports` array, `pagination`, and optional
`request` metadata. Its collection items are the same ordered references. There is no nested
resource count or URL in this envelope, unlike committee bill responses.

``CommitteeReportReference`` requires integer `congress` and `number` plus string `type`.
Its optional integer `part` stays separate from the report number and citation. Chamber and
type remain open strings, including their original capitalization. Citation, modification
date and URL are optional strings and remain unmodified. The recorded update date format
includes spaces and an offset, such as `2015-03-20 00:05:26+00:00`.

A reference with citation `H. Rept. 109-519,Part 2` publishes part 2 and a report-level URL
without a part component. No part, title or other identity field is inferred from that link.
Arrays preserve order and duplicates. Every model retains all source fields in `rawFields`;
encoding emits the original JSON object, including unknown keys and explicit nulls. Optional
typed fields expose both absent and null values as nil; raw fields retain the distinction.

## Requests and continuation

``CommitteeReportQuery`` accepts page bounds and optional modification-window strings. It
uses a ``CommitteeIdentifier`` for the House, Senate or Joint committee route. Limit must
be 1 through 250 and offset nonnegative. No sort or Congress filter is accepted. Timestamp
strings pass through without interpretation, and literal plus signs are percent encoded.

```swift
let committee = try CommitteeIdentifier(chamber: .house, code: "hspw00")
let query = try CommitteeReportQuery(limit: 12)
let request = CongressRequest.committeeReports(for: committee, matching: query)
let endpoint = Endpoint.committeeReports(for: committee, matching: query)
```

The request is a built-in collection using ordinary strict continuation validation. The
recorded window's exact 12/12 chain terminates at count 24 without a pagination exception.
One-response decoding does not establish that an inventory is exhausted. Applications own
durable receipt storage, source completeness decisions and any subsequent linked retrieval.
