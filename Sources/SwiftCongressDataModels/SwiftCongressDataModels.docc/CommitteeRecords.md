# Committee directory records

Decode inventories and profiles while retaining the provider's original fields.

## Envelopes and records

```swift
let page = try JSONDecoder().decode(CommitteePage.self, from: bytes)
for committee in page.committees {
  print(committee.systemCode, committee.chamber ?? "(not supplied)")
}
```

``CommitteePage`` reads the `committees` array, pagination and request metadata.
``CommitteeSummary`` requires the source system code and preserves optional names,
open chamber/type strings, update dates and explicit parent/subcommittee references.
The `items` view retains the original order and duplicates.

``CommitteeDetail`` reads the singular `committee` object as ``CommitteeProfile``.
Only `systemCode` is required on a profile. Captures omit a top-level name and chamber:
neither is synthesized from query inputs, code prefixes or ordered ``CommitteeHistory``
entries. The profile's type and `isCurrent` flag retain their source meanings. All history
dates and external identifiers remain strings, including historical timestamps with
non-hour offsets.

``CommitteeReference`` retains published names, system codes and URLs for explicit
relationships. ``ResourceLink`` retains optional counts and URLs for bills, reports,
nominations and communications. A Congress-scoped profile can publish different resource
counts and scoped links for the same system code. No link is fetched during decoding.

## Raw preservation and request safety

Every nested record and envelope retains `rawFields`. Encoding emits those original
fields, including unknown keys and explicit nulls. Missing optional arrays remain nil
rather than becoming empty arrays. Use SDK response receipts when exact original bytes
are required.

``CommitteeIdentifier`` accepts a safe nonempty ASCII code without prefix or length
assumptions and requires an explicit request-only ``CommitteeChamber``.
``CommitteeQuery`` supports all, chamber, Congress, and Congress/chamber scopes with
page bounds and source date filters. A detail's optional positive Congress scope is
separate from its identifier.

``CommitteePage`` uses ordinary strict ``CongressContinuation`` validation.
The recorded 236-record/count-238 terminal response decodes unchanged; traversal rejects
it before yielding. Nested relationships are not extra page records, and no count repair
or inferred continuation is performed.
