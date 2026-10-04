# Implementation readiness

Swift Congress implements Congress.gov discovery, bill detail, bill lists, action lists, bill
summaries and summary publication feeds; member browsing and detail; bill text versions; Bioguide
supplied-file import and historical-service queries; independent House votes; and independent
Senate votes. Source coverage does not establish historical completeness.

## Amendment directory coverage

Amendment inventories, detail and bill-associated lists have source, tests, DocC and Data demo
implementation present for validation. Twelve official
HTTP 200 captures cover all five routes, a complete 16/16/16 bill chain, House/Senate/SUAMDT,
independent bill/amendment/treaty targets, notes and on-behalf roles. All 149 fixture hashes and
byte counts verify; prior 137 remain unchanged. Acquisition used twelve of fourteen requests
for this family and 122 of 152 overall, without retries or redactions. Date-window serialization
has no live comparison capture. No Phase 11 subresource or text asset retrieval is included.

Independent review has identified a later-page quota-failure test gap for amendment inventories;
the correction also exercises that collection alongside bill-associated amendments. Review closure,
required source checks, Apple execution, Linux graphs, DocC compilation and all 110 offline demo
comparisons remain pending. This entry does not accept source or platform qualification. Android
remains unavailable locally; hosted CI and Pages publication have not run for these additions,
and release is not authorized. Earlier accepted coverage and receipts remain unchanged.

## Bill association coverage

Related bills, legislative subjects with separate policy area, and committee associations now
have raw-preserving models, typed requests/endpoints, lazy page/item conveniences, tests, DocC,
and offline demo modes. Eleven official captures include complete related, committee, and subject
chains, historical and sparse subjects, and policy-only initial and filtered terminal pages.
Subject continuation counts the separate policy record without changing raw pagination or
fabricating an item. Other collection contracts and independent service boundaries are unchanged.
On October 4, 2026, the 23-check source gate passed. Independent review is complete, with its
declaration-order finding corrected. The initial 28 focused Apple cases passed; after the
ordering correction, the selected 15-case rerun and final full 489-case suite passed on iPhone
17, iOS 27, with zero failed, skipped, or unrun cases. Three linker sysroot warnings remain
disclosed. Linux passed 239 tests in 26 suites in each dependency graph (HTTPPortable and
default), with exit 0. All eight DocC catalogs plus merged output built with zero diagnostics.
All four demo executables passed 35 offline invocations on iPhone 17, iOS 27, matching fixture
output exactly, including all eleven association captures. Source and designated local checks
are accepted with these platform limits. Android, hosted CI, Pages publication, and release
qualification remain separate outstanding gates.

## Committee bill coverage

Committee bill relationships now have raw-preserving records and nested page metadata,
typed requests/endpoints, page/window queries, lazy page/item conveniences, focused tests,
DocC and an offline demo. Four official captures include an exact 60/49 chain against count
109, open relationship labels and a Senate bill associated with a House committee. Nested
resource count/url remain separate from pagination; no title or bill detail is synthesized.
Acquisition used four of the twenty authorized requests shared by committee subresources.
On October 4, 2026, the source gate passed all 23 checks. The Xcode MCP rebuild succeeded
in 8.858 seconds with three known linker sysroot warnings. All 16 focused and 590 full-suite
cases passed on iPhone 17, iOS 27, with zero failures, skips or unrun cases. Fresh independent
review found no issues. Linux passed 289 tests in 34 suites in each dependency graph, with
execution times of 4.582 seconds for HTTPPortable and 4.976 seconds for default. All eight
DocC catalogs plus merged output and the site built with zero diagnostics. All four demo
executables passed 66 offline invocations, matching fixture output exactly. Source and
designated local checks are accepted with these platform limits. Android execution remains
unavailable; hosted CI, Pages publication and release qualification remain separate
outstanding gates.

## Committee directory coverage

Four committee inventory scopes and global/Congress-scoped detail now have raw-preserving
models, typed requests/endpoints, lazy traversal, tests, DocC, and offline demo modes.
Eleven official captures retain ordered history, explicit relationships, inactive and sparse
profiles, and scope-dependent resource counts/URLs. Profile names and chambers are not
synthesized. The complete Joint Congress 119 chain yields 5/4 records against count 9.
The separate 236-record/count-238 terminal response remains usable for one-response decoding
and fails strict traversal before yielding. No generic continuation rule changed.

Acquisition used eleven of twelve authorized requests. On October 4, 2026, the source gate
passed all 23 checks and the Xcode MCP build succeeded in 12.5 seconds with three known linker
sysroot warnings. All 25 focused and 574 full-suite cases passed on iPhone 17, iOS 27, with
no failed, skipped or unrun cases. Fresh independent review found no issues. Linux passed
278 tests in 32 suites in each dependency graph, with execution times of 3.111 seconds for
HTTPPortable and 2.742 seconds for default. All eight DocC catalogs plus merged output and
the site built with zero diagnostics. All four demo executables passed 62 offline invocations,
matching fixture output exactly. Source and designated local checks are accepted with these
platform limits. Android execution remains unavailable; hosted CI, Pages publication and
release qualification remain separate outstanding gates. This directory/profile slice does not retrieve subresources or provide a roster API.

## Committee House communication-reference coverage

House committee communication references now have raw-preserving records and open type/name
metadata, typed requests/endpoints, lazy page/item conveniences, focused tests, DocC and an
offline demo. Congress, number and type remain distinct; referral/update dates are unchanged
outer-record fields. Four official captures include a complete exact-link 5/5/5 chain against
count 15 plus a partial discovery page. Unsupported Senate/Joint factories and sequence
constructors fail synchronously before HTTP. Ordinary strict continuation and independent
service boundaries are unchanged. Shared committee-subresource acquisition used sixteen of
twenty requests; aggregate acquisition usage is ninety of 152. All 117 fixture hashes verify
and prior 113 remain unchanged. On October 4, 2026, the final source gate passed all 23 checks,
and strict formatting passed for the changed Data demo. All 25 initial focused Apple cases
passed. After correcting the fresh independent review's test-order finding, the final Xcode
MCP build succeeded in 10.327 seconds with three known linker sysroot warnings, and all 660
full-suite cases passed on iPhone 17, iOS 27, with zero failures, skips or unrun cases. The
review finding is resolved; no findings remain. Linux passed 326 tests in 40 suites in each
dependency graph, with execution times of 9.720 seconds for HTTPPortable and 6.222 seconds
for default, exit 0. All eight DocC catalogs plus merged output and the site built with zero
diagnostics, and both new articles were verified. All four demo executables passed 78 offline
invocations with exact fixture-output comparisons and recorded executable hashes. Source and
designated local checks are accepted with these platform limits. Android execution remains
unavailable; hosted CI and Pages publication have not run for these additions, and release
is not authorized. The unchanged House demo line 46 formatting finding remains a separate
baseline issue; the changed Data demo passed its formatting check.

## Committee nomination-reference coverage

Senate committee nomination references have raw-preserving records and nested action/type
projections, typed requests/endpoints, lazy page/item conveniences, tests, DocC and an offline
demo. Integer numbers remain separate from string parts, preserving leading zeroes. Four
official captures include a complete exact-link 32/32/32 chain against count 96, plus a partial
discovery page. Unsupported House/Joint factories and sequence constructors fail synchronously
before HTTP. Ordinary strict continuation and independent service boundaries are unchanged.
Acquisition brings shared committee-subresource usage to twelve of twenty; all 113 fixtures
verify and prior 109 remain unchanged. On October 4, 2026, the source gate passed all 23 checks,
and strict formatting passed for the changed Data demo. The Xcode MCP build succeeded in
13.644 seconds with three known linker sysroot warnings. All 25 focused and 635 full-suite
cases passed on iPhone 17, iOS 27, with zero failures, skips or unrun cases. Fresh independent
review found no issues. Linux passed 313 tests in 38 suites in each dependency graph, with
execution times of 5.963 seconds for HTTPPortable and 14.105 seconds for default, exit 0.
All eight DocC catalogs plus merged output and the site built with zero diagnostics. All
four demo executables passed 74 offline invocations with exact fixture-output comparisons.
Source and designated local checks are accepted with these platform limits. Android execution
remains unavailable; hosted CI, Pages publication and release qualification remain separate
outstanding gates.

## Committee report-reference coverage

Committee report references now have raw-preserving records, typed page/window queries,
requests/endpoints, lazy page/item conveniences, tests, DocC and an offline demo. Four
House committee responses include an exact 12/12 chain against count 24 and a recorded
part 2 with its citation and report-level URL. Integer report numbers and parts remain
separate; open type/chamber strings, raw dates, order and duplicates survive. No title,
report detail or document asset is inferred or fetched. Ordinary strict continuation is
unchanged. Four report requests bring shared committee-subresource usage to eight of twenty.
On October 4, 2026, the source gate passed all 23 checks. The final Xcode MCP rebuild
succeeded in 11.444 seconds, following the initial 13.774-second build; three known linker
sysroot warnings remain. All 20 initial focused cases passed. After correcting the fresh
independent review's missing consumer-defined factory test, all 11 cases in the focused
rerun and the final full 610-case suite passed on iPhone 17, iOS 27, with zero failures,
skips or unrun cases. The review finding is resolved. Linux passed 300 tests in 36 suites
in each dependency graph, with execution times of 6.751 seconds for HTTPPortable and
5.989 seconds for default, exit 0. All eight DocC catalogs plus merged output and the site
built with zero diagnostics. All four demo executables passed 70 offline invocations with
exact fixture-output comparisons. All 109 fixture hashes verified. Source and designated
local checks are accepted with these platform limits. Android execution remains unavailable;
hosted CI, Pages publication and release qualification remain separate outstanding gates.

## Committee report inventory, detail and text coverage

Standalone report inventories, ordered multipart detail and nested text metadata have
raw-preserving models, typed requests/endpoints, lazy inventory/text traversal, tests, DocC
and offline demos. Existing committee-associated report APIs remain compatible. Sixteen
official HTTP 200 captures cover all five routes, complete 96/96/94 inventory and 1/1/1/1
text chains, House/Senate/executive details, two report parts, bill/treaty references, and
explicit conference observations. All 137 fixture hashes/bytes verify and the prior 121
remain unchanged. Acquisition used sixteen of sixteen requests for this family and 110 of
152 overall, with no retries or redactions. The initially unexpected text-envelope response
retains its original bytes and unexpected-shape provenance; the recorder correction did not
rewrite that evidence. Positive errata, relative asset links and treaty letter parts remain
uncaptured and are covered only by labeled policy mutations. No URL-derived part, guessed
URL base or asset fetch is added.

On October 4, 2026, the final source gate passed all 23 checks and strict formatting passed
for the changed Data demo. The final Xcode MCP build succeeded in 6.607 seconds with three
known linker sysroot warnings. All 57 focused and 742 full-suite Apple cases passed on
iPhone 17, iOS 27, with zero failures, skips or unrun cases. Fresh independent
review is complete, with the fixture-formatting finding corrected and no remaining findings.
Linux passed 362 tests in 45 suites in each dependency graph, with execution times of
8.981 seconds for HTTPPortable and 8.335 seconds for default, exit 0.
All eight DocC catalogs plus merged output and the site built with zero diagnostics, and
both new articles were verified. All four demo executables
passed 98 offline invocations with exact fixture-output comparisons.
Source and designated local checks are accepted with these platform limits.
Android execution remains unavailable locally; hosted CI and Pages publication have not run
for these additions, and release is not authorized. The unchanged House demo line 46
formatting finding remains a separate baseline issue; the changed Data demo passed.

## Committee Senate communication-reference coverage

Senate committee communication references now have raw-preserving records and open type/name
metadata, typed requests/endpoints, lazy page/item conveniences, focused tests, DocC and an
offline demo. Congress, number and type remain distinct; referral/update dates remain unchanged
outer-record fields. Four official captures include an exact complete 11/11/9 chain against
count 31 and a partial discovery page, preserving EC, PM and POM type codes with source names.
Unsupported House/Joint factories and sequence constructors fail synchronously before HTTP.
Ordinary strict continuation and independent service boundaries are unchanged. Shared committee
subresource acquisition used twenty of twenty requests; aggregate usage is 94 of 152. All 121
fixture hashes verify and prior 117 remain unchanged. On October 4, 2026, the source gate passed
all 23 checks, and strict formatting passed for the changed Data demo. The Xcode MCP build
succeeded in 14.643 seconds with three known linker sysroot warnings. All 25 focused and 685
full-suite Apple cases passed on iPhone 17, iOS 27, with zero failures, skips or unrun cases.
Fresh independent review found no issues. Linux passed 339 tests in 42 suites in each dependency
graph, with execution times of 4.434 seconds for HTTPPortable and 4.643 seconds for default,
exit 0. All eight DocC catalogs plus merged output and the site built with zero diagnostics;
both new articles were verified. All four demo executables passed 82 offline invocations with
exact fixture-output comparisons and recorded executable hashes. Source and designated local
checks are accepted with these platform limits. Android execution remains unavailable; hosted
CI and Pages publication have not run for these additions, and release is not authorized. The
unchanged House demo line 46 formatting finding remains a separate baseline issue; the changed
Data demo passed its formatting check.

## CRS report coverage

CRS report inventory and detail models, typed requests/endpoints, lazy page/item conveniences,
tests, DocC, and offline demo modes are implemented. Seven official responses preserve exact
envelope capitalization, nested metadata, mixed related-number scalars, null titles, duplicate
references, and independent source versions/dates. The complete daily 5/4 chain uses ordinary
strict continuation. Acquisition used seven of eight authorized requests. Differences between
list and detail versions, and a source update date outside its requested narrow window, remain
unchanged provider data. On October 4, 2026, the 23-check source gate passed and the Xcode MCP
build succeeded in 9.862 seconds, with three linker sysroot warnings disclosed. All 28 focused
cases and the full 549-case suite passed on iPhone 17, iOS 27, with zero failed, skipped, or
unrun cases. Fresh independent review found no issues. Linux passed 264 tests in 30 suites in
each dependency graph (HTTPPortable and default), with execution times of 2.776 and 3.003 seconds.
All eight DocC catalogs plus merged output and the site built with zero diagnostics. All four
demo executables passed 51 offline invocations on iPhone 17, iOS 27, matching fixture output
exactly, including all seven CRS captures. Source and designated local checks are accepted with
these platform limits. Android, hosted CI, Pages publication, and release qualification remain
separate outstanding gates.

## Geographic member coverage

State/territory, district, and Congress/district routes now use `MemberGeographyQuery` through
existing member request, endpoint, and lazy page/item methods. Nine official responses reuse
MemberPage unchanged, including a complete Alaska 2/1 chain and a partial New York default-limit
chain. Missing districts and redistricting differences remain source data. Source, focused tests,
and both Data DocC catalogs are implemented. On October 4, 2026, the 23-check source gate passed,
the Xcode MCP build succeeded, and 32 focused cases plus the full 521-case suite passed on iPhone
17, iOS 27, with zero failed, skipped, or unrun cases. Three linker sysroot warnings remain
disclosed. Fresh independent review found no issues. Linux passed 251 tests in 28 suites in
each dependency graph (HTTPPortable and default), with exit 0. All eight DocC catalogs plus
merged output and the site built with zero diagnostics. All four demo executables passed 44
offline invocations on iPhone 17, iOS 27, matching fixture output exactly, including all nine
geographic captures. Source and designated local checks are accepted with these platform limits.
Android, hosted CI, Pages publication, and release qualification remain separate outstanding gates.

## Law inventory and lookup coverage

Law inventory and public/private law-number lookup source, tests, documentation, and offline demo
modes are implemented. Eight official responses confirm reuse of bill page/detail envelopes,
a complete private-law 1/1/1 chain, and modern public/private and historical law lookups.
`Bill.laws` preserves source citations separately from the originating bill identity. Ordinary
strict pagination is unchanged. Independent review is complete with no remaining findings.
The October 3, 2026 receipts record the 23-check source gate, 224 tests in 24 suites in each
Linux dependency graph, and all eight DocC catalogs plus the merged archive and site with zero
diagnostics. On iPhone 18 Pro, iOS 27, all 36 focused and 461 full Apple test cases passed with
zero failed, skipped, or unrun cases. Three linker sysroot warnings remain in the Data demo and
test bundles. These are retained results for the unchanged source, not new validation runs.

On October 4, 2026, the 23-check source gate passed again, and all 461 Apple test cases passed
on iPhone 17, iOS 27, with zero failed, skipped, or unrun cases. The incremental build succeeded
with zero reported warnings. All four demo executables passed 24 offline invocations on that
same destination, including all eight law fixtures, with exact fixture-output matches. These
completed runs clear the preceding test and demo startup timeouts; the earlier full-build
linker warnings remain disclosed. Fresh independent review found no remaining issues; source
and designated local checks are accepted with these platform limits. Android, hosted CI, Pages
publication, and release qualification remain separate outstanding gates.

## Bill cosponsor coverage

Bill cosponsors now have raw-preserving records, page/query models, typed requests/endpoints,
lazy traversal, tests, DocC, and an offline demo mode. Five official captures establish a complete
15/15/1 chain with active count 30 and inclusive count 31, a published withdrawal, an empty
modern response, and an integer House district. The internal count policy applies only to the
built-in cosponsor page; all other collection count behavior remains unchanged. Independent
review is complete, including the README demo example. The 23-check source gate and strict
source/test/demo formatting pass. Linux passes 211 tests in 22 suites in each dependency graph;
three supplemental Linux demo invocations match the recorded withdrawal, empty, and House
fixtures exactly. On October 3, 2026, 31 focused and all 425 Apple test cases passed on iPhone 18
Pro, iOS 27, with zero failed, skipped, or unrun cases. The preceding startup timeouts no longer
block this test gate. The incremental build succeeded with zero reported warnings; the earlier
full build's three linker sysroot warnings and two skipped AppIntents metadata warnings remain
disclosed. All eight DocC catalogs plus the merged archive and site built from the updated modules
with zero diagnostics. All four built demo executables passed 16 offline invocations with exact
fixture-output matches on iPhone 17 Pro, iOS 26.5. The retained Linux, DocC, and demo evidence covers
the unchanged source. Fresh independent review found no remaining issues; source and designated
local checks are accepted with these platform limits. Android, hosted CI, Pages publication, and release qualification
remain outstanding.

## Member legislation coverage

Sponsored and cosponsored member legislation now have distinct page envelopes, raw-preserving
bill/amendment records, typed requests/endpoints, lazy page/item APIs, tests, DocC, and offline
demo modes. Ten official captures include complete C001136 chains and L000174 amendment rows
with missing bill fields and null types. Independent review is complete. The 23-check source
gate, strict source/test/demo formatting, 32 focused and all 394 Apple cases (zero skips), and
198 tests in 20 suites in each Linux graph pass. All eight DocC catalogs, merged archive and site
build without warnings. Three linker sysroot warnings remain in the Data demo and test bundles.
All four demo executables passed 13 offline invocations with exact fixture-output matches on
iPhone 17 Pro, iOS 26.5. The iOS 27 simulator repeatedly stalled before main in shared-cache
mmap; that runtime launch issue remains unresolved. The passing Apple test results above are
from iOS 27, while the successful demo results are from iOS 26.5. Source and local validation
are accepted for this slice with these platform limits. Android, hosted CI, Pages publication, and release qualification remain outstanding.

## Summary coverage and validation

Bill summaries and all three summary-feed routes have models, typed requests/endpoints, lazy
page/item conveniences, tests, DocC, and offline demo modes. Thirteen official responses cover
every route, a complete three-page bill-summary chain, an empty historical response, and a
four-page unscoped feed chain without optional sort. The latter returns 2/2/2/1 entries at offsets
0/2/4/6 against count 7 and ends without a next link. Its regression coverage passed fresh independent review and the
local checks below. The recorded sorted feed still changes
a plus sign to a space in a later continuation, which is rejected before that page is yielded.
See SOURCE_VERIFICATION.md.

On September 29, 2026, the uncommitted summary additions based on `d6f2295`, including the
complete feed-chain fixtures and regression, passed independent code review, the 23-check source
gate, strict source/test/demo formatting, 39 focused summary cases and all 362 Apple test cases
on iPhone 18 Pro with iOS 27.0, and 186 tests in 18 suites in each Linux dependency graph
(`swift:6.3-noble`, HTTPPortable and default). All eight local DocC catalogs and merged output
built without warnings. The incremental Xcode build emitted two linker sysroot warnings in the
Data test bundles; six were recorded in the preceding full build, also affecting the four demos.
The cause is unresolved, so the Apple build is not warning-free. All four demos passed nine offline invocations with exact fixture-output matches. The existing
bill-text mode initially stalled in the simulator loader before main; restarting only the target
simulator without erasing data resolved it. Source and local validation are accepted for this
slice. Android, hosted CI, Pages publication, and release qualification remain outstanding.

The public swifty-networking 1.3.1 tag was verified September 24, 2026 UTC at
`04bbf231eabb95b90a5be786034e07cf351ee1d5`. The dependency floor is 1.3.1 and the tracked lockfile
records the HTTPPortable superset. No unpublished dependency override is used.

## Status by slice

| Slice | Local status | Hosted CI | Release |
| --- | --- | --- | --- |
| Congress.gov bill associations | source/Linux, iPhone 17 iOS 27 tests and demos, and DocC pass; source and local checks accepted; linker warnings disclosed | not run for additions | none |
| Congress.gov bill cosponsors | source/Linux, iOS 27 tests, DocC, and iOS 26.5 demos pass; source and local checks accepted; historical build warnings disclosed | not run for additions | none |
| Congress.gov committee bill relationships | source/Linux, iPhone 17 iOS 27 tests and demos, and DocC pass; source and local checks accepted; linker warnings disclosed | not run for additions | none |
| Congress.gov committee directories and profiles | source/Linux, iPhone 17 iOS 27 tests and demos, and DocC pass; source and local checks accepted; linker warnings disclosed | not run for additions | none |
| Congress.gov committee House communication references | source/Linux, iPhone 17 iOS 27 tests and demos, and DocC pass; source and local checks accepted; linker warnings disclosed | not run for additions | not authorized |
| Congress.gov committee nomination references | source/Linux, iPhone 17 iOS 27 tests and demos, and DocC pass; source and local checks accepted; linker warnings disclosed | not run for additions | none |
| Congress.gov committee report references | source/Linux, iPhone 17 iOS 27 tests and demos, and DocC pass; source and local checks accepted; linker warnings disclosed | not run for additions | none |
| Congress.gov amendment inventories, detail and bill lists | implementation present; review closure and source/local validation pending | not run for additions | not authorized |
| Congress.gov committee report inventories, detail and text | source/Linux, iPhone 17 iOS 27 tests and demos, and DocC pass; source and local checks accepted; linker warnings disclosed | not run for additions | not authorized |
| Congress.gov committee Senate communication references | source/Linux, iPhone 17 iOS 27 tests and demos, and DocC pass; source and local checks accepted; linker warnings disclosed | not run for additions | not authorized |
| Congress.gov CRS report lists and detail | source/Linux, iPhone 17 iOS 27 tests and demos, and DocC pass; source and local checks accepted; linker warnings disclosed | not run for additions | none |
| Congress.gov discovery, bill detail, bill lists, action lists | locally qualified | passed at `d6f2295` | none |
| Congress.gov geographic members | source/Linux, iPhone 17 iOS 27 tests and demos, and DocC pass; source and local checks accepted; linker warnings disclosed | not run for additions | none |
| Congress.gov law inventory and lookup | source/Linux, iPhone 17 iOS 27 tests and demos, and DocC pass; source and local checks accepted; historical build warnings disclosed | not run for additions | none |
| Congress.gov member sponsored and cosponsored legislation | source and local checks accepted; iOS 27 tests and iOS 26.5 demos; linker warnings disclosed | not run for additions | none |
| Congress.gov member browsing and detail | locally qualified | passed at `d6f2295` | none |
| Congress.gov bill text versions | locally qualified | passed at `d6f2295` | none |
| Congress.gov bill summaries and publication feeds | source and local checks accepted; linker warnings disclosed | not run for additions | none |
| Bioguide supplied-file import and historical-service queries | locally qualified | passed at `d6f2295` | none |
| House votes (inventories, roll calls, tallies, legislation references) | locally qualified | passed at `d6f2295` | none |
| Senate votes (inventories, roll calls, vote subjects, current identity crosswalk) | locally qualified | passed at `d6f2295` | none |

"Locally qualified" means, at `b5a94f7`: `bash Scripts/verify.sh` (23 `[PASS]`) and
`bash Scripts/verify.sh --self-test` (55 arms) both exit 0; `bash Scripts/linux-test.sh` passes both
the HTTPPortable and the default trait graph (169 tests in 16 suites each, `swift:6.3-noble`);
the Apple `swift-congress-Package` test plan passes in full (323 of 323) on iPhone 18 Pro, iOS 27.0
simulator, with 0 source build warnings; all four demos (CongressBioguideDemo, CongressDataDemo,
CongressHouseVotesDemo, CongressSenateVotesDemo) build and each ran at least once offline through
`xcrun simctl spawn` against a recorded or supplied fixture, output matching the fixture; and all
eight product DocC catalogs plus the merged archive build with zero warnings. This evidence is from
a local qualification run on 2026-09-27, at `b5a94f7`.

Android emulator execution was not run locally: no Android Swift SDK or `adb` is installed.
GitHub run metadata rechecked September 29, 2026 confirms that baseline CI run
[36325494128](https://github.com/KalebCooper/swift-congress/actions/runs/36325494128) completed
successfully at `d6f2295f146115cbbac845d83ed168ffb756c957`, with all five jobs successful:
Linux, Android, iOS, source conventions, and formatting. Docs run
[36325494053](https://github.com/KalebCooper/swift-congress/actions/runs/36325494053) records
successful build and Pages deployment jobs at that same SHA. These are baseline run statuses,
not qualification of the uncommitted summary additions. No release or tag was created for those
additions; the baseline records no package release.

## Known gaps

- `HouseRollCall.decode` (`Sources/SwiftCongressHouseVotesModels/HouseRollCall.swift`) throws
  `.invalidDocument` when a document lacks `vote-metadata` with a positive `congress` and
  `rollcall-num`, or lacks `vote-data`. The House DTD marks `vote-metadata` optional, so decode is
  stricter than the DTD. This is documented in DocC (`- Throws:`) and behavior is unchanged pending
  owner review.
- The DocC Topics section shape differs between the Congress.gov Data catalogs (grouped under `###`
  headings) and the other three pairs (flat lists). Cosmetic; a family-wide Topics convention is a
  later choice, deferred by the review that found it.
- One source-checker comment (`Scripts/verify-source.sh`, the test-title check) describes what it
  enforces more narrowly than the check itself does. No current test title depends on the gap: all
  169 recorded titles already satisfy the stricter behavior. Deferred to the next gate change.
- Demo targets under `Examples/` are plain SwiftPM `executableTarget`s with no `.xcodeproj`, a
  pre-existing deviation from the swift-government demo layout convention. They build and run
  through the Xcode MCP `swift-congress-Package` scheme and `xcrun simctl spawn`.

Fixtures record exact sanitized URLs, retrieval instants, statuses, media types, byte counts, hashes,
and provider IDs. Tests never reach live sources. See SOURCE_VERIFICATION.md.

The Bioguide refresh operating model remains an owner decision. Supplied-file import is independent
of that decision. The locally available official archive digest was reverified; no unattended
endpoint or capped-search replacement is assumed.
