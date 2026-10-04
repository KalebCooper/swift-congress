# Bill association records

Decode related bills, legislative subjects, policy areas, and committee associations without a transport.

## Related bills and committee associations

```swift
let related = try JSONDecoder().decode(RelatedBillPage.self, from: recordedBytes)
for bill in related.items {
  print(bill.number)
  for relationship in bill.relationshipDetails ?? [] {
    print(relationship.identifiedBy ?? "", relationship.type ?? "")
  }
}
```

``RelatedBill`` retains the source integer number, open bill type and every
``BillRelationshipDetail``. Authorities such as CRS and House remain separate assertions.
Rows can repeat across pages. No symmetric edge, identical text, unique inventory, or automatic
graph traversal is inferred.

``BillCommitteePage`` retains ``BillCommittee`` records and their ordered
``BillCommitteeActivity`` arrays. Nested ``BillSubcommittee`` associations preserve their
own activities without fabricating the chamber and type absent from the recorded child.
Associations do not establish a committee profile, membership roster, or inferred parentage.
Published URLs remain metadata.

## Legislative subjects and policy area

```swift
let page = try JSONDecoder().decode(BillSubjectPage.self, from: recordedBytes)
print(page.policyArea?.name ?? "(not published on this page)")
for subject in page.items { print(subject.name) }
```

``BillSubjectPage/legislativeSubjects`` and ``BillSubjectPage/items`` contain only legislative
subjects. ``BillSubjectPage/policyArea`` is separate and may appear only on an initial page.
Names and update timestamps remain source strings, including historical vocabulary.
Encoding the page emits the original nested `subjects` object. Unknown fields, nulls,
missing values, order, and duplicates remain in `rawFields`.

Source subject counts include the policy-area record when present. The recorded six-record
page contains five legislative subjects and one policy area, followed at offset six by six
legislative subjects and no policy area. A recorded limit-one initial page contains only a
policy area and advances to offset one. The raw ``Pagination/count`` remains unchanged.
Only this built-in page uses that internal record count. Consumer collections on the same
URL still advance using their item count and cannot opt into this behavior.

``BillSubjectQuery`` supports modification windows and page bounds, with default limit 20,
maximum 250, and nonnegative offset. Dates are passed through without local interpretation.
Related bills and committee associations accept ordinary ``CongressQuery`` bounds.
None of these three routes adds a sort control.

## Evidence limits

Recorded complete chains cover related bills for 119/s/5, committee associations for
117/hr/3076, and subjects for 119/s/5. Subjects also include historical 93/hjres/1, empty
82/s/677, and a filtered policy-only terminal. The limit-one chain records only its first
two pages, not exhaustion. These samples establish neither historical completeness nor
a stable snapshot.
