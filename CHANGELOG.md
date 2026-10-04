# Changelog

This project follows Keep a Changelog and Semantic Versioning. No version has been released.

## Unreleased

### Added

- Congress.gov amendment inventories, detail and bill-associated lists, with open amendment
  codes, independent bill/amendment/treaty targets, source roles and resource metadata, strict
  lazy traversal, typed requests/endpoints and offline demos.

- Congress.gov committee bill relationships, with nested resource metadata, open relationship labels,
  source action/update dates, typed requests/endpoints, strict lazy traversal and an offline demo.

- Congress.gov committee directories and global/Congress-scoped profiles, with ordered history,
  explicit relationships, raw resource links, typed requests/endpoints, strict lazy traversal,
  pre-HTTP detail-scope validation and offline directory/profile demos.

- Congress.gov committee House communication references, preserving open type codes and names,
  separate source dates and links through House-only typed requests, strict traversal and a demo.

- Congress.gov committee nomination references, with original number/part identity, nested action/type
  fields, Senate-only typed requests/endpoints, strict lazy traversal and an offline demo.

- Congress.gov committee report inventories, multipart detail and text metadata, with
  open report codes, explicit conference queries, separate bill/treaty references, nested formats
  and errata strings, strict lazy traversal, typed requests/endpoints and offline demos.

- Congress.gov committee report references, preserving source report numbers, parts, citations and
  raw dates/links through typed page/window queries, strict lazy traversal and an offline demo.

- Congress.gov committee Senate communication references, preserving open type codes and names,
  separate source dates and links through Senate-only typed requests, strict traversal and a demo.

- Congress.gov CRS report lists and detail, with raw-preserving nested metadata, independent source
  dates and versions, typed requests/endpoints, strict lazy traversal, and offline metadata demos.

- Congress.gov geographic member browsing with route-specific state, district, and Congress/district
  queries, existing member page models, strict lazy traversal, and recorded redistricting examples.

- Congress.gov related bills, legislative subjects with separate policy areas, and bill committee
  associations, preserving authorities, activities, nested subcommittees, and raw counts through
  typed requests/endpoints, lazy traversal, exact receipts, and offline demo modes.

- Congress.gov law inventories and public/private law-number lookup, returning originating bill
  envelopes with raw-preserving law citations, lazy traversal, and offline law demo modes.

- Congress.gov bill cosponsors, with typed source fields, active and withdrawal-inclusive counts,
  lazy traversal, exact receipts, and an offline cosponsor demo mode.

- Congress.gov member sponsored and cosponsored legislation, with raw-preserving bill/amendment
  records, distinct page envelopes, lazy traversal, exact receipts, and offline demo modes.

- Congress.gov bill summary versions and summary publication feeds, with scoped date-window queries,
  raw HTML and version codes, lazy traversal, exact receipts, and offline summary demo modes.

- Congress.gov discovery, bill detail and lists, and bill action lists.
- Independent portable models, immutable typed requests/endpoints, and lazy page/item sequences.
- Source-byte receipts, origin and continuation validation, explicit credentials, and transport injection.
- Current and historical official fixtures, deterministic tests, product documentation, and a file-based demo.
- Optional HTTPPortable transport forwarding using swifty-networking 1.3.1 or later.

- Bioguide supplied-file import with bounded extraction, per-profile SHA-256, count/identity validation,
  original profile bytes, historical service models, and a full-archive validation demo.
- Bioguide historical-service queries matching a profile's own positions by Congress, job, and
  region, a lazy import-time filtered record sequence, and a demo filter mode.

- Independent House HTML inventories and XML roll calls, bounded decoding, historical optional IDs,
  source receipts, fixtures, documentation, tests, and a runnable file demo.
- Typed House vote-total tallies and conservative legislation-label recognition, read from the
  same roll-call document, with documentation, tests, and a demo that prints both.

- Independent Senate session inventories, roll calls, and dated current LIS-to-Bioguide identities.
- Typed Senate bill/amendment/nomination/treaty vote subjects, read from the same roll-call
  document, with documentation, tests, and a demo that prints them beside the raw question.
- Open House and Senate position values and bounded, entity-rejecting system XML codecs.

- Congress.gov member browsing (unscoped and per-Congress lists) and single-member detail
  retrieval, distinguishing the raw `currentMember` filter from historical terms, with
  documentation and a demo that prints recorded member files.
- Congress.gov bill text-version browsing for both bill identifier forms, lazy page and version
  traversal, format links preserved as supplied metadata only, and a demo mode that lists recorded
  version and format fields from a file.
