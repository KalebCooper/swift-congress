# CRS report records

Decode exact CRS inventory and detail envelopes without changing provider metadata.

## Envelopes and records

``CRSReportPage`` decodes the case-sensitive `CRSReports` array as `reports`.
``CRSReportDetail`` decodes the case-sensitive `CRSReport` object as `report`.
Both preserve all original fields and request metadata. Each record requires the source
`id` and `title`; other metadata is optional and missing/null values remain absent
in typed accessors. Raw fields preserve explicit nulls and unknown keys.

``CRSReportSummary`` retains list `version`, while ``CRSReport`` retains detail
`currentVersion`. Do not equate them or infer a version-history endpoint. Publication
and update dates are unparsed source strings with different meanings. Status and
content type are open strings.

## Nested source metadata

- ``CRSReportAuthor`` retains the source author label.
- ``CRSReportFormat`` retains an open format label and its unchanged link.
- ``CRSReportRelatedMaterial`` projects uppercase source `URL` as `url` and keeps
  heterogeneous `number` values as ``JSONValue``. A law citation such as
  `"93-344"` is not coerced into a numeric bill identifier.
- ``CRSReportTopic`` retains the source topic label.

Related titles can be null and records can repeat; neither is repaired or removed.
Some report page links have no URL scheme. All URL fields remain source strings and
no linked document is downloaded by model decoding or SDK conveniences.

## Requests and continuation

``CRSReportIdentifier`` validates a safe path component without assuming an R-only
prefix or imposing a provider length limit. ``CRSReportQuery`` offers page bounds
and optional modification-window strings, without unsupported sorting.

Built-in inventory requests use ordinary ``CongressContinuation`` validation:
same origin, path, filters and page size, advancing offsets and consistent counts.
There is no CRS overrun exception. A source result can publish a date outside requested
bounds; dates are not reinterpreted or used to discard returned records.
