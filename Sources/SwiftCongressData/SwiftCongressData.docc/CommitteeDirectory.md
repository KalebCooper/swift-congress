# Committee directories and profiles

Browse published committee inventories and inspect profiles without following their links.

## Directory scopes

```swift
let query = try CommitteeQuery(
  limit: 5, scope: .congressChamber(chamber: .joint, congress: 119))
for try await receipt in client.committeePages(matching: query) {
  persist(receipt.body, headers: receipt.headers)
  for committee in receipt.value.committees {
    print(committee.systemCode, committee.name ?? "(not supplied)")
  }
}
```

`CommitteeQuery` also supports all committees, a chamber, or a Congress. All four scopes
accept page bounds and unparsed source modification dates. There is no sort control.
A Congress scope describes the source inventory association; it does not establish a roster
or guarantee that every related historical record is included.

Store `CongressRequest.committees(matching:)` for reuse. Execute it with `value(for:)`
for the initial page, `pages(for:)` for exact receipts, or `items(for:)` for records.
`committeePages(matching:)` and `committees(matching:)` delegate to those operations.
`send(Endpoint.committees(matching:))` fetches exactly one response. Consumer-defined
endpoints and response models remain available.

## Profiles and relationships

```swift
let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
let profile = try await client.committee(identifier, congress: 118)
for entry in profile.committee.history ?? [] {
  print(entry.officialName ?? "(not supplied)", entry.startDate ?? "(not supplied)")
}
let request = try CongressRequest.committee(identifier, congress: 118)
let same = try await client.value(for: request)
```

Omit `congress` to retrieve the global profile. The scope is separate from committee
identity and can change resource counts and URLs. Nonpositive Congress input throws
`CongressDataError.invalidInput` before HTTP; endpoint and request factories throw
`CongressInputError.invalidQuery`.

Profiles preserve the provider's `isCurrent` flag, ordered history, explicit parent and
subcommittee references, and resource links. Captured profiles have no top-level name
or chamber. Neither the request nor a history entry is copied into an absent field.
Code spelling never determines parentage. Response chamber/type strings remain open.

Linked bills, reports, communications, nominations, websites and related profiles are
metadata only. Directory/profile retrieval does not fetch them or construct a roster.

## Continuation and coverage

Lazy traversals fetch on demand without prefetching, preserve source order and duplicates,
check cancellation even for buffered items, and remain independent. A failed iterator ends.
Counts and links must satisfy ordinary strict continuation before a page is yielded.

The recorded Congress 119 all-chamber response contains 236 records, count 238, and no
next link. Single-response APIs expose that response, but page/item traversal throws
`invalidContinuation` before yielding it. The library does not correct the count, count
nested references as additional rows, or invent a next link. A separate Joint Congress
119 capture completes a 5/4 chain against count 9. Neither sample proves a stable snapshot
or historical completeness.

Offline examples use `--committee-directory <path>` and `--committee <path>`.
The existing `--committees` mode continues to decode bill committee associations.
