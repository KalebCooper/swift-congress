# Browsing members by geography

Use `MemberGeographyQuery` with the existing member APIs to browse a state or territory,
a district, or a district within a Congress.

```swift
let query = try MemberGeographyQuery(
  currentMember: true, scope: .state(limit: 2, stateCode: "AK"))
for try await receipt in client.memberPages(matching: query) {
  print(receipt.value.members.map(\.bioguideId))
  break
}
let request = CongressRequest.members(matching: query)
let first = try await client.value(for: request)
let same = try await client.send(Endpoint.members(matching: query))
```

Value and endpoint execution retrieve one response. Page and item sequences are lazy,
independent, preserve source order and duplicates, and never prefetch. The first demand
fetches the initial page; later demand follows validated provider links. Invalid origins,
routes, changed filters, counts, sizes, or offsets throw before yielding the affected page.
Cancellation is checked even while items remain buffered.

## Route-specific controls

| Scope | Source path | Optional controls |
| --- | --- | --- |
| `congressDistrict(congress:district:stateCode:)` | `/v3/member/congress/{congress}/{state}/{district}` | currentMember |
| `district(district:stateCode:)` | `/v3/member/{state}/{district}` | currentMember |
| `state(limit:stateCode:)` | `/v3/member/{state}` | currentMember, limit |

State codes are exactly two ASCII letters, normalized to uppercase. DC and territory codes
are permitted without a fixed allowlist. Congress must be positive and district nonnegative.
District zero is valid for at-large and delegate queries. State limits are 1 through 250;
nil omits the limit. No geographic query exposes initial offsets or modification windows.
Provider continuation links can add paging controls; an omitted limit validates against
the provider's default of 20. Existing `MemberQuery` inventory behavior is unchanged.

## Interpret the source records

The currentMember filter defaults to false, which includes current and former members
in the recorded results; nil omits the parameter. A Congress/district query does not
establish membership on a particular date. Redistricting can leave a returned record
with a different published district than the route. The historical Congress 118 TX 15
sample retains both district 34 and district 15 records. No local filtering removes either.

AK and DC district-zero records omit district. The models preserve that absence instead
of copying zero from the request. Terms remain source aggregates, and neither source
counts nor successful traversal promise complete history or a stable snapshot.

The offline `CongressDataDemo --members <absolute-path>` mode accepts
`members-ak-current-first.json`, `members-dc-district0-current.json`, and
`members118-tx15-historical.json` from the Data test-support fixture directory.
It reads one recorded page without contacting the service.
