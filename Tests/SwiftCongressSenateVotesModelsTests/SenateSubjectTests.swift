import Foundation
import SwiftCongressSenateVotesModels
import SwiftCongressSenateVotesTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct SenateSubjectTests {
  @Test("A historical nomination keeps its raw number and missing Congress")
  func aHistoricalNominationKeepsItsRawNumberAndMissingCongress() throws {
    let rollCall = try decode(.senate1989)
    guard case .nomination(let nomination)? = rollCall.subject else {
      Issue.record("expected a nomination, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(nomination.number == "128")
    #expect(nomination.document.congress == nil)
    #expect(nomination.document.type == "PN")
    #expect(nomination.document.name == "PN128")
    #expect(nomination.document.shortTitle == "")
    #expect(
      nomination.document.title == "James Addison Baker, III, of Texas, to be Secretary of State")
    #expect(nomination.document.rawNode == rollCall.document)
    #expect(rollCall.amendment?.child("amendment_number")?.text == "")
    #expect(rollCall.question == "On the Nomination")
  }

  @Test("A modern amendment reads its target bill and keeps the top-level document")
  func aModernAmendmentReadsItsTargetBillAndKeepsTheTopLevelDocument() throws {
    let rollCall = try decode(.senate2026)
    guard case .amendment(let amendment)? = rollCall.subject else {
      Issue.record("expected an amendment, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(amendment.number == "S.Amdt. 6776")
    #expect(amendment.targetDocumentNumber == "S. 4668")
    #expect(amendment.target == .bill(.senateBill, number: "4668"))
    #expect(amendment.targetAmendmentNumber == "")
    #expect(amendment.targetAmendmentTargetNumber == "")
    #expect(amendment.targetDocumentShortTitle == "No short title on file")
    #expect(amendment.purpose == "In the nature of a substitute.")
    #expect(amendment.rawNode == rollCall.amendment)
    #expect(amendment.document?.type == "S.Amdt.")
    #expect(amendment.document?.congress == "119")
    #expect(amendment.document?.number == "")
    #expect(rollCall.question == "On the Cloture Motion")
  }

  @Test("A bill vote recognizes the House bill code and keeps every document field")
  func aBillVoteRecognizesTheHouseBillCodeAndKeepsEveryDocumentField() throws {
    let rollCall = try decode(.senate2010_bill)
    guard case .bill(let bill)? = rollCall.subject else {
      Issue.record("expected a bill, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(bill.measureType == .houseBill)
    #expect(bill.number == "3082")
    #expect(bill.document.congress == "111")
    #expect(bill.document.name == "H.R. 3082")
    #expect(
      bill.document.shortTitle
        == "Military Construction and Veterans Affairs and Related Agencies Appropriations Act, 2010"
    )
    #expect(bill.document.title?.hasPrefix("A bill making appropriations") == true)
    #expect(rollCall.question == "On the Motion")
  }

  @Test("A treaty vote keeps its compound number and ignores an empty amendment container")
  func aTreatyVoteKeepsItsCompoundNumberAndIgnoresAnEmptyAmendmentContainer() throws {
    let rollCall = try decode(.senate2010_treaty)
    guard case .treaty(let treaty)? = rollCall.subject else {
      Issue.record("expected a treaty, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(treaty.number == "111-5")
    #expect(treaty.document.type == "Treaty Doc.")
    #expect(treaty.document.congress == "111")
    #expect(treaty.document.name == "Treaty Doc. 111-5")
    #expect(rollCall.amendment?.child("amendment_number")?.text == "")
    #expect(rollCall.amendment?.child("amendment_to_document_number")?.text == "")
    #expect(rollCall.question == "On the Resolution of Ratification")
  }

  @Test("A treaty amendment recognizes its treaty target and its empty document")
  func aTreatyAmendmentRecognizesItsTreatyTargetAndItsEmptyDocument() throws {
    let rollCall = try decode(.senate2010_treatyAmendment)
    guard case .amendment(let amendment)? = rollCall.subject else {
      Issue.record("expected an amendment, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(amendment.number == "S.Amdt. 4893")
    #expect(amendment.targetDocumentNumber == "Treaty Doc. 111-5")
    #expect(amendment.target == .treaty(number: "111-5"))
    // These elements are absent from the 2010 record, unlike the empty ones of 1989 and 2026.
    #expect(amendment.targetAmendmentNumber == nil)
    #expect(amendment.targetAmendmentTargetNumber == nil)
    #expect(amendment.targetDocumentShortTitle == nil)
    #expect(amendment.purpose?.hasPrefix("To provide that the advice and consent") == true)
    #expect(amendment.document?.type == "")
    #expect(amendment.document?.number == "")
    #expect(amendment.document?.congress == "111")
    #expect(rollCall.question == "On the Amendment")
  }

  @Test("An empty document yields no subject")
  func anEmptyDocumentYieldsNoSubject() throws {
    // Test-authored mutation of the 2010 vote 289 fixture: every document field is emptied and the
    // Congress is kept.
    let emptied = try decode(.senate2010_bill, replacing: emptyDocumentFields)
    #expect(emptied.subject == nil)
    #expect(emptied.document?.child("document_congress")?.text == "111")
    // Test-authored mutation of the 2010 vote 289 fixture: the document and amendment elements are
    // removed entirely.
    let removed = try decode(.senate2010_bill, removing: ["document", "amendment"])
    #expect(removed.document == nil)
    #expect(removed.amendment == nil)
    #expect(removed.subject == nil)
  }

  @Test("A whitespace amendment number still selects an amendment")
  func aWhitespaceAmendmentNumberStillSelectsAnAmendment() throws {
    // Test-authored mutation of the 2010 vote 289 fixture: amendment_number holds one space.
    let rollCall = try decode(
      .senate2010_bill,
      replacing: [("<amendment_number/>", "<amendment_number> </amendment_number>")])
    guard case .amendment(let amendment)? = rollCall.subject else {
      Issue.record("expected an amendment, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(amendment.number == " ")
    #expect(amendment.target == nil)
    #expect(amendment.targetDocumentNumber == "")
    #expect(amendment.document?.type == "H.R.")
  }

  @Test("An amendment type without an amendment number is unknown")
  func anAmendmentTypeWithoutAnAmendmentNumberIsUnknown() throws {
    // Test-authored mutation of the 2010 vote 289 fixture: document_type becomes S.Amdt. while
    // amendment_number stays empty.
    let rollCall = try decode(
      .senate2010_bill,
      replacing: [("<document_type>H.R.</document_type>", "<document_type>S.Amdt.</document_type>")]
    )
    guard case .unknown(let unknown)? = rollCall.subject else {
      Issue.record("expected unknown, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(unknown.reason == .amendmentNumberMissing)
    #expect(unknown.document?.type == "S.Amdt.")
    #expect(unknown.document?.number == "3082")
    #expect(unknown.amendment == rollCall.amendment)
  }

  @Test("A number without a document type is unknown")
  func aNumberWithoutADocumentTypeIsUnknown() throws {
    // Test-authored mutation of the 2010 vote 289 fixture: document_type is emptied, then removed.
    for replacement in ["<document_type/>", ""] {
      let rollCall = try decode(
        .senate2010_bill, replacing: [("<document_type>H.R.</document_type>", replacement)])
      guard case .unknown(let unknown)? = rollCall.subject else {
        Issue.record("expected unknown, got \(String(describing: rollCall.subject))")
        return
      }
      #expect(unknown.reason == .documentTypeMissing)
      #expect(unknown.document?.type == (replacement.isEmpty ? nil : ""))
      #expect(unknown.document?.number == "3082")
      #expect(unknown.document?.name == "H.R. 3082")
    }
  }

  @Test("Target fields without an amendment number are unknown")
  func targetFieldsWithoutAnAmendmentNumberAreUnknown() throws {
    // Test-authored mutation of the 2010 vote 289 fixture: every document field is emptied and
    // amendment_to_document_number names the bill while amendment_number stays empty.
    let rollCall = try decode(
      .senate2010_bill,
      replacing: emptyDocumentFields + [
        (
          "<amendment_to_document_number/>",
          "<amendment_to_document_number>H.R. 3082</amendment_to_document_number>"
        )
      ])
    guard case .unknown(let unknown)? = rollCall.subject else {
      Issue.record("expected unknown, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(unknown.reason == .amendmentNumberMissing)
    #expect(unknown.document?.type == "")
    #expect(unknown.amendment?.child("amendment_to_document_number")?.text == "H.R. 3082")
  }

  @Test("A typed document with target fields and no amendment number is that document's subject")
  func aTypedDocumentWithTargetFieldsAndNoAmendmentNumberIsThatDocumentsSubject() throws {
    // Test-authored mutation of the 2010 vote 289 fixture: amendment_to_document_number names the
    // bill while amendment_number and the document stay unchanged.
    let rollCall = try decode(
      .senate2010_bill,
      replacing: [
        (
          "<amendment_to_document_number/>",
          "<amendment_to_document_number>H.R. 3082</amendment_to_document_number>"
        )
      ])
    guard case .bill(let bill)? = rollCall.subject else {
      Issue.record("expected a bill, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(bill.measureType == .houseBill)
    #expect(bill.number == "3082")
  }

  @Test("An absent document still lets an amendment number select the amendment")
  func anAbsentDocumentStillLetsAnAmendmentNumberSelectTheAmendment() throws {
    // Test-authored mutation of the 2010 vote 289 fixture: document is removed and amendment_number
    // holds a value.
    let rollCall = try decode(
      .senate2010_bill, removing: ["document"],
      replacing: [("<amendment_number/>", "<amendment_number>S.Amdt. 1</amendment_number>")])
    guard case .amendment(let amendment)? = rollCall.subject else {
      Issue.record("expected an amendment, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(amendment.document == nil)
  }

  @Test("An absent amendment with an amendment-type document is unknown")
  func anAbsentAmendmentWithAnAmendmentTypeDocumentIsUnknown() throws {
    // Test-authored mutation of the 2010 vote 289 fixture: amendment is removed and document_type
    // becomes S.Amdt.
    let rollCall = try decode(
      .senate2010_bill, removing: ["amendment"],
      replacing: [
        ("<document_type>H.R.</document_type>", "<document_type>S.Amdt.</document_type>")
      ])
    guard case .unknown(let unknown)? = rollCall.subject else {
      Issue.record("expected unknown, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(unknown.reason == .amendmentNumberMissing)
    #expect(unknown.amendment == nil)
  }

  @Test("A whitespace document type is unrecognized")
  func aWhitespaceDocumentTypeIsUnrecognized() throws {
    // Test-authored mutation of the 2010 vote 289 fixture: document_type holds one space.
    let rollCall = try decode(
      .senate2010_bill,
      replacing: [("<document_type>H.R.</document_type>", "<document_type> </document_type>")])
    guard case .unknown(let unknown)? = rollCall.subject else {
      Issue.record("expected unknown, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(unknown.reason == .documentTypeUnrecognized)
    #expect(unknown.document?.type == " ")
  }

  @Test("An unrecognized document code is unknown and keeps its nodes")
  func anUnrecognizedDocumentCodeIsUnknownAndKeepsItsNodes() throws {
    // Test-authored mutation of the 2010 vote 289 fixture: document_type becomes S.Doc.
    let rollCall = try decode(
      .senate2010_bill,
      replacing: [("<document_type>H.R.</document_type>", "<document_type>S.Doc.</document_type>")])
    guard case .unknown(let unknown)? = rollCall.subject else {
      Issue.record("expected unknown, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(unknown.reason == .documentTypeUnrecognized)
    #expect(unknown.document?.type == "S.Doc.")
    #expect(unknown.document?.number == "3082")
    #expect(unknown.document?.rawNode == rollCall.document)
    #expect(unknown.amendment == rollCall.amendment)
  }

  @Test("A nomination with an empty number stays a nomination")
  func aNominationWithAnEmptyNumberStaysANomination() throws {
    // Test-authored mutation of the 1989 vote 1 fixture: document_number is emptied.
    let rollCall = try decode(
      .senate1989, replacing: [("<document_number>128</document_number>", "<document_number/>")])
    guard case .nomination(let nomination)? = rollCall.subject else {
      Issue.record("expected a nomination, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(nomination.number == "")
    #expect(nomination.document.name == "PN128")
  }

  @Test(
    "Target labels are read exactly and never normalized",
    arguments: [
      ("H.J.Res. 12", SenateAmendmentTarget.bill(.houseJointResolution, number: "12")),
      ("S.Con.Res. 7", .bill(.senateConcurrentResolution, number: "7")),
      ("Treaty Doc. 111-5", .treaty(number: "111-5")),
      ("Treaty Doc. 99-2A", .treaty(number: "99-2A")),
      ("Treaty Doc. ", .unknown(label: "Treaty Doc. ")),
      ("Treaty Doc.", .unknown(label: "Treaty Doc.")),
      ("H.R. 0123", .unknown(label: "H.R. 0123")),
      ("H.R. 12a", .unknown(label: "H.R. 12a")),
      ("H.R.  12", .unknown(label: "H.R.  12")),
      ("h.r. 12", .unknown(label: "h.r. 12")),
      ("H R 12", .unknown(label: "H R 12")),
      ("S.Amdt. 1", .unknown(label: "S.Amdt. 1")),
      ("S.", .unknown(label: "S.")),
      ("PN 128", .unknown(label: "PN 128")),
      (" S. 4668", .unknown(label: " S. 4668")),
      ("S. 4668 ", .unknown(label: "S. 4668 ")),
    ])
  func targetLabelsAreReadExactlyAndNeverNormalized(
    label: String, expected: SenateAmendmentTarget
  ) throws {
    // Test-authored mutation of the 2026 vote 240 fixture: the target label text is replaced.
    let rollCall = try decode(
      .senate2026,
      replacing: [
        (
          "<amendment_to_document_number>S. 4668</amendment_to_document_number>",
          "<amendment_to_document_number>\(label)</amendment_to_document_number>"
        )
      ])
    guard case .amendment(let amendment)? = rollCall.subject else {
      Issue.record("expected an amendment, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(amendment.target == expected)
    #expect(amendment.targetDocumentNumber == label)
  }

  @Test("An empty target label has no reading")
  func anEmptyTargetLabelHasNoReading() throws {
    // Test-authored mutation of the 2026 vote 240 fixture: the target label is emptied.
    let rollCall = try decode(
      .senate2026,
      replacing: [
        (
          "<amendment_to_document_number>S. 4668</amendment_to_document_number>",
          "<amendment_to_document_number/>"
        )
      ])
    guard case .amendment(let amendment)? = rollCall.subject else {
      Issue.record("expected an amendment, got \(String(describing: rollCall.subject))")
      return
    }
    #expect(amendment.target == nil)
    #expect(amendment.targetDocumentNumber == "")
  }

  @Test("Reading the subject leaves stored values and encoding unchanged")
  func readingTheSubjectLeavesStoredValuesAndEncodingUnchanged() throws {
    let rollCall = try decode(.senate2010_bill)
    #expect(rollCall.subject != nil)
    #expect(rollCall.document?.child("document_type")?.text == "H.R.")
    #expect(rollCall.document?.child("document_number")?.text == "3082")
    #expect(rollCall.amendment?.child("amendment_number")?.text == "")
    #expect(rollCall.title?.hasSuffix("to H.R. 3082") == true)
    #expect(rollCall.rawNode.child("document") == rollCall.document)
    let encoded = try JSONEncoder().encode(rollCall)
    let object = try #require(try JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    #expect(object.keys.contains("document"))
    #expect(object.keys.contains("amendment"))
    #expect(!object.keys.contains("subject"))
    #expect(try JSONDecoder().decode(SenateRollCall.self, from: encoded) == rollCall)
  }

  @Test("Measure types compare by their published code")
  func measureTypesCompareByTheirPublishedCode() {
    #expect(SenateMeasureType(rawValue: "H.R.") == .houseBill)
    #expect(SenateMeasureType(rawValue: "H R") != .houseBill)
    #expect(SenateMeasureType(rawValue: "S.Doc.").rawValue == "S.Doc.")
    #expect(
      SenateAmendmentTarget.bill(.senateBill, number: "1") != .bill(.senateResolution, number: "1"))
  }

  private var emptyDocumentFields: [(String, String)] {
    [
      ("<document_type>H.R.</document_type>", "<document_type/>"),
      ("<document_number>3082</document_number>", "<document_number/>"),
      ("<document_name>H.R. 3082</document_name>", "<document_name/>"),
      (
        "<document_title>A bill making appropriations for military construction, the Department "
          + "of Veterans Affairs, and related agencies for the fiscal year ending September 30, "
          + "2010, and for other purposes.</document_title>", "<document_title/>"
      ),
      (
        "<document_short_title>Military Construction and Veterans Affairs and Related Agencies "
          + "Appropriations Act, 2010</document_short_title>", "<document_short_title/>"
      ),
    ]
  }

  private func decode(_ fixture: Fixture) throws -> SenateRollCall {
    try SenateRollCall.decode(fixture.data(), sourceURL: sourceURL)
  }

  /// Applies each replacement once, requiring the original text to be present, so a mutation that
  /// no longer matches the fixture fails loudly instead of testing the unmodified file.
  private func decode(_ fixture: Fixture, replacing replacements: [(String, String)]) throws
    -> SenateRollCall
  {
    var text = try #require(String(data: fixture.data(), encoding: .utf8))
    for (original, replacement) in replacements {
      let range = try #require(text.range(of: original))
      text.replaceSubrange(range, with: replacement)
    }
    return try SenateRollCall.decode(Data(text.utf8), sourceURL: sourceURL)
  }

  /// Removes each named element and its content, requiring both tags to be present.
  private func decode(_ fixture: Fixture, removing elements: [String]) throws -> SenateRollCall {
    var text = try #require(String(data: fixture.data(), encoding: .utf8))
    for element in elements {
      let start = try #require(text.range(of: "<\(element)>"))
      let end = try #require(text.range(of: "</\(element)>"))
      text.replaceSubrange(start.lowerBound..<end.upperBound, with: "")
    }
    return try SenateRollCall.decode(Data(text.utf8), sourceURL: sourceURL)
  }

  /// Removes each named element, then applies each replacement, requiring every tag and original
  /// text to be present.
  private func decode(
    _ fixture: Fixture, removing elements: [String], replacing replacements: [(String, String)]
  ) throws -> SenateRollCall {
    var text = try #require(String(data: fixture.data(), encoding: .utf8))
    for element in elements {
      let start = try #require(text.range(of: "<\(element)>"))
      let end = try #require(text.range(of: "</\(element)>"))
      text.replaceSubrange(start.lowerBound..<end.upperBound, with: "")
    }
    for (original, replacement) in replacements {
      let range = try #require(text.range(of: original))
      text.replaceSubrange(range, with: replacement)
    }
    return try SenateRollCall.decode(Data(text.utf8), sourceURL: sourceURL)
  }

  private var sourceURL: URL {
    get throws {
      try #require(
        URL(
          string:
            "https://www.senate.gov/legislative/LIS/roll_call_votes/vote1112/vote_111_2_00289.xml"))
    }
  }
}
