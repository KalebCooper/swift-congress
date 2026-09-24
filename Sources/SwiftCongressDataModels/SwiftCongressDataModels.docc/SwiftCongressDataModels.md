# ``SwiftCongressDataModels``

Portable Congress.gov records and immutable request descriptions.

## Overview

This product has no networking dependency. Execute an endpoint using your own
transport, send its encoded path to https://api.congress.gov with explicit
X-Api-Key and User-Agent headers, and decode its declared response using JSONDecoder.

```swift
let source = try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill)
let endpoint = Endpoint.bill(source)
let request = CongressRequest.bill(source)
```

Bill, Congress, action, and envelope models preserve every original JSON field in
rawFields. Encoding emits those original fields; typed accessors do not replace
unknown fields or turn missing/null dates into defaults. Raw JSON numeric values
use Foundation Decimal; use SDK receipts when exact source bytes are required.

BillSourceIdentifier names a Congress.gov record, whose early number can be a
surrogate. BillIdentifier is restricted to numbered-bill eras and never accepts
an early source surrogate. Neither type establishes historical completeness.
Congress/session numbers are source facts, separate from Bioguide's predecessor
body namespaces. No automatic cross-provider identity joins are performed.

CongressContinuation validates count/offset progress and requires the next link
to retain origin, path, page size, and filters. Missing continuation for an
incomplete page is an error. Counts can change; no stable snapshot is promised.

## Topics

### Records

- ``Bill``
- ``BillAction``
- ``BillDetail``
- ``Congress``
- ``CongressSession``
- ``JSONValue``
- ``ResourceLink``

### Requests

- ``BillIdentifier``
- ``BillQuery``
- ``BillSourceIdentifier``
- ``BillType``
- ``CongressInputError``
- ``CongressQuery``
- ``CongressRequest``
- ``Endpoint``

### Pages and receipts

- ``BillActionPage``
- ``BillPage``
- ``CongressCollection``
- ``CongressContinuation``
- ``CongressPage``
- ``CongressPaginationError``
- ``Pagination``
- ``SourceHeader``
- ``SourceResponse``
