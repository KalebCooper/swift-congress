# swift-congress

![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)

Independent Swift libraries for published United States congressional records.

## Status

Congress.gov discovery, bill detail, bill lists, and action lists are implemented with portable
models, typed requests/endpoints, lazy page and item sequences, and exact source response receipts.
Fixtures cover Congresses 6, 82, and 119 and the earliest Congress discovery page. Member browsing
and single-member detail are also implemented: the unscoped and per-Congress list routes and the
by-identifier detail route, with the raw `currentMember` filter kept separate from a member's typed
historical `terms`, and `partyHistory`, `leadership`, `previousNames`, and `addressInformation` kept
as raw fields only. Bill text versions are implemented for both bill identifier forms: lazy page and
version traversal, with format links kept as supplied metadata and never fetched. Text fixtures cover
the historical Congress 6 `hr 1`, Congress 82 `s 677`, and modern Congress 119 `hr 1` bills; nothing
beyond these recorded bills, or beyond the members the API publishes, is claimed. Unknown fields,
null values, and historical source identifiers are preserved throughout. No historical completeness,
stable snapshot, freshness, availability, or identity matching is guaranteed.

Bill summary versions and the publication feed are implemented with raw HTML, open version codes,
separate bill/feed records, and lazy pages and items. Feed scopes include all bills, one Congress,
and one Congress/bill type. Omitted dates retain the provider's recent-day default; use finite
windows for backfills. See [bill summaries](Sources/SwiftCongressData/SwiftCongressData.docc/BillSummaries.md).

Bill cosponsors retain original flags, sponsorship and withdrawal dates, and both active and
withdrawal-inclusive totals. Lazy traversal follows the inclusive total when published while
preserving raw metadata. See [bill cosponsors](Sources/SwiftCongressData/SwiftCongressData.docc/BillCosponsors.md).

Bill related records preserve every relationship authority and duplicate row. Legislative subjects
and their separate policy areas retain source vocabulary and raw counts. Committee associations
include ordered activities and nested subcommittees without fetching linked profiles. Each route
provides typed requests/endpoints, lazy pages/items, and exact receipts. See
[bill associations](Sources/SwiftCongressData/SwiftCongressData.docc/BillAssociations.md).

Committee bill retrieval preserves source relationship labels, action/update dates, string bill
numbers and separate resource/pagination counts. Typed requests and strict lazy traversal support
modification windows without fetching linked bill details. See
[committee bills](Sources/SwiftCongressData/SwiftCongressData.docc/CommitteeBills.md).

Committee directories support all, chamber, Congress, and Congress/chamber scopes. Profiles retain
ordered history, current status, explicit parent/subcommittee references and scoped resource links.
No profile name, chamber, relationship or continuation is inferred from other fields. See
[committee directories](Sources/SwiftCongressData/SwiftCongressData.docc/CommitteeDirectory.md).

Committee House communication references preserve open type codes and names, separate referral/update
dates and source links. House-only typed factories reject unsupported chambers before HTTP; strict
lazy traversal retains ordered duplicates without fetching standalone details. See
[committee House communications](Sources/SwiftCongressData/SwiftCongressData.docc/CommitteeHouseCommunications.md).

Committee nomination references preserve integer numbers, string parts including leading zeroes,
raw dates, latest actions and civilian/military flags. Senate-only typed factories reject unsupported
chambers before HTTP; strict lazy traversal retains ordered duplicates without fetching details. See
[committee nominations](Sources/SwiftCongressData/SwiftCongressData.docc/CommitteeNominations.md).

Committee report references preserve integer report numbers and parts, exact citations, open
source types and raw dates/links. Typed page/window queries and strict lazy traversal retain
ordered duplicates without fetching report detail or documents. See
[committee reports](Sources/SwiftCongressData/SwiftCongressData.docc/CommitteeReports.md).

Amendment inventories cover three scopes, detail and bill-associated lists, with open codes,
independent bill/amendment/treaty targets and strict lazy traversal. Source dates, sponsors,
on-behalf roles, notes and resource counts remain separate. No nested resource or text asset is
fetched automatically. See [amendments](Sources/SwiftCongressData/SwiftCongressData.docc/Amendments.md).
Offline Data demo modes are `--amendments` and `--amendment`.

Standalone committee report inventories support three scopes, optional conference values and date
windows. Detail retains every ordered report part with separate bill/treaty references; strict
text traversal preserves nested format links and open errata strings without retrieving assets.
See [standalone reports](Sources/SwiftCongressData/SwiftCongressData.docc/CommitteeReportInventory.md).
Offline Data demo modes are `--committee-reports`, `--committee-report` and `--committee-report-text`.

Committee Senate communication references preserve open type codes and names, separate referral/update
dates and source links. Senate-only typed factories reject unsupported chambers before HTTP; strict
lazy traversal retains ordered duplicates without fetching standalone details. See
[committee Senate communications](Sources/SwiftCongressData/SwiftCongressData.docc/CommitteeSenateCommunications.md).

CRS report lists and detail preserve authors, topics, format links, related materials, and separate
source dates and versions. Typed requests, strict lazy traversal, and exact receipts support
metadata ingestion without downloading assets. See [CRS reports](Sources/SwiftCongressData/SwiftCongressData.docc/CRSReports.md).

Law inventories and public/private law-number lookup return the originating bill envelopes.
Typed law lookup keys stay separate from bill identities; `Bill.laws` retains the provider's
citation numbers and open category labels. See [laws](Sources/SwiftCongressData/SwiftCongressData.docc/Laws.md).

Geographic member browsing supports state/territory, district, and Congress/district routes
through `MemberGeographyQuery` and the existing member methods. Route-specific controls preserve
missing districts and redistricting results without inferring historical membership. See
[member geography](Sources/SwiftCongressData/SwiftCongressData.docc/MemberGeography.md).

Member sponsored and cosponsored legislation have separate page envelopes and lazy traversal.
Records preserve bill titles and policy areas, and amendment numbers when published. Missing bill
fields and null amendment types remain missing; no identifier is inferred from a URL.
See [member legislation](Sources/SwiftCongressData/SwiftCongressData.docc/MemberLegislation.md).

Bioguide supplied-file import verifies bounded profile reads, inventory counts, SHA-256, source IDs,
and predecessor-body affiliations. A full 13,056-profile official snapshot has passed the importer.
Historical-service queries match a profile's own positions against Congress, job, and region exactly
as published; the query is source-service matching, not a timeline. Filtered results are not a
validation report; an early break validates nothing beyond the scanned profiles, and the
whole-directory demo mode remains the validation path.

House year/section discovery and roll calls are implemented independently, including historical rows
without member IDs. A roll call's typed tallies are the Clerk's published totals, read from the same
document and never recomputed from voter rows, and its typed legislation reference is conservative
label recognition, not a Congress.gov crosswalk.

Senate session inventories, roll calls, and the dated current LIS-to-Bioguide crosswalk are also
independent services. A Senate roll call's typed subject identifies the bill, amendment, nomination,
or treaty document the vote concerned, read from the same document and never a Congress.gov
crosswalk. Historical identity gaps remain unresolved.

No package release exists. See [implementation readiness](IMPLEMENTATION_READINESS.md) for
validation status.

## Usage

```swift
import SwiftCongressData
import SwiftCongressDataModels

let client = CongressDataClient(apiKey: key, userAgent: "MyCivicApp/1.0")
let source = try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill)
let detail = try await client.bill(source)
let reusable = CongressRequest.bill(source)
let same = try await client.value(for: reusable)

for try await bill in client.bills(matching: try BillQuery(congress: 6)) {
  print(bill.title)
}
```

Use `response(for:)` for one endpoint receipt and `billPages(matching:)` for page receipts.
Each receipt contains the exact decoded bytes, status, and repeated headers. Configure transports
explicitly off Apple platforms. API keys are required and are sent only through X-Api-Key.

## Example

`Examples/CongressDataDemo` decodes an official recorded bill from a supplied file path, or a
recorded member detail or member list page with `--member <path>` and `--members <path>`, or a
recorded bill text-version page with `--text <path>`, listing each version's type and date and
each format's type and raw url. Its Apple live mode accepts `--live` and an explicit API key for
the bill route, unchanged. The demo never supplies a default key and never fetches a format link.
Deterministic example inputs include `Sources/SwiftCongressDataTestSupport/Fixtures/bill6.json`,
`member-L000174.json`, `members117-first.json`, and `bill119-text-first.json`.
Use `--members <path>` with `members-ak-current-first.json`, `members-dc-district0-current.json`,
or `members118-tx15-historical.json` to inspect geographic inventories in that fixture directory.
Use `--cosponsors <path>` with `bill117-s3580-cosponsors-next.json` in that fixture directory
to inspect source names, original flags, district values, sponsorship and withdrawal dates,
and both active and withdrawal-inclusive totals.
Use `--related-bills <path>`, `--subjects <path>`, or `--committees <path>` with
`bill119-s5-related-first.json`, `bill119-s5-subjects-first.json`, or
`bill117-hr3076-committees-first.json` to inspect authorities, policy areas, and committee activities.
Use `--committee-bills <path>` with `committee-house-hspw00-bills-chain-terminal.json`
to inspect source bill relationships, dates, links and separate nested/pagination counts.
Use `--committee-directory <path>` with `committee-directory-congress-119-joint-chain-first.json`,
or `--committee <path>` with `committee-118-house-hspw00.json`, to inspect directory metadata,
profile history and relationship/resource counts. The `--committees` mode still reads bill associations.
Use `--committee-house-communications <path>` with
`committee-house-hsso00-house-communications-chain-first.json` to inspect original communication
identity, type, name, chamber, separate dates and links.
Use `--committee-nominations <path>` with `committee-senate-slia00-nominations-chain-first.json`
to inspect nomination numbers, unchanged parts, citations, dates and links.
Use `--committee-report-references <path>` with `committee-house-hspw00-reports-chain-terminal.json`
to inspect report parts, citations, source dates and links.
Use `--committee-senate-communications <path>` with
`committee-senate-slet00-senate-communications-chain-first.json` to inspect original communication
identity, type, name, chamber, separate dates and links.
Use `--crs-report <path>` with `crs-report-r47175.json`, or `--crs-reports <path>` with
`crs-reports-day-first.json`, to inspect compact report metadata without printing entire summaries.
Use `--law <path>` with `law119-public1.json` or `law93-public1.json`, and `--laws <path>`
with `law117-private-first.json`, to inspect originating bill identities and source law citations.
The same demo accepts `--summaries <path>` and `--summary-updates <path>` for recorded summary
pages, printing source HTML and version metadata. Inputs include `bill119-summaries-first.json`
and `summary-updates-window-unsorted-first.json` in that fixture directory.
Use `--sponsored-legislation <path>` or `--cosponsored-legislation <path>` with
`member-c001136-sponsored-legislation-first.json` or
`member-l000174-cosponsored-legislation-discovery.json` to inspect bill and amendment rows.

`Examples/CongressBioguideDemo` validates every profile in a staged export directory. Prepare a
supplied official all-profile ZIP with `Scripts/prepare-bioguide.py`; provide the actual retrieval
instant and a new output directory. Refresh scheduling and snapshot promotion belong to the caller.
An optional `--congress <n> --body <type> [--job <name>] [--region <code>]` filter mode prints each
matching position's source Congress name and a matching-position count instead of validating the
whole directory.

`Examples/CongressHouseVotesDemo` reads a supplied House roll-call XML file, or uses `--live` on
Apple, and prints the published vote totals and any recognized legislation reference alongside the
question.

`Examples/CongressSenateVotesDemo` reads a supplied Senate XML vote, or uses `--live` on Apple,
and prints the recognized subject alongside the question.

## Products

| Product | Responsibility |
| --- | --- |
| SwiftCongressBioguide | Bounded supplied-file import, manifest and digest validation |
| SwiftCongressBioguideModels | Profiles, source service affiliations, and archive provenance |
| SwiftCongressData | Congress.gov execution, lazy traversal, and response capture |
| SwiftCongressDataModels | Portable records, source identities, requests, endpoints, and continuation validation |
| SwiftCongressHouseVotes | Bounded House index and roll-call retrieval |
| SwiftCongressHouseVotesModels | Independent HTML inventories, XML records, typed requests and endpoints |
| SwiftCongressSenateVotes | Bounded Senate inventory, vote, and current identity retrieval |
| SwiftCongressSenateVotesModels | Independent Senate XML records, source identities, requests and endpoints |

## Requirements

Swift tools 6.2, Swift 6, and iOS, macOS, tvOS, visionOS, or watchOS 26.
Linux and Android use the optional HTTPPortable trait and an injected transport.
No transport dependency is required to use a models product.

## Installation

No release exists yet. Add the package by URL, pinned to `main` since there is no tagged version:

```swift
.package(url: "https://github.com/KalebCooper/swift-congress.git", branch: "main")
```

On Linux or Android, enable the trait:

```swift
.package(
  url: "https://github.com/KalebCooper/swift-congress.git", branch: "main",
  traits: ["HTTPPortable"])
```

Or reference it as a local Swift package. Either way, select the required library products.
The HTTP SDKs require swifty-networking 1.3.1 or later.

## License

MIT. See [LICENSE](LICENSE). The package license does not grant rights to upstream portraits or
other separately restricted source assets. Recorded sources are attributed in fixture manifests.
