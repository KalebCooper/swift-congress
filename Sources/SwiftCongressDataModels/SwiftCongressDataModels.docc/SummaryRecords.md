# Decoding summary records

Decode Congress.gov summary JSON without a transport dependency.

```swift
import Foundation
import SwiftCongressDataModels

let versions = try JSONDecoder().decode(BillSummaryPage.self, from: data)
for summary in versions.summaries {
  print(summary.versionCode as Any, summary.text as Any)
}
```

Use ``BillSummaryPage`` for the bill summary route and ``BillSummaryUpdatePage`` for the
publication feed. Feed entries require the source's nested ``Bill`` and expose chamber and
last-summary-update fields. Per-bill entries contain no fabricated bill identity.

Both envelopes and records encode their original JSON fields, preserving unknown keys and explicit
nulls. Typed optional scalar accessors return nil for missing or null values; inspect `rawFields`
to distinguish them. Text is original HTML and version codes retain leading zeros and unknown
values. No stable summary identifier, parsed date, or latest-version selection is synthesized.

``SummaryQuery`` constructs the unscoped, Congress, or Congress-and-bill-type feed path with
optional date bounds and sort. Omitted date bounds retain the provider's recent-day default.
For backfills, specify a finite window; exhausting a default feed does not establish all-time
coverage. Query timestamps are preserved for provider-side validation.

Use ``CongressContinuation`` with the page and exact request endpoint when implementing your own
executor. Summary pages have no overrun allowance. Invalid continuation must be reported before
yielding the affected page; do not rewrite a malformed provider link.
