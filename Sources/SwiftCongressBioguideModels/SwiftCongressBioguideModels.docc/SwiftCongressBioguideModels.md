# ``SwiftCongressBioguideModels``

Portable profile, service affiliation, and supplied-snapshot provenance models.

## Overview

The models have no transport or third-party dependency. Profile fields retain
source spelling, partial date strings, explicit nulls, omitted values, unknown
JSON fields, and asset rights. Encoding emits the complete retained source object.

```swift
let profile = try JSONDecoder().decode(BioguideProfile.self, from: bytes)
for position in profile.jobPositions {
  if let congress = position.congressAffiliation?.congress {
    print(congress.congressType, congress.congressNumber)
  }
}
```

The pair of congressType and congressNumber identifies a legislative body.
Continental Congress 2 and U.S. Congress 2 are different identities. Congress
affiliation dates are separate from personal job dates and never fill missing
service dates. A profile with no structured congressional service remains a profile.
Birth/death dates remain strings: a year such as 1806 is not converted to January 1.

Asset availability does not grant portrait reuse. Preserve usageRight, credit,
source links, and all unmodeled fields in rawFields. Unknown values are not errors.
Exact original JSON bytes remain available in BioguideRecord from the importer.

## Topics

- ``BioguideAffiliation``
- ``BioguideCongress``
- ``BioguideManifest``
- ``BioguideManifestEntry``
- ``BioguidePosition``
- ``BioguideProfile``
- ``BioguideRecord``
- ``JSONValue``
