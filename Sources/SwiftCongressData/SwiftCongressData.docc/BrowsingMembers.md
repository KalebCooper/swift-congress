# Browsing members

Read Congress.gov's member inventories and single-member detail through the same typed
requests and lazy traversal used for bill inventories.

## Retrieve one member

``CongressDataClient/member(_:)`` retrieves one detail record.

```swift
let identifier = try MemberIdentifier(rawValue: "L000174")
let detail = try await client.member(identifier)
print(detail.member.directOrderName ?? detail.member.bioguideId)
```

## Browse the member inventories

``CongressDataClient/memberPages(matching:)`` yields page receipts and
``CongressDataClient/members(matching:)`` yields list records. Each loop below reads
a bounded prefix; without the `break`, a loop fetches every page of the inventory,
one request per page.

```swift
let query = try MemberQuery(limit: 2, scope: .congress(117))
for try await receipt in client.memberPages(matching: query) {
  print(receipt.value.pagination.count)
  break
}
var remaining = 5
for try await member in client.members(matching: query) {
  print(member.bioguideId)
  remaining -= 1
  if remaining == 0 { break }
}
```

`MemberQuery.Scope` selects the unscoped `/v3/member` inventory or one Congress's
`/v3/member/congress/{n}` inventory. The API returns the members it publishes for a
scope; this library asserts nothing about whether that is a complete historical
membership, and item and page counts can change between requests.

## The currentMember filter is not history

`MemberQuery.currentMember` sends the provider's `currentMember` query parameter, which
filters membership at retrieval time; the initializer default is `false`. It says
nothing about a member's own service history. A member's historical service lives in
the typed `terms` array on a detail record, or the leaner `terms.item` array on a list
record; the two publish different fields. A query with `currentMember == false` does
not make its results historical, and in recorded listings it included currently
serving members.

## Raw-only fields

`MemberProfile` keeps `partyHistory`, `leadership`, `previousNames`, and
`addressInformation` only in `rawFields`; no typed view exists for them. A consumer
that needs one of these reads the matching key from `rawFields` and decodes it itself.
