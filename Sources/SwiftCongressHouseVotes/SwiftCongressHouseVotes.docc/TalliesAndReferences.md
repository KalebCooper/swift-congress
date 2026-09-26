# Reading vote tallies and legislation references

Read a roll call's published totals and its measure label directly from the same document,
with no separate request and no join to another service.

## Read the published totals

```swift
let vote = try await client.rollCall(number: 314, year: 2026)
if let tallies = vote.tallies {
  for row in tallies.byParty {
    print(row.party ?? "unlabeled", row.counts.yea?.rawValue ?? "no yea-total")
  }
  for row in tallies.byVote {
    for count in row.counts {
      print(count.name, count.value.map(String.init) ?? "raw: \(count.rawValue)")
    }
  }
}
```

`HouseRollCall.tallies` reads the same `vote-metadata/vote-totals` element already retained in
`rawNode`; nothing is fetched again and nothing is recomputed from voter rows. `byParty` and
`byVote` appear on an ordinary roll call; an election of the Speaker instead publishes
`byCandidate` rows, whose labels can be a person's name or a literal `Present`/`Not Voting`
count, not a member vote. These are chamber proceedings, not campaign data, and a row's absence
from one array is not evidence it was never published: check `HouseVoteTallies.rawNode` for
headers and any row kind this projection does not type. Every `HouseTallyCount` keeps the
Clerk's exact text in `rawValue` beside a `value` that parses only a complete nonnegative decimal;
an unparsed count is not silently dropped.

## Recognize a legislation label

```swift
if let reference = vote.legislationReference {
  print(reference.rawValue)
  if let measure = reference.measure {
    print(measure.measureType.rawValue, measure.number, "in Congress", measure.congress)
  }
}
```

`HouseRollCall.legislationReference` wraps the same `legis-num` label already retained in
`legislation`. `HouseLegislationReference.measure` is set only for one of the eight anchored
`HouseMeasureType` forms this projection recognizes, patterned on the two observed in recorded
Clerk files (`S 2403`, `H R 2190`) and the eight kinds the Clerk's DTD lists, spelled with a
single space and a decimal number with no leading zero. A procedural label such as `QUORUM 1`, an
empty label, and the Clerk's own dotted spellings (`H.R. 1514`) all keep their `rawValue` with a
nil `measure`.

## What a reference does not mean

A recognized `HouseMeasureReference` is evidence for a caller to consider, not a Congress.gov
bill identity: its `congress` is the roll call's own declared Congress, never looked up, and this
module performs no crosswalk to any other package or service. A caller that wants a Congress.gov
record still has to resolve one itself from the recognized fields.
