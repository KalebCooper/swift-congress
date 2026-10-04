# Member legislation records

Decode member inventories without fabricating bill identities.

## Envelopes and records

``SponsoredLegislationPage`` and ``CosponsoredLegislationPage`` retain their differently named
arrays, pagination, original request metadata, and every raw envelope field. Both expose
``MemberLegislation`` items in source order.

A record's Congress number is required. Bill number, title, type, introduction date, latest action,
policy area, amendment number, and URL are optional source values. Amendment records can publish
`amendmentNumber` while omitting bill fields and returning null `type` and `latestAction`.
The decoder preserves this distinction without parsing identifiers from links. Policy areas remain
JSON values, including objects with null names.

## Raw fidelity

Encoding emits `rawFields`, retaining unknown fields and omitted-versus-null distinctions.
Source dates and open type strings are not normalized. Wrong scalar types fail decoding instead
of becoming defaults. Use source-byte receipts from the SDK when exact formatting, bytes, and
headers are needed.

Construct requests with ``MemberIdentifier`` and ``CongressQuery``. These routes accept bounded
limit and offset controls; they do not inherit current-member or date filters from member browsing.
