# Geographic member requests and records

Describe geographic inventories with ``MemberGeographyQuery``, then construct an
``Endpoint`` or ``CongressRequest`` using the existing members factory.

```swift
let query = try MemberGeographyQuery(
  scope: .congressDistrict(congress: 118, district: 15, stateCode: "TX"))
let endpoint = Endpoint.members(matching: query)
let request = CongressRequest.members(matching: query)
```

The query validates and uppercases two ASCII letters, accepts positive Congress numbers
and nonnegative districts, and permits an optional 1...250 limit only for state inventories.
It has no initial offset or timestamp controls. The currentMember filter defaults to false;
nil omits it. Constructing any of these values performs no I/O.

All three geographic routes reuse ``MemberPage`` and ``MemberSummary``. The original
members, pagination, request metadata, unknown fields, and missing values survive encoding.
A missing district stays absent even when the request used district zero. Historical
district results can carry a member's later district; the route never rewrites the record.

``CongressContinuation`` validates provider links with ordinary strict page sizes and
count progression. An omitted state limit uses the existing default of 20 for validation;
no initial offset is emitted. Captured Alaska state pages form a complete 2/1 chain with
count 3. Two New York pages with omitted initial limit retain count 179 and next offsets
20/40; that captured prefix does not establish exhaustion or historical completeness.

For a custom executor, interpret collection resolution, send explicit credentials to the
Congress.gov origin, decode MemberPage, and validate continuation before exposing each page.
A request constructed directly from an endpoint describes one response only.
