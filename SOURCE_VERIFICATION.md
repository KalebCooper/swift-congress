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

Summary captures on September 29, 2026 cover all four summary routes: bill-specific versions and
unscoped, Congress, and Congress/bill-type publication feeds. Bill 119/hr/1 has a linked 0/2/4
chain with 2/2/1 summaries against count 5; 82/s/677 returns a successful empty page. Version
codes retain leading zeros and `text` is original HTML. Feed entries retain their nested bill,
chamber fields, and separate last-summary-update timestamp. No null scalar was observed; labeled
mutation tests exercise nullable and unknown values without claiming additional provider evidence.

The finite-window sorted unscoped feed first returned a next link with `sort=updateDate+asc`.
Following that exact link produced a next link with a literal space in the sort value. The latter
was not fetched; strict continuation rejects the changed filter before yielding the affected page.
The scoped 119/hr window is a one-row terminal response.

Four further official captures omit the optional sort on the same unscoped finite window,
from 2026-09-01T00:00:00Z through 2026-09-02T00:00:00Z. Following each actual provider link yields
offsets 0/2/4/6 with 2/2/2/1 entries, count 7 on every page, and no next link on the terminal page.
Their original bodies are retained as `summary-updates-window-unsorted-*.json`. Together with
the nine earlier responses, these thirteen captures establish the recorded feed chain without
changing the sorted-feed failure behavior. They do not establish historical completeness or a
stable snapshot. Exact bytes, hashes, request targets and retrieval instants are recorded in
the fixture manifest.

Member legislation captures on September 30, 2026 UTC cover sponsored and cosponsored routes
for C001136 and former member L000174. Ten unchanged official responses include complete
provider-linked C001136 chains: sponsored offsets 0/5/10 with 5/5/5 rows and count 15;
cosponsored offsets 0/80/160 with 80/80/79 rows and count 239. Both end without a next link.
The envelopes use `sponsoredLegislation` and `cosponsoredLegislation`; bill rows use `title`,
not a guessed `latestTitle`. Policy-area names can be null. Request metadata lowercases the
member ID even when the request path is uppercase; both representations are preserved.

L000174 samples contain amendments, not bills: Congress 114 `amendmentNumber` 5164 in the
cosponsored response and 5136 in the sponsored response. Their source URLs retain
`/v3/amendment/114/samdt/5164?format=json` and
`/v3/amendment/114/samdt/5136?format=json`. Both have null `type` and `latestAction`,
and omit bill `number`, `title`, and `policyArea`. The manifest's generic identifier summary
omits `amendmentNumber`; these coordinates supplement that summary using the original fixture
bytes. The model does not infer types or bill identities from those URLs. Single-row former-member
samples do not establish complete inventories. Fixture manifests retain the exact sanitized
requests, retrieval instants, status, media type, byte count, and SHA-256.

Bill cosponsor captures on September 30, 2026 retain five unchanged official responses. The
117/s/3580 chain follows actual next links at offsets 0/15/30, yielding 15/15/1 records, with
active `pagination.count` 30 and nested `countIncludingWithdrawnCosponsors` 31 on every page.
The second page reaches the active total and still links to offset 30. H000601 has sponsorship
date 2022-03-15 and withdrawal date 2022-03-21. Traversal therefore uses the inclusive count
for this built-in page only, without rewriting active totals or filtering withdrawn records.
119/hr/1 returns an empty array with both totals zero. The 119/hr/22 one-row sample publishes
integer district 2 for G000597; Senate rows omit district. No null row fields were observed.
Missing/null/unknown mutation tests do not establish further production shapes. Exact request
URLs, retrieval instants, status, media types, byte counts, IDs, and SHA-256 remain in the fixture
manifest. These samples do not imply votes, endorsements, current status, or corpus completeness.

Law captures on October 3, 2026 retain eight unchanged official responses. Combined and public
inventories for Congress 119 use `bills` envelopes. The private inventory for Congress 117 follows
actual links at offsets 0/1/2, with 1/1/1 bills, count 3, and no terminal next link. Law-number
lookup uses the `bill` envelope: public 119-1 returns 119/S/5, private 117-1 returns 117/HR/681,
and historical public 93-1 returns 93/HJRES/1. Each bill's `laws` array retains source citation
numbers and `Public Law` or `Private Law` strings, distinct from route tokens. No null law fields
were observed; labeled missing/null/unknown mutations establish decoder policy only. Public and
combined inventory samples do not establish complete inventories. Exact request URLs, retrieval
instants, status, media types, byte counts, and hashes remain in the fixture manifest.

Bill association captures on October 4, 2026 retain eleven unchanged official responses.
Related bills for 119/s/5 follow offsets 0/2 with 2/2 records and raw count 4, including a
repeated bill 149 and CRS/House relationship authorities. Bill numbers are JSON integers.
Committee associations for 117/hr/3076 follow offsets 0/2 with 2/1 records and count 3;
ordered activities and a Health subcommittee survive without inventing its absent chamber/type.

Subjects for 119/s/5 follow offsets 0/6: the first page contains five legislative subjects
plus one policy area, the terminal has six legislative subjects, and raw count is 12. Source
paging counts the policy record while item traversal exposes legislative subjects only. The
limit-one initial response contains only policy area, with next offset 1; that next response
contains one legislative subject and links to offset 2. Only those two limit-one pages were
captured; the separate limit-six chain establishes exhaustion. Historical 93/hjres/1 contains
four legislative subjects plus policy area (count 5), and 82/s/677 is empty (count 0). A finite
119/s/5 modification window from 2025-01-10T13:00:00Z through 14:00:00Z returns policy area
only, count 1, and no next link. This is a filtered result, not an unfiltered policy-only bill.
No null nested fields were observed; labeled mutations establish decoder policy only. Exact
URLs, timestamps, statuses, media types, byte counts, and hashes remain in the fixture manifest.
The samples do not establish symmetric relationships, committee membership, complete historical
vocabulary, or a stable snapshot. No metadata link is fetched by these association APIs.

Geographic member captures on October 4, 2026 retain nine unchanged official responses. The
[member contract](https://github.com/LibraryOfCongress/api.congress.gov/blob/main/Documentation/MemberEndpoint.md)
provides state, district, and Congress/district routes with differing query controls. Alaska's
current state inventory uses limit 2 and follows the exact next link to a terminal page: 2/1
records and count 3. The historical-filter state sample contains ten records, including current
members. Two New York pages omit the initial limit, return 20 records each against count 179,
and publish limit 20 with next offsets 20/40. Only that prefix was captured.

AK and DC district-zero samples omit each record's district key. Congress 118 TX district 15
with currentMember=false returns G000581 with district 34 and D000594 with district 15;
currentMember=true returns D000594 alone. These source fields are retained without filtering
or reconstructing an as-of membership timeline. No initial offsets or district limits were
sent. Exact URLs, retrieval instants, statuses, media types, bytes, and hashes remain in the
fixture manifest. No new continuation exception is required by these samples.

CRS captures on October 4, 2026 retain seven unchanged official responses. The
[CRS contract](https://github.com/LibraryOfCongress/api.congress.gov/blob/main/Documentation/CRSReportEndpoint.md)
advertises list paging and date windows, plus detail by report ID. Actual envelopes are
`CRSReports` and `CRSReport`. The daily window from October 3 at 00:00:00Z to October 4 at
00:00:00Z contains nine records; its exact linked limit-five chain yields 5/4 and terminates.
The unfiltered limit-two sample is a partial inventory. Recorded prefixes include R, RS, and IF.

R47175 and IF10199 details retain authors, topics, PDF/HTML format links, raw summaries, and
related materials. Related `URL` keys are uppercase; numbers include string law citations
and integer bill numbers, titles can be null, and R47175 repeats the same HRES reference.
Detail page URLs have no scheme and remain unchanged strings. IF10199 list `version` is 41
while detail `currentVersion` is 49; no version-history meaning is inferred.

Publication and update timestamps remain separate. A narrow window from October 3
16:08:51Z through 16:53:27Z returned R45546 with updateDate 12:22:58Z, outside those bounds.
The client preserves this response without a guessed time-zone correction or local filtering.
Unknown/missing-field mutations establish decoder policy only. Exact URLs, retrieval instants,
statuses, media types, byte counts and hashes remain in the fixture manifest. No report asset
was acquired and these samples do not establish completeness or stable snapshots.

Committee directory captures on October 4, 2026 retain eleven unchanged official responses.
The [committee contract](https://github.com/LibraryOfCongress/api.congress.gov/blob/main/Documentation/CommitteeEndpoint.md)
provides all, chamber, Congress, and Congress/chamber inventories with paging and modification
windows, plus global and Congress-scoped details. The envelopes are `committees` and `committee`.
The Joint Congress 119 limit-five chain follows its exact next link at offset 5 and terminates
with 5/4 records against count 9. The all-committee and limit-two Joint samples remain partial.

The Congress 119 all-chamber response contains 236 records against count 238 with no next link.
One-response decoding preserves it, while lazy traversal fails before yielding that page.
Neither nested subcommittees nor an inferred offset is used to conceal the discrepancy.

Global and Congress 118 House hspw00 profiles retain three ordered history entries and fifteen
subcommittee references; scoped bill, communication and report counts and links differ.
House hspw14 explicitly identifies hspw00 as its parent. Senate ssju00 includes nomination
links and a history timestamp of `1816-12-10T04:56:00Z`. Joint jcov00 publishes `isCurrent: false`,
an end date, and no website or resource objects. Captured profiles omit top-level name and
chamber. These remain absent rather than being supplied from request inputs or history.
Open type/chamber strings, source dates and external identifiers remain unchanged.

Resource and relationship links are metadata only: no linked asset, roster or subresource was
acquired. Eleven of twelve authorized requests were used, without retries or redactions.
Exact sanitized URLs, retrieval instants, status, media types, byte counts and SHA-256 remain in
the fixture manifest. Decoder-policy mutations are labeled tests, not additional source evidence.
These records do not establish historical completeness, stable snapshots or cross-service identity.

Committee bill captures on October 4, 2026 retain four unchanged official responses for
House hspw00. The actual `committee-bills` envelope is an object containing a bills array,
count and URL; pagination and request metadata are top-level fields. The unfiltered two-row
sample has count 15553 and remains partial. A window from 2015-12-07T16:53:38Z through
16:53:40Z returns count 109: its limit-one sample remains partial, while the exact provider-linked
limit-sixty chain yields 60/49 records at offsets 0/60 and ends without a next link.

Those 109 Congress 110 relationships include Referred To, Markup By, Reported By,
Discharged From and Bills of Interest - Exchange of Letters. Bill types include HCONRES,
HR, HRES and S; committee chamber does not constrain bill chamber. Numbers are strings,
titles are absent, and action dates remain separate from modification dates. All recorded
update dates fit the window. Unknown/null/missing fields and duplicate rows are exercised
by labeled decoder-policy mutations, not claimed as further provider observations.

The four requests used no retries or redactions. Exact URLs, retrieval instants, status,
media types, byte counts and hashes remain in the fixture manifest. The complete window
does not establish all-time completeness or a stable snapshot. Linked bill detail is not
fetched, and generic continuation validation is unchanged.

Committee report-reference captures on October 4, 2026 retain four unchanged official responses
for House hspw00. The top-level reports array contains integer Congress, report number and part
fields, plus string chamber, citation, type, modification date and URL. The unfiltered two-row
sample has count 931 and remains partial. The window from 2015-03-20T00:04:12Z through
00:06:53Z contains count 24; its limit-one sample remains partial, while the exact provider-linked
limit-twelve chain yields 12/12 rows at offsets 0/12 and terminates without a next link.

The complete chain includes citation `H. Rept. 109-519,Part 2`, number 519, part 2 and type
HRPT. Its report URL has no part component. Source timestamps retain their spaces and offsets,
including `2015-03-20 00:05:26+00:00`. No rows or parts are deduplicated by URL, and no detail
or asset is fetched. All captured references are House records; Senate and Joint support follows
the advertised route contract. Labeled sparse/null/unknown/duplicate mutations establish decoder
policy, not further source evidence. Strict generic continuation is unchanged.

These four requests used no retries or redactions. Exact sanitized URLs, retrieval instants,
statuses, media types, byte counts and hashes remain in the fixture manifest. Together with the
four committee bill requests, they use eight of the twenty authorized committee-subresource
requests. Exhausting this recorded window does not establish all-time coverage or a stable snapshot.

Committee nomination captures on October 4, 2026 retain four unchanged official responses for
Senate Indian Affairs slia00. The actual top-level nominations array contains integer Congress
and nomination numbers, string partNumber, citation, description, received/update dates and URL.
Nested latestAction contains actionDate/text; nominationType uses Boolean isCivilian/isMilitary.
The guide's inMilitary spelling is not a decoding alias. All captured flags are civilian true
and military false, without imposing that combination on other records.

The two-record discovery page remains partial against count 96. A separate exact provider-linked
limit-32 chain follows offsets 0/32/64 with 32/32/32 rows and no terminal next link. Parts include
92 instances of 00 and one each of 09, 10, 13 and 14. Leading zeroes remain unchanged. PN1983 in
Congress 118 has part 00 and a URL without a part suffix. Actions include confirmation, withdrawal
and return to the President. The captured Congresses span 97 through 119 with gaps; this does not
establish historical completeness or a stable snapshot. No linked detail or asset is fetched.

The four requests used no retries or redactions, bringing shared committee-subresource usage to
twelve of twenty. All 113 fixture hashes verify; the prior 109 captures are unchanged. Exact
sanitized URLs, retrieval instants, statuses, media types, bytes and hashes remain in the fixture
manifest. Sparse/null/unknown/duplicate mutations establish decoder policy only. Strict ordinary
continuation remains unchanged; unsupported House/Joint nomination requests fail before HTTP.

Committee House communication captures on October 4, 2026 retain four unchanged official responses
for House Ethics hsso00. The actual top-level houseCommunications array contains integer Congress
and communication numbers, chamber, referral/update dates, URL, and a communicationType object
with code/name strings. Dates, Congress and URL are on the outer record, despite guide indentation.
No alternative nesting is inferred. Open codes preserve twelve EC/Executive Communication records
and three PT/Petition records in the complete chain.

The two-record discovery page remains partial against count 15. A separate exact provider-linked
limit-5 chain follows offsets 0/5/10 with 5/5/5 rows and no terminal next link. Congresses 114 through
119 are represented. Referral and modification dates retain their separate meanings and original
strings. No standalone communication detail or asset is fetched. These responses do not establish
historical completeness or a stable snapshot.

The four requests used no retries or redactions, bringing shared committee-subresource usage to
sixteen of twenty. All 117 fixture hashes verify; the prior 113 captures are unchanged. Exact
sanitized URLs, retrieval instants, statuses, media types, bytes and hashes remain in the fixture
manifest. Missing/null/unknown/duplicate mutations establish decoder policy only. Strict ordinary
continuation remains unchanged; unsupported Senate/Joint House-communication requests fail before HTTP.

Committee Senate communication captures on October 4, 2026 retain four unchanged official responses
for Senate Ethics slet00. The actual top-level senateCommunications array contains integer Congress
and communication numbers, chamber, referral/update dates, URL, and a communicationType object
with code/name strings. Dates, Congress and URL are on the outer record, despite guide indentation.
No alternative nesting is inferred. Open codes preserve twenty-nine EC/Executive Communication
records, one PM/Presidential Message and one POM/Petition or Memorial in the complete chain.

The two-record discovery page remains partial against count 31. A separate exact provider-linked
limit-11 chain follows offsets 0/11/22 with 11/11/9 rows and no terminal next link. Records include
Congresses 96 and 119, with gaps. Referral and modification dates retain their separate meanings
and original strings, including a referral later than its update date. No date is normalized or
inferred. No standalone communication detail or asset is fetched. These responses do not establish
historical completeness or a stable snapshot.

The four requests used no retries or redactions, exhausting the twenty-request shared committee
subresource budget. Aggregate acquisition usage is 94 of 152. All 121 fixture hashes verify; prior
117 captures are unchanged. Exact sanitized URLs, retrieval instants, statuses, media types, bytes
and hashes remain in the fixture manifest. Missing/null/unknown/duplicate mutations establish
decoder policy only. Strict ordinary continuation remains unchanged; unsupported House/Joint
Senate-communication requests fail before HTTP.


### Amendment directory evidence

Twelve Congress.gov HTTP 200 captures on October 4, 2026 preserve exact bytes and provenance
for unscoped, Congress and Congress/type inventories, detail and bill-associated amendments.
The complete 117/hr/3076 chain follows returned offsets 0/16/32 with 16 records each, count 48,
and no terminal next link. Summaries can omit description, purpose and latest action. Congress
is an integer, amendment number is a string and type is an open source string.

House 117/hamdt/173 has a bill target and integer sponsor district. Senate 117/samdt/2564 has
both amendedBill and amendedAmendment; 116/samdt/946 separately confirms amendedTreaty with
integer treatyNumber. Historical 97/suamdt/3 retains its source identity even though its latest
action names SP 2 and links to senate-amendment/2. Senate 114/samdt/5129 publishes ordered notes
and separate submitted/proposed on-behalf member roles, with differing submission/proposal dates.
Senate 117/samdt/2137 preserves a 507-child resource count and raw vote links without traversal.
Cosponsor metadata retains its distinct countIncludingWithdrawnCosponsors integer.

The official Amendment guide, Bill guide and OpenAPI document the five routes and date-window
parameters; no live date-window comparison is claimed. The Library of Congress changelog names
SUAMDT Senate Unprinted Amendments, while documented coverage is limited to Congresses 97 and 98.
Positive Congress inputs beyond that coverage remain valid requests, without completeness claims.
Targets are independent and do not establish ancestry or a vote result. No child/action/cosponsor/
text subresource or asset was fetched in these twelve directory captures. Acquisition used twelve
of the fourteen-request ceiling, no retries or redactions; 149 fixture hashes/bytes verify and
all prior 137 remain unchanged. Two reserved attempts remain unused.


### Standalone committee report evidence

Sixteen Congress.gov captures on October 4, 2026 retain exact bytes and provenance for all five
standalone committee-report routes. Inventories use `reports` and reuse the compatible report
reference model, preserving integer number/part fields and unknown `cmte_rpt_id`. The complete
Congress 117 Senate chain follows exact links through offsets 0/96/192, yielding 96/96/94 against
count 286 with no terminal next link. The unscoped and Congress inventories were also captured.

The identical Congress 117 limit-two comparison returns matching records/count 1013 for omitted
and false conference filters, and empty/count zero for true. This is observed behavior only.
Date-window support is documented and tested for encoding, not verified by a captured window.
House 116/hrpt/333 detail separately publishes `isConferenceReport: true`; other recorded details
publish false. House 109/hrpt/519 contains two ordered parts with separate committees/citations.
Senate 117/srpt/1 and executive 117/erpt/5 preserve their own fields. Singular `associatedBill`
is an array with string bill numbers; `associatedTreaties` uses integer treaty numbers.

Text uses the `text` array with nested `formats`, not the initially hypothesized `textVersions`.
The first unexpected response was retained with its exact provenance before a narrow recorder
correction allowed follow-ups. The full 109/hrpt/519 chain follows offsets 0/1/2/3, one record
per page, count four, and terminal no-next. Format links cover part-one and part-two assets but
supply no structured part field; models do not infer parts from filenames or fetch assets.
All recorded `isErrata` values are the string N. Positive errata, relative asset URLs and treaty
letter parts were not observed; labeled mutations preserve these documented possibilities
without claiming additional source evidence or guessing a URL base. Strict report pagination
has no bill-text overrun allowance. The authorized sixteen-request ceiling was exhausted with
no retries or redactions; all 137 retained fixture hashes/byte counts verify, and earlier 121
entries remain unchanged.

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

This is a local qualification run, 2026-09-27, at `b5a94f7`. Not run here: Android emulator
execution (no local Android Swift SDK or `adb`) and hosted CI. No API limit was bypassed and no
shared service was reset while gathering this evidence.
