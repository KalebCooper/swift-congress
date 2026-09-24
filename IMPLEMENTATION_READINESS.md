# Implementation readiness

SwiftCongressData and SwiftCongressDataModels implement Congress discovery, bill detail, bill
inventories, and action inventories. Bioguide supplied-file import is implemented and has validated all 13,056 records in the supplied
official archive. Independent House and Senate vote services are implemented, including explicit inventories and
the Senate current identity crosswalk. Source coverage does
not establish historical completeness.

The public swifty-networking 1.3.1 tag was verified September 24, 2026 UTC at
`04bbf231eabb95b90a5be786034e07cf351ee1d5`. The dependency floor is 1.3.1 and the tracked lockfile
records the HTTPPortable superset. No unpublished dependency override is used.

## Verified locally

- Strict source verification and all 47 planted source-checker arms.
- 43 Linux Swift 6.3.3 tests in eight suites, both default traits and HTTPPortable.
- Eight Congress.gov, Bioguide, House, and Senate DocC catalogs, built from Linux modules with zero warnings.
- CongressDataDemo, CongressBioguideDemo, CongressHouseVotesDemo, and CongressSenateVotesDemo execution against recorded or supplied source data.

## Remaining gates

- Apple package build/tests and Xcode application demo: the MCP connection closed; fresh clients
  register this package but scoped queries do not complete, including after a Congress-only
  close/reopen. The generated package scheme is registered. A template skeleton was written by
  MCP without a completed tool response and is preserved under ignored plans, not published as a demo.
  No shell Apple build or hand-edited project was substituted.
- Android emulator execution: no local Android Swift SDK or adb is installed.
- Hosted CI, both iOS matrix entries, documentation publication, remote creation, and release.
- Congress.gov member and text-version slices are not implemented: fresh official payload acquisition
  is blocked by HTTP 429, with Retry-After 81242 seconds on the final attempt. No substitute
  credentials or synthetic official fixtures were used. An authorized key location is awaiting owner input.

Fixtures record exact sanitized URLs, retrieval timestamps, statuses, media types, byte counts,
hashes, and provider IDs. Tests do not reach live sources. See SOURCE_VERIFICATION.md.

The Bioguide refresh operating model is awaiting owner input. Supplied-file import remains
independent of that decision. The locally available official archive digest was reverified;
no unattended endpoint or capped-search replacement is assumed.
