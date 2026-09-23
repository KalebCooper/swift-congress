# Contributing

This repository contains infrastructure only. Keep public products absent until a working service
slice includes models, implementation, recorded fixtures, tests, documentation, and a useful example.

Run `bash Scripts/verify.sh --scaffold` before committing infrastructure and
`bash Scripts/verify.sh --self-test` after changing verification. These checks do not prove source,
Apple, Linux, Android, or documentation readiness. The default gate deliberately fails without source.

Use Swift 6 with strict concurrency and memory safety. Alphabetize declarations within logical groups.
Use Swift Testing with shared suite limits. Never send deterministic tests to a live provider.
Preserve all provider fields, unknown values, nulls, identifiers, and source provenance.

Read [IMPLEMENTATION_READINESS.md](IMPLEMENTATION_READINESS.md) before implementation. Activate CI
only after real source, fixtures, tests, documentation catalogs, and dependencies exist. Use Xcode MCP
for supported local Xcode operations. Do not create custom Xcode schemes. Conventional Commits use
lowercase imperative subjects, 60 characters or fewer. Pushes and releases require owner direction.
