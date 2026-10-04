# ``SwiftCongressDataModels``

Portable Congress.gov records and immutable request descriptions.

## Overview

This product has no networking dependency. Execute an endpoint using your own
transport, send its encoded path to https://api.congress.gov with explicit
X-Api-Key and User-Agent headers, and decode its declared response using JSONDecoder.

```swift
let source = try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill)
let endpoint = Endpoint.bill(source)
let request = CongressRequest.bill(source)
```

Bill, Congress, action, member, relationship, subject, committee, CRS report, summary, text-version, and envelope models preserve every
original JSON field in rawFields. Encoding emits those original fields; typed
accessors do not replace unknown fields or turn missing/null dates into defaults.
Raw JSON numeric values use Foundation Decimal; use SDK receipts when exact source
bytes are required.

BillSourceIdentifier names a Congress.gov record, whose early number can be a
surrogate. BillIdentifier is restricted to numbered-bill eras and never accepts
an early source surrogate. Neither type establishes historical completeness.
Congress/session numbers are source facts, separate from Bioguide's predecessor
body namespaces. No automatic cross-provider identity joins are performed.

CongressContinuation validates count/offset progress and requires the next link
to retain origin, path, page size, and filters. Missing continuation for an
incomplete page is an error. Counts can change; no stable snapshot is promised.
Bill text-version pages alone may carry one record beyond the requested limit; see
``BillTextVersionPage``. Bill cosponsor pages use their separately published inclusive count
when present, preserving the active count; see <doc:CosponsorRecords>.
Subject pages count their policy-area record toward source offsets while exposing only
legislative items; see <doc:BillAssociationRecords>. Consumer collections keep ordinary item counts.

## Topics

### Records

- ``Amendment``
- ``AmendmentAction``
- ``AmendmentActionLink``
- ``AmendmentCosponsorResource``
- ``AmendmentDetail``
- ``AmendmentMember``
- ``AmendmentNote``
- ``AmendmentSummary``
- ``AmendmentTreaty``
- ``Bill``
- ``BillAction``
- ``BillCommittee``
- ``BillCommitteeActivity``
- ``BillCosponsor``
- ``BillDetail``
- ``BillLawReference``
- ``BillRelationshipDetail``
- ``BillSubcommittee``
- ``BillSubject``
- ``BillSummary``
- ``BillSummaryUpdate``
- ``BillTextFormat``
- ``BillTextVersion``
- ``CommitteeBill``
- ``CommitteeDetail``
- ``CommitteeHistory``
- ``CommitteeHouseCommunication``
- ``CommitteeHouseCommunicationType``
- ``CommitteeNomination``
- ``CommitteeNominationAction``
- ``CommitteeNominationType``
- ``CommitteeProfile``
- ``CommitteeReference``
- ``CommitteeReportBill``
- ``CommitteeReportDetail``
- ``CommitteeReportPart``
- ``CommitteeReportReference``
- ``CommitteeReportTextFormat``
- ``CommitteeReportTextVersion``
- ``CommitteeReportTreaty``
- ``CommitteeSenateCommunication``
- ``CommitteeSenateCommunicationType``
- ``CommitteeSummary``
- ``Congress``
- ``CongressSession``
- ``CRSReport``
- ``CRSReportAuthor``
- ``CRSReportDetail``
- ``CRSReportFormat``
- ``CRSReportRelatedMaterial``
- ``CRSReportSummary``
- ``CRSReportTopic``
- ``JSONValue``
- ``MemberDepiction``
- ``MemberDetail``
- ``MemberLegislation``
- ``MemberProfile``
- ``MemberSummary``
- ``MemberTerm``
- ``MemberTermSummary``
- ``RelatedBill``
- ``ResourceLink``

### Requests

- ``AmendmentIdentifier``
- ``AmendmentQuery``
- ``AmendmentType``
- ``BillAmendmentQuery``
- ``BillCosponsorQuery``
- ``BillIdentifier``
- ``BillQuery``
- ``BillSourceIdentifier``
- ``BillSubjectQuery``
- ``BillType``
- ``CommitteeBillQuery``
- ``CommitteeChamber``
- ``CommitteeIdentifier``
- ``CommitteeQuery``
- ``CommitteeReportIdentifier``
- ``CommitteeReportInventoryQuery``
- ``CommitteeReportQuery``
- ``CommitteeReportType``
- ``CongressInputError``
- ``CongressQuery``
- ``CongressRequest``
- ``CRSReportIdentifier``
- ``CRSReportQuery``
- ``Endpoint``
- ``LawIdentifier``
- ``LawQuery``
- ``LawType``
- ``MemberGeographyQuery``
- ``MemberIdentifier``
- ``MemberQuery``
- ``SummaryQuery``

### Pages and receipts

- ``AmendmentPage``
- ``BillActionPage``
- ``BillCommitteePage``
- ``BillCosponsorPage``
- ``BillPage``
- ``BillSubjectPage``
- ``BillSummaryPage``
- ``BillSummaryUpdatePage``
- ``BillTextVersionPage``
- ``CommitteeBillPage``
- ``CommitteeHouseCommunicationPage``
- ``CommitteeNominationPage``
- ``CommitteePage``
- ``CommitteeReportPage``
- ``CommitteeReportTextPage``
- ``CommitteeSenateCommunicationPage``
- ``CongressCollection``
- ``CongressContinuation``
- ``CongressPage``
- ``CongressPaginationError``
- ``CosponsoredLegislationPage``
- ``CRSReportPage``
- ``MemberPage``
- ``Pagination``
- ``RelatedBillPage``
- ``SourceHeader``
- ``SourceResponse``
- ``SponsoredLegislationPage``

### Amendment decoding

- <doc:AmendmentRecords>

### Bill association decoding

- <doc:BillAssociationRecords>

### Committee bill decoding

- <doc:CommitteeBillRecords>

### Committee directory decoding

- <doc:CommitteeRecords>

### Committee House communication decoding

- <doc:CommitteeHouseCommunicationRecords>

### Committee nomination decoding

- <doc:CommitteeNominationRecords>

### Committee report decoding

- <doc:CommitteeReportRecords>

### Committee report detail decoding

- <doc:CommitteeReportDetailRecords>

### Committee Senate communication decoding

- <doc:CommitteeSenateCommunicationRecords>

### Cosponsor decoding

- <doc:CosponsorRecords>

### CRS report decoding

- <doc:CRSReportRecords>

### Geographic member records

- <doc:GeographicMemberRecords>

### Law decoding

- <doc:LawRecords>

### Member legislation decoding

- <doc:MemberLegislationRecords>

### Summary decoding

- <doc:SummaryRecords>
