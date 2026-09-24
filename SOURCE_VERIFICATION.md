# Source verification

Verified September 24, 2026 UTC. Samples prove their own payloads, not corpus completeness.
Fixture manifests retain exact sanitized request URLs and response provenance.

## Congress.gov

The [official API](https://github.com/LibraryOfCongress/api.congress.gov) requires an API.data.gov
key, documents 5,000 requests/hour for standard keys, and permits page sizes 1 through 250,
default 20. Explicit X-Api-Key header requests successfully returned JSON.

The [bill contract](https://github.com/LibraryOfCongress/api.congress.gov/blob/main/Documentation/BillEndpoint.md)
states that Congresses 6 through 14 predate authoritative bill numbering. Their source keys must
remain distinct from official numbered-bill identities. Older enacted-law and modern introduced-bill
coverage differ. No historical cutoff is imposed on source discovery.

Recorded responses: Congress discovery offsets 0, 2, and terminal 118; bill detail 6/hr/1,
82/s/677, and 119/hr/1; bill-list offsets 0 and 2 for Congress 6; actions for 119/hr/1.
Original bytes are unchanged. The earliest Congress has a null session number. The 82nd Congress
bill lacks sponsors. All fields, including unknown values and nulls, survive model encoding.

The demo key then returned HTTP 429. Further API requests stopped. Member and text-version
payload acquisition remains pending. Retaining a document link does not prove its target payload.

## Bioguide

The supplied all-profile archive came from [the official export UI](https://bioguide.congress.gov/search).
Reverification found 21,668,690 compressed bytes, 64,960,436 uncompressed bytes, 13,056 profile files,
and largest profile 132,748 bytes. SHA-256:
`71b6898bc068a046cc5dcbfc6d6486c2a22c9dfa9cffd6c4bf7810510006b27d`.
This archive differs from the capped search export. The earlier UI count of 13,038 does not
establish a supported filtering rule. No unattended refresh contract is claimed.

M000985 retains Continental Congress 2 separately from U.S. Congresses 1 through 3, a death-date
string of `1806`, and missing personal service dates. Affiliation dates are not personal service
dates. Portrait and asset rights remain source data, not package MIT licensing.

The complete archive passed external extraction/CRC validation and the compiled Swift importer:
13,056 unique profiles, including ConfederationCongress, ContinentalCongress, and USCongress.
The importer checks all file hashes and exact source identities; this does not resolve the live
website count discrepancy or choose a refresh policy.

## Chambers

[House XML](https://xml.house.gov/) and [Senate XML](https://www.senate.gov/general/XML.htm) are
independent official sources. Current and historical requests needed no key. No numerical rate
allowance is asserted.

House 1990 roll 1 is a quorum call with 430 rows and no name IDs. Roll 10 retains historical
position vocabulary. The 2026 roll 314 sample has modern identifiers. Year indexes are HTML,
with separate ROLL_nnn.asp inventory links. Never infer a complete inventory or fill gaps by
inventing roll numbers.

Senate samples are 101/1/1 (1989), 119/2/240 (2026), the 119/2 index, and current identity data.
Modern amendment nesting and empty count elements must survive decoding. LIS member IDs differ
from Bioguide IDs; today's crosswalk does not guarantee a historical identity match.

## Authority and reuse

Preserve attribution, record-level rights, source identifiers, and original receipts. Overlapping
official publications do not necessarily provide independent corroboration. Applications own
filtering, joins, snapshot acceptance, durable provenance, and refresh scheduling.

## House implementation validation

House XML and HTML fixtures include 1990 quorum/legislative votes and 2026 roll 314.
No member identity is inferred for missing historical name-id attributes. Published
Aye/No and Yea/Nay strings, quorum counts, unknown XML, and original bytes survive.
Year indexes expose official CGI vote references and independent ROLL section links.
Six House tests pass in both Linux configurations. The codec explicitly rejects the
entity-declaration marker before parsing because libxml can silently skip declarations
when entity resolution is disabled. Byte, depth, and element limits are enforced.
Six product DocC catalogs build with zero warnings on Linux. Apple/Android gates remain pending.

## Senate implementation validation

The independent Senate service reads the explicit session XML inventory, roll calls,
and dated current LIS identity export. The 1989 fixture is a nomination vote without
modify_date; the 2026 fixture is amendment cloture with nested target-document metadata.
Empty counts, nested question text, unknown fields, and original bytes survive decoding.
Only two historical voter LIS IDs occur in the recorded current crosswalk, and no
automatic identity join is performed. Seven Senate tests pass in both Linux configurations.
The full package has 38 tests across eight suites and eight zero-warning Linux DocC catalogs.
