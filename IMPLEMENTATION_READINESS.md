# Implementation readiness

SwiftCongressData and SwiftCongressDataModels implement Congress discovery, bill detail, bill
inventories, and action inventories. Bioguide supplied-file import is implemented and has validated all 13,056 records in the supplied
official archive. Independent chamber services remain pending. Source coverage does
not establish historical completeness.

The public swifty-networking 1.3.1 tag was verified September 24, 2026 UTC at
`04bbf231eabb95b90a5be786034e07cf351ee1d5`. The dependency floor is 1.3.1 and the tracked lockfile
records the HTTPPortable superset. No unpublished dependency override is used.

## Verified locally

- Strict source verification and all 47 planted source-checker arms.
- Linux Swift 6.3.3 tests, both default traits and HTTPPortable.
- Congress.gov and Bioguide DocC catalogs, built from Linux modules with zero warnings.
- CongressDataDemo execution against the recorded Congress 6 bill.

## Remaining gates

- Apple package build/tests and Xcode application demo: the MCP connection closed; fresh clients
  list tools but Xcode calls do not complete. The generated package scheme is registered.
  No shell Apple build or hand-edited project was substituted.
- Android emulator execution: no local Android Swift SDK or adb is installed.
- Hosted CI, both iOS matrix entries, documentation publication, remote creation, and release.
- Congress.gov members and text-version payload acquisition after the observed HTTP 429.
- Independent House/Senate services.

Fixtures record exact sanitized URLs, retrieval timestamps, statuses, media types, byte counts,
hashes, and provider IDs. Tests do not reach live sources. See SOURCE_VERIFICATION.md.

The Bioguide refresh operating model is awaiting owner input. Supplied-file import remains
independent of that decision. The locally available official archive digest was reverified;
no unattended endpoint or capped-search replacement is assumed.
