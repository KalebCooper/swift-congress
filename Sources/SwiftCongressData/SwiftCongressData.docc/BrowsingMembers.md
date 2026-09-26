# Browsing members

Read Congress.gov's member inventories and single-member detail through the same typed
requests and lazy traversal used for bill inventories.

## Retrieve one member

```swift
let identifier = try MemberIdentifier(rawValue: "L000174")
let detail = try await client.member(identifier)
print(detail.member.directOrderName ?? detail.member.bioguideId)
```

## Browse the member inventories

```swift
let query = try MemberQuery(scope: .congress(117))
for try await receipt in client.memberPages(matching: query) {
  print(receipt.value.pagination.count)
}
for try await member in client.members(matching: try MemberQuery(scope: .congress(117))) {
  print(member.bioguideId)
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
record; the two publish different fields, and reading a query with
`currentMember == false` does not make its results historical, only unfiltered by
present status.

## Raw-only fields

`MemberProfile` keeps `partyHistory`, `leadership`, `previousNames`, and
`addressInformation` only in `rawFields`; no typed view exists for them. A consumer
that needs one of these reads the matching key from `rawFields` and decodes it itself.
