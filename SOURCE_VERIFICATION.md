# Source verification

Verified September 24 through 27, 2026 UTC. Samples prove their own payloads, not corpus
completeness. Fixture manifests retain exact sanitized request URLs and response provenance.

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

An earlier keyed attempt returned HTTP 429 with Retry-After 81242 seconds; no substitute
credentials or synthetic official fixtures were used at that time. Member and text-version
recording later resumed under an owner-authorized key location (`~/.config/congress/api_key`,
sent only as `X-Api-Key`, read only by the recording script under `plans/`, never printed or
logged), with each request bound and counted in advance.

Member fixtures: `/v3/member/H000324?format=json` (deceased member; `deathYear` decodes as the JSON
string `"2021"`, `birthYear` as `"1936"`), the unscoped list's first page
(`/v3/member?currentMember=false&format=json&limit=2&offset=0`, count 2696), and that page's
provider `pagination.next` verbatim (`/v3/member?currentMember=false&offset=2&limit=2&format=json`).
The provider next link keeps `currentMember=false` and uses the same path and parameter order the
constructed endpoint builds, so the default unscoped traversal is evidenced end to end.

Text-version fixtures for Congress 119 `hr 1` cover offsets 0 and 2 (linked, 3 versions each,
count 6) and offset 4 (the provider's `pagination.next` from offset 2, 2 versions, no `next`,
recorded under an explicit owner authorization for that one request), plus a constructed terminal
offset 5 (1 version). The linked traversal 0, 2, 4 yields 8 items across 6 distinct version types;
"Public Law" appears 3 times and is byte-identical each time. The offset-4 page is consistent with
the text-page overrun rule (a page may carry one record beyond the requested limit; end
`4 + 2 = 6 >= count 6`, so the page is terminal). No other collection type is allowed this overrun.

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
H000205 retains Continental Congress 1 and Confederation Congress 1 as two positions with the same
Congress number and different body types.

The complete archive passed external extraction/CRC validation and the compiled Swift importer:
13,056 unique profiles, including ConfederationCongress, ContinentalCongress, and USCongress.
The importer checks all file hashes and exact source identities; this does not resolve the live
website count discrepancy or choose a refresh policy.

## Chambers

[House XML](https://xml.house.gov/) and [Senate XML](https://www.senate.gov/general/XML.htm) are
independent official sources. Current and historical requests needed no key. No numerical rate
allowance is asserted.

House 1990 roll 1 is a quorum call with 430 rows and no name IDs. Roll 10 retains historical
position vocabulary. Roll 2 of the 2025 session is the Speaker election, candidate-only tallies
with no legislation reference published. The 2026 roll 314 sample has modern identifiers. Year
indexes are HTML, with separate ROLL_nnn.asp inventory links. Never infer a complete inventory or
fill gaps by inventing roll numbers.

Senate samples are 101/1/1 (1989, nomination), 111/2 votes 289 (bill), 297 (amendment targeting a
treaty document), and 298 (treaty), 119/2/240 (2026, amendment), the 119/2 index, and current
identity data. Modern amendment nesting and empty count elements must survive decoding. LIS member
IDs differ from Bioguide IDs; today's crosswalk does not guarantee a historical identity match.

## Authority and reuse

Preserve attribution, record-level rights, source identifiers, and original receipts. Overlapping
official publications do not necessarily provide independent corroboration. Applications own
filtering, joins, snapshot acceptance, durable provenance, and refresh scheduling.

## House implementation validation

House XML and HTML fixtures include 1990 quorum/legislative votes, the 2025 Speaker election, and
2026 roll 314. No member identity is inferred for missing historical name-id attributes. Published
Aye/No and Yea/Nay strings, quorum counts, unknown XML, and original bytes survive.
Year indexes expose official CGI vote references and independent ROLL section links.
The codec explicitly rejects the entity-declaration marker before parsing because libxml can
silently skip declarations when entity resolution is disabled. Byte, depth, and element limits are
enforced. A roll call's typed tallies are the Clerk's published totals, read from the same document
and never recomputed from voter rows; a typed legislation reference is conservative label
recognition, not a Congress.gov crosswalk.

## Senate implementation validation

The independent Senate service reads the explicit session XML inventory, roll calls,
and dated current LIS identity export. The 1989 fixture is a nomination vote without
modify_date; the 2026 fixture is amendment cloture with nested target-document metadata.
Empty counts, nested question text, unknown fields, and original bytes survive decoding.
Only two historical voter LIS IDs occur in the recorded current crosswalk, and no
automatic identity join is performed. A roll call's typed subject identifies the bill, amendment,
nomination, or treaty document the vote concerned, read from the same document and never a
Congress.gov crosswalk.

## Final local checks and unavailable gates

The final deterministic suite has 169 tests in 16 suites, passing with both the Linux default and
HTTPPortable trait graphs. It includes cancellation during streamed chamber body reads, custom
consumer response decoding, and lazy member and text-version traversal. House HTML parsing ignores
comments, script/style text, and angle brackets inside quoted attributes; unrecognized empty
inventories fail instead of claiming completion. `bash Scripts/verify.sh` passes 23 checks and
`bash Scripts/verify.sh --self-test` passes 55 planted-arm checks.

The Apple `swift-congress-Package` test plan passes in full, 323 of 323, on iPhone 18 Pro (iOS
27.0 simulator), with 0 source build warnings. All four demos (CongressBioguideDemo,
CongressDataDemo, CongressHouseVotesDemo, CongressSenateVotesDemo) build for the same destination
and each ran at least once offline through `xcrun simctl spawn` against a recorded or supplied
fixture, matching that fixture's known output. All eight product DocC catalogs plus the merged
archive build with zero warnings, from Apple build products.

This is the Q2 through Q4 qualification pass, 2026-09-27 09:03..09:08 CT, at `b5a94f7`. Not run
here: Android emulator execution (no local Android Swift SDK or `adb`) and hosted CI. No API limit
was bypassed and no shared service was reset while gathering this evidence.
