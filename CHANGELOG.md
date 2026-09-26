# Changelog

This project follows Keep a Changelog and Semantic Versioning. No version has been released.

## Unreleased

### Added

- Independent Senate session inventories, roll calls, and dated current LIS-to-Bioguide identities.
- Typed Senate bill/amendment/nomination/treaty vote subjects, read from the same roll-call
  document, with documentation, tests, and a demo that prints them beside the raw question.
- Open House and Senate position values and bounded, entity-rejecting system XML codecs.

- Independent House HTML inventories and XML roll calls, bounded decoding, historical optional IDs,
  source receipts, fixtures, documentation, tests, and a runnable file demo.
- Typed House vote-total tallies and conservative legislation-label recognition, read from the
  same roll-call document, with documentation, tests, and a demo that prints both.

- Bioguide supplied-file import with bounded extraction, per-profile SHA-256, count/identity validation,
  original profile bytes, historical service models, and a full-archive validation demo.
- Bioguide historical-service queries matching a profile's own positions by Congress, job, and
  region, a lazy import-time filtered record sequence, and a demo filter mode.

- Congress.gov discovery, bill detail and lists, and bill action lists.
- Independent portable models, immutable typed requests/endpoints, and lazy page/item sequences.
- Source-byte receipts, origin and continuation validation, explicit credentials, and transport injection.
- Current and historical official fixtures, deterministic tests, product documentation, and a file-based demo.
- Optional HTTPPortable transport forwarding using swifty-networking 1.3.1 or later.
