# ``SwiftCongressHouseVotesModels``

Decode House XML and HTML without an HTTP dependency.

## Overview

House records are independent of Congress.gov, Bioguide, and Senate records. Historical
voter rows can omit `name-id`; a display name is never promoted to a member identity.
Row ordinals preserve duplicate names. The raw XML tree keeps unknown elements,
attributes, mixed text, and original position strings. Source receipts preserve exact bytes.

```swift
let identifier = try HouseVoteIdentifier(number: 314, year: 2026)
let endpoint = Endpoint.rollCall(identifier)
let request = HouseVoteRequest.rollCall(identifier)
```

Year and section indexes are HTML. They expose only published vote links and section
URLs, preserving order and duplicates. Retrieving a year does not retrieve its sections.
The caller controls traversal and completion accounting. The supported link forms are
the official `cgi-bin/vote.asp` roll references and `ROLL_*.asp` section links.

Quorum calls, procedural questions, Aye/No, Yea/Nay, Present, and Not Voting remain
source values. Dates and timezone attributes are not inferred. Totals are published
strings and retain empty values; the library does not recompute or replace them.

## Bounds and provenance

XML uses the system FoundationXML codec on Linux and Android and Foundation on Apple.
It rejects entity declarations, never resolves external entities, and bounds bytes,
depth, and element count. It supports source-declared character encodings. HTML is
bounded UTF-8 and retains its original text. Malformed input and inventories with no recognized entries fail explicitly.

Official source: [House Clerk XML information](https://xml.house.gov/).
Attributed recordings cover 1990 quorum and legislative rolls and a 2026 roll,
plus both historical and current inventory pages. Recording URLs, retrieval times,
HTTP status, media types, byte counts, and SHA-256 hashes accompany the fixtures.
Historical observations establish sample behavior, not a claim of complete coverage.

## Topics

- ``Endpoint``
- ``HouseCandidateTally``
- ``HouseDecodingError``
- ``HouseInputError``
- ``HouseLegislationReference``
- ``HouseMeasureReference``
- ``HouseMeasureType``
- ``HousePartyTally``
- ``HouseResponse``
- ``HouseRollCall``
- ``HouseTallyCount``
- ``HouseTallyGroup``
- ``HouseVoteIdentifier``
- ``HouseVoteIndex``
- ``HouseVotePosition``
- ``HouseVoter``
- ``HouseVoteReference``
- ``HouseVoteRequest``
- ``HouseVoteTallies``
- ``HouseXMLCodec``
- ``HouseXMLContent``
- ``HouseXMLNode``
- ``SourceHeader``
- ``SourceResponse``
