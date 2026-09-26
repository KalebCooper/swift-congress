# Querying historical service

Match positions and profiles against Congress, job, and region exactly as the export publishes
them, with no timeline and no completeness claim.

## Query one loaded profile

```swift
import Foundation
import SwiftCongressBioguideModels

let profile = try JSONDecoder().decode(BioguideProfile.self, from: bytes)
let congress = try BioguideCongressIdentifier(number: 2, type: .continentalCongress)
let query = BioguideServiceQuery(congress: congress, job: .delegate, regionCode: "PA")
let matches = profile.positions(matching: query)
```

`BioguideProfile.positions(matching:)` evaluates each of the profile's positions against every
predicate a `BioguideServiceQuery` sets. Congress and body are compared together through
`BioguideCongressIdentifier`: the 2nd Continental Congress and the 2nd United States Congress never
satisfy the same query. Job and region come from the position's own job and affiliation views,
never another position's. Every set predicate needs its own evidence on that position; an absent,
null, or non-string field never satisfies it. A query with no predicates matches every position.
A profile with no positions never matches, even an empty query; use ``BioguideRecords`` for every
profile. Comparison is exact and case-sensitive against the published raw strings:
`BioguideJobName` and `BioguideCongressType` keep an unrecognized source spelling through
`init(rawValue:)` rather than rejecting it.

## Filter while importing

```swift
import SwiftCongressBioguide
import SwiftCongressBioguideModels

let query = BioguideServiceQuery(job: .senator)
for try await record in importer.records(in: directory, matching: query) {
  print(record.profile.usCongressBioId)
}
```

``BioguideImporter/records(in:matching:)`` returns ``BioguideMatchingRecords``, which reads and
verifies profiles in manifest order and yields a profile's complete record the first time
`BioguideProfile.positions(matching:)` on it is non-empty. Verification is unconditional: a corrupt
or mismatched profile still throws even when its positions would not have matched, so a successful
filtered pass proves every scanned profile decoded and checksummed, not only the ones returned.
Nothing is read ahead, and only the profile under evaluation is held in memory; see
<doc:SwiftCongressBioguide> for the shared laziness and cancellation contract.

## What a match does not mean

A query answers which already-supplied positions carry the queried values today, in this snapshot.
It has no date or as-of semantics: personal service dates are frequently missing, and an
affiliation's Congress dates describe the body, not when the person held the position. Matching
infers no chamber (a Delegate to the Continental Congress is not a modern House member) and performs
no identity join across profiles. A nonempty result is not a claim that the export is complete, and
an empty result over a partial snapshot is not evidence that the position was never published.
