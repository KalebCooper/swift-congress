# Implementation readiness

Six Swift Congress surfaces are implemented: Congress.gov discovery, bill detail, bill lists, and
action lists; Congress.gov member browsing and detail; Congress.gov bill text versions; Bioguide
supplied-file import and historical-service queries; independent House votes; and independent
Senate votes. Source coverage does not establish historical completeness.

The public swifty-networking 1.3.1 tag was verified September 24, 2026 UTC at
`04bbf231eabb95b90a5be786034e07cf351ee1d5`. The dependency floor is 1.3.1 and the tracked lockfile
records the HTTPPortable superset. No unpublished dependency override is used.

## Status by slice

| Slice | Local status | Hosted CI | Release |
| --- | --- | --- | --- |
| Congress.gov discovery, bill detail, bill lists, action lists | locally qualified | not run | none |
| Congress.gov member browsing and detail | locally qualified | not run | none |
| Congress.gov bill text versions | locally qualified | not run | none |
| Bioguide supplied-file import and historical-service queries | locally qualified | not run | none |
| House votes (inventories, roll calls, tallies, legislation references) | locally qualified | not run | none |
| Senate votes (inventories, roll calls, vote subjects, current identity crosswalk) | locally qualified | not run | none |

"Locally qualified" means, at `b5a94f7`: `bash Scripts/verify.sh` (23 `[PASS]`) and
`bash Scripts/verify.sh --self-test` (55 arms) both exit 0; `bash Scripts/linux-test.sh` passes both
the HTTPPortable and the default trait graph (169 tests in 16 suites each, `swift:6.3-noble`);
the Apple `swift-congress-Package` test plan passes in full (323 of 323) on iPhone 18 Pro, iOS 27.0
simulator, with 0 source build warnings; all four demos (CongressBioguideDemo, CongressDataDemo,
CongressHouseVotesDemo, CongressSenateVotesDemo) build and each ran at least once offline through
`xcrun simctl spawn` against a recorded or supplied fixture, output matching the fixture; and all
eight product DocC catalogs plus the merged archive build with zero warnings. This evidence is the
Q2 through Q4 qualification pass, 2026-09-27 09:03..09:08 CT, at `b5a94f7`.

Android emulator execution was not run here: no local Android Swift SDK or `adb` is installed; the
pinned hosted Android lane remains the required execution gate. Hosted CI (all four GitHub Actions
lanes) has never run against this repository. No package release exists and no version is tagged.

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
