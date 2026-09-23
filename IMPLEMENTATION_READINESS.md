# Implementation readiness

Only repository infrastructure is ready. The networking prerequisite must be implemented and
verified separately before any HTTP service is started. No dependency version is selected here.
HTTPPortable, its forwarded trait, and transport dependencies arrive with a real implementation.

## Service boundaries

| Future SDK | Future independent models module | Source |
| --- | --- | --- |
| SwiftCongressBioguide | SwiftCongressBioguideModels | Official Bioguide supplied profile export; file import first. |
| SwiftCongressData | SwiftCongressDataModels | Congress.gov API congresses, bills, members, actions, document links. |
| SwiftCongressHouseVotes | SwiftCongressHouseVotesModels | House Clerk year indexes and published roll-call XML. |
| SwiftCongressSenateVotes | SwiftCongressSenateVotesModels | Senate session indexes, roll-call XML, current identity data. |

Each pair stands alone. Models have no networking dependency; SDKs depend only on their own models
and approved transport dependencies. No shared client or cross-service imports. Add only implemented
products. Bioguide import does not imply a network client or fabricated endpoint API.

Recheck current official provider contracts before implementing. The design evidence records a
Congress.gov explicit API key, list bounds, and provider-specific quotas; those facts are not a live
verification or an SDK guarantee. House and Senate XML vary across historical years. Preserve raw
voter identity and positions, nullable member matches, procedural questions, and source totals.
Bioguide export availability and archive-count reconciliation require an explicit operating model.
Do not substitute capped search exports for a full archive or invent unsupported unattended access.
Coverage spans every available era and predecessor body where the source supports it; missing
digitization is not an empty historical record. Keep source authority and provenance field-specific.

## Activation checklist

1. Verify the separate networking work and official service contracts, authentication, pagination,
   XML portability, rate limits, rights, and data guarantees.
2. Implement one service slice with dependency-free models and recorded official fixtures. Add
   test support, bounded Swift Testing suites, and ergonomic request/endpoint/client consumer checks
   where HTTP applies. Add every target with the shared strict Swift settings.
3. Add actual dependencies, the conditional HTTPPortable trait, and its verified superset lockfile.
4. Adapt the prepared source checker for the implemented services, including the file-import
   exception for Bioguide, and prove its planted violations. The prepared source checker retains
   NOAA's source rules; its template self-tests do not prove any Congress source exists.
5. Add real product DocC catalogs, SPI configuration, and a working demo with project format 77.
   Update the documentation script for each implemented product pair and restore the release-demo
   step only on the xcode-27 Apple matrix entry.
6. Run the full repository gate, Apple build/tests through Xcode MCP, Linux both trait modes,
   Android, and local DocC with zero warnings. All are pending. Enable the prepared CI jobs only
   after the corresponding artifacts exist. All timeout values remain provisional until green runs.

The infrastructure gate checks the empty manifest, required files, shell syntax, disabled source
lanes, and timeout declarations. It does not certify semantic YAML validation or hosted runner support.
No custom Xcode schemes, placeholder targets, empty DocC catalogs, SPI targets, demos, or lockfiles
are included. No remote, push, tag, GitHub Release, or publication is part of this scaffold.
