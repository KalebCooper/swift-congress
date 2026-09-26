# Contributing

This repository contains four independent implemented SDK/models pairs: SwiftCongressBioguide,
SwiftCongressData, SwiftCongressHouseVotes, and SwiftCongressSenateVotes. Add a new product only
when its service has models, implementation, recorded fixtures, tests, documentation, and a useful
example.

Run `bash Scripts/verify.sh` before committing and `bash Scripts/verify.sh --self-test` after
changing verification. These checks do not prove Apple, Linux, Android, or documentation readiness.

Use Swift 6 with strict concurrency and memory safety. Alphabetize declarations within logical groups.
Use Swift Testing with shared suite limits. Never send deterministic tests to a live provider.
Preserve all provider fields, unknown values, nulls, identifiers, and source provenance.

Read [IMPLEMENTATION_READINESS.md](IMPLEMENTATION_READINESS.md) for current validation status. Use
Xcode MCP for supported local Xcode operations. Do not create custom Xcode schemes. Conventional
Commits use lowercase imperative subjects, 60 characters or fewer. Pushes and releases require owner
direction.
