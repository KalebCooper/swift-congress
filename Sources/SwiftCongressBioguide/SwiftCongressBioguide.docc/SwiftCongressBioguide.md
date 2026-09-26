# ``SwiftCongressBioguide``

Validate and read a supplied Bioguide profile snapshot with bounded memory.

## Overview

Bioguide is a file distribution. This product has an importer rather than a fabricated
HTTP client or endpoint API. It does not choose a refresh schedule or merge members
with Congress.gov or chamber vote identities.

Use Scripts/prepare-bioguide.py with an official all-profile ZIP, a new staging
directory, and the actual retrieval instant. The script rejects traversal paths,
symbolic links, duplicate entries and identifiers, encrypted files, invalid CRC,
mismatched names, and configured-size violations. It records the original archive
SHA-256 and the exact extracted profile hashes. Capped search exports are not full
snapshots; select the official Download all profiles export.

```swift
let importer = try BioguideImporter(manifest: manifest)
for try await record in importer.records(in: directory) {
  persist(record.entry.identifier, bytes: record.body)
}
```

The importer validates manifest bounds at construction. Directory reconciliation
occurs on first iteration. Each read verifies a regular nonsymlink file, bounded
length, SHA-256, JSON schema, and source identifier before yielding. Reads run away
from the caller's actor and check cancellation before and after file I/O and decode.
Each iterator starts independently. A failure ends only that iterator. Early break
does not validate unvisited files.

Keep the caller-staged directory immutable during traversal. This importer is not
a filesystem sandbox against another process replacing files concurrently. Snapshot
promotion and database transactions belong to the caller. Exhaust the sequence
successfully before promoting it; a checksum verifies supplied evidence, not the
live website's completeness. The original ZIP digest is preserved as provenance,
not recomputed from extracted files.

Defaults bound the snapshot to 30,000 profiles, 4 MiB per profile, and 512 MiB total.
Only the manifest and current decoded profile remain in memory. No network access
occurs and no ZIP dependency is required. Portable SHA-256 uses swift-crypto.

## Topics

- ``BioguideError``
- ``BioguideImporter``
- ``BioguideMatchingRecords``
- ``BioguideRecords``
- <doc:HistoricalServiceQueries>
