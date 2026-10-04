import Foundation
import SwiftCongressData
import SwiftCongressDataModels

// Offline: pass a recorded Congress.gov bill JSON path, a recorded member detail or member
// list page with --member/--members, a summary page with --summaries/--summary-updates,
// bill cosponsors with --cosponsors, law detail/inventory with --law/--laws, or text with --text.
// Associations use --committees/--related-bills/--subjects with a recorded page.
// Amendment lists/details use --amendments/--amendment.
// Committee directories/profiles use --committee-directory/--committee.
// CRS metadata uses --crs-report/--crs-reports with recorded detail/list envelopes.
// Live Apple lookup: pass --live and a key (bill route only).
@main
struct CongressDataDemo {
  static func main() async throws {
    let arguments = Array(CommandLine.arguments.dropFirst())
    if arguments.first == "--amendment" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let amendment = try JSONDecoder().decode(AmendmentDetail.self, from: bytes).amendment
      print("Amendment: \(amendment.congress) \(amendment.type.rawValue) \(amendment.number)")
      print("Purpose: \(amendment.purpose ?? "unknown")")
      print("Description: \(amendment.description ?? "unknown")")
      if let bill = amendment.amendedBill {
        print("Bill: \(bill.congress) \(bill.type.rawValue) \(bill.number)")
      }
      if let target = amendment.amendedAmendment {
        print("Amendment target: \(target.congress) \(target.type.rawValue) \(target.number)")
      }
      if let treaty = amendment.amendedTreaty {
        print("Treaty: \(treaty.congress) \(treaty.treatyNumber)")
      }
    } else if arguments.first == "--amendments" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(AmendmentPage.self, from: bytes)
      print("Amendments: \(page.items.count)")
      for amendment in page.items {
        print(
          "\(amendment.congress) \(amendment.type.rawValue) \(amendment.number) | purpose: \(amendment.purpose ?? "unknown") | description: \(amendment.description ?? "unknown") | updated: \(amendment.updateDate ?? "unknown")"
        )
      }
      print("Source count: \(page.pagination.count)")
    } else if arguments.first == "--committee" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let profile = try JSONDecoder().decode(CommitteeDetail.self, from: bytes).committee
      print("systemCode \(profile.systemCode), type \(profile.type ?? "-")")
      print(
        "isCurrent \(profile.isCurrent.map(String.init) ?? "-"), updateDate \(profile.updateDate ?? "-")"
      )
      print(
        "parent \(profile.parent?.systemCode ?? "-"), subcommittees.count \(profile.subcommittees?.count ?? 0)"
      )
      for history in profile.history ?? [] {
        print("history officialName \(history.officialName ?? "-")")
        print("  startDate \(history.startDate ?? "-"), endDate \(history.endDate ?? "-")")
      }
      print(
        "bills.count \(profile.bills?.count.map(String.init) ?? "-"), communications.count \(profile.communications?.count.map(String.init) ?? "-")"
      )
      print(
        "nominations.count \(profile.nominations?.count.map(String.init) ?? "-"), reports.count \(profile.reports?.count.map(String.init) ?? "-")"
      )
    } else if arguments.first == "--committee-bills" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(CommitteeBillPage.self, from: bytes)
      print("pagination.count \(page.pagination.count), committee-bills.count \(page.count)")
      print("committee-bills.url \(page.url)")
      for bill in page.items {
        print("bill \(bill.congress)/\(bill.type.rawValue)/\(bill.number)")
        print(
          "relationshipType \(bill.relationshipType ?? "-"), actionDate \(bill.actionDate ?? "-")")
        print("updateDate \(bill.updateDate ?? "-"), url \(bill.url ?? "-")")
      }
    } else if arguments.first == "--committee-directory" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(CommitteePage.self, from: bytes)
      print("pagination.count \(page.pagination.count)")
      for committee in page.items {
        print("systemCode \(committee.systemCode), name \(committee.name ?? "-")")
        print("chamber \(committee.chamber ?? "-"), type \(committee.committeeTypeCode ?? "-")")
        print(
          "parent \(committee.parent?.systemCode ?? "-"), subcommittees.count \(committee.subcommittees?.count ?? 0)"
        )
      }
    } else if arguments.first == "--committee-house-communications" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(CommitteeHouseCommunicationPage.self, from: bytes)
      print("Committee House communications: \(page.items.count)")
      for communication in page.items {
        print(
          "\(communication.congress) \(communication.number) | type: \(communication.communicationType.code) | name: \(communication.communicationType.name ?? "unknown") | chamber: \(communication.chamber ?? "unknown") | referred: \(communication.referralDate ?? "unknown") | updated: \(communication.updateDate ?? "unknown") | url: \(communication.url ?? "unknown")"
        )
      }
      print("Source count: \(page.pagination.count)")
    } else if arguments.first == "--committee-nominations" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(CommitteeNominationPage.self, from: bytes)
      print("Committee nominations: \(page.items.count)")
      for nomination in page.items {
        print(
          "\(nomination.congress) \(nomination.number) | part: \(nomination.partNumber) | citation: \(nomination.citation ?? "unknown") | received: \(nomination.receivedDate ?? "unknown") | updated: \(nomination.updateDate ?? "unknown") | url: \(nomination.url ?? "unknown")"
        )
      }
      print("Source count: \(page.pagination.count)")
    } else if arguments.first == "--committee-report" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let detail = try JSONDecoder().decode(CommitteeReportDetail.self, from: bytes)
      print("Committee report parts: \(detail.committeeReports.count)")
      for part in detail.committeeReports {
        print(
          "\(part.congress) \(part.type) \(part.number) | part: \(part.part.map(String.init) ?? "unknown") | citation: \(part.citation ?? "unknown") | title: \(part.title ?? "unknown") | conference: \(part.isConferenceReport.map(String.init) ?? "unknown")"
        )
        for bill in part.associatedBill ?? [] {
          print("  bill: \(bill.congress) \(bill.type) \(bill.number)")
        }
        for treaty in part.associatedTreaties ?? [] {
          print("  treaty: \(treaty.congress) \(treaty.number) | part: \(treaty.part ?? "unknown")")
        }
      }
    } else if arguments.first == "--committee-report-references"
      || arguments.first == "--committee-reports"
    {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(CommitteeReportPage.self, from: bytes)
      print("Committee reports: \(page.items.count)")
      for report in page.items {
        print(
          "\(report.congress) \(report.type) \(report.number) | part: \(report.part.map(String.init) ?? "unknown") | citation: \(report.citation ?? "unknown") | chamber: \(report.chamber ?? "unknown") | updated: \(report.updateDate ?? "unknown") | url: \(report.url ?? "unknown")"
        )
      }
      print("Source count: \(page.pagination.count)")
    } else if arguments.first == "--committee-report-text" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(CommitteeReportTextPage.self, from: bytes)
      print("Committee report text versions: \(page.items.count)")
      for version in page.items {
        print("Formats: \(version.formats?.count ?? 0)")
        for format in version.formats ?? [] {
          print(
            "\(format.type ?? "unknown") | errata: \(format.isErrata ?? "unknown") | url: \(format.url ?? "unknown")"
          )
        }
      }
      print("Source count: \(page.pagination.count)")
    } else if arguments.first == "--committee-senate-communications" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(CommitteeSenateCommunicationPage.self, from: bytes)
      print("Committee Senate communications: \(page.items.count)")
      for communication in page.items {
        print(
          "\(communication.congress) \(communication.number) | type: \(communication.communicationType.code) | name: \(communication.communicationType.name ?? "unknown") | chamber: \(communication.chamber ?? "unknown") | referred: \(communication.referralDate ?? "unknown") | updated: \(communication.updateDate ?? "unknown") | url: \(communication.url ?? "unknown")"
        )
      }
      print("Source count: \(page.pagination.count)")
    } else if arguments.first == "--committees" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(BillCommitteePage.self, from: bytes)
      print("pagination.count \(page.pagination.count)")
      for committee in page.items {
        print("committee \(committee.systemCode ?? "-"), name \(committee.name ?? "-")")
        print("chamber \(committee.chamber ?? "-"), type \(committee.type ?? "-")")
        for activity in committee.activities ?? [] {
          print("  activity \(activity.name ?? "-"), date \(activity.date ?? "-")")
        }
        for subcommittee in committee.subcommittees ?? [] {
          print(
            "  subcommittee \(subcommittee.systemCode ?? "-"), name \(subcommittee.name ?? "-")")
          for activity in subcommittee.activities ?? [] {
            print("    activity \(activity.name ?? "-"), date \(activity.date ?? "-")")
          }
        }
      }
    } else if arguments.first == "--cosponsored-legislation" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(CosponsoredLegislationPage.self, from: bytes)
      print("pagination.count \(page.pagination.count)")
      for record in page.items { printLegislation(record) }
    } else if arguments.first == "--cosponsors" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(BillCosponsorPage.self, from: bytes)
      print("pagination.count \(page.pagination.count)")
      print(
        "countIncludingWithdrawnCosponsors \(page.countIncludingWithdrawnCosponsors.map(String.init) ?? "-")"
      )
      for record in page.items {
        print("bioguideId \(record.bioguideId), fullName \(record.fullName ?? "-")")
        print(
          "district \(record.district.map(String.init) ?? "-"), isOriginalCosponsor \(record.isOriginalCosponsor.map(String.init) ?? "-")"
        )
        print(
          "sponsorshipDate \(record.sponsorshipDate ?? "-"), sponsorshipWithdrawnDate \(record.sponsorshipWithdrawnDate ?? "-")"
        )
      }
    } else if arguments.first == "--crs-report" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let report = try JSONDecoder().decode(CRSReportDetail.self, from: bytes).report
      print("id \(report.id), title \(report.title)")
      print("status \(report.status ?? "-"), contentType \(report.contentType ?? "-")")
      print("currentVersion \(report.currentVersion.map(String.init) ?? "-")")
      print("publishDate \(report.publishDate ?? "-"), updateDate \(report.updateDate ?? "-")")
      for author in report.authors ?? [] { print("author \(author.author ?? "-")") }
      for format in report.formats ?? [] {
        print("format \(format.format ?? "-"), url \(format.url ?? "-")")
      }
      for topic in report.topics ?? [] { print("topic \(topic.topic ?? "-")") }
      print("relatedMaterials.count \(report.relatedMaterials?.count ?? 0)")
    } else if arguments.first == "--crs-reports" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(CRSReportPage.self, from: bytes)
      print("pagination.count \(page.pagination.count)")
      for report in page.items {
        print("id \(report.id), title \(report.title)")
        print("status \(report.status ?? "-"), contentType \(report.contentType ?? "-")")
        print("version \(report.version.map(String.init) ?? "-")")
        print("publishDate \(report.publishDate ?? "-"), updateDate \(report.updateDate ?? "-")")
      }
    } else if arguments.first == "--law" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let detail = try JSONDecoder().decode(BillDetail.self, from: bytes)
      printLawBill(detail.bill)
    } else if arguments.first == "--laws" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(BillPage.self, from: bytes)
      print("pagination.count \(page.pagination.count)")
      for bill in page.bills { printLawBill(bill) }
    } else if arguments.first == "--live" {
      #if canImport(Darwin)
      guard arguments.count == 2 else { throw DemoError.arguments }
      let client = CongressDataClient(apiKey: arguments[1], userAgent: "CongressDataDemo/1.0")
      let detail = try await client.bill(
        BillSourceIdentifier(congress: 6, number: "1", type: .houseBill))
      print(detail.bill.title)
      #else
      throw DemoError.arguments
      #endif
    } else if arguments.first == "--member" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let detail = try JSONDecoder().decode(MemberDetail.self, from: bytes)
      printMember(detail.member)
    } else if arguments.first == "--members" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(MemberPage.self, from: bytes)
      print("pagination.count \(page.pagination.count)")
      for member in page.members {
        print("bioguideId \(member.bioguideId), name \(member.name)")
        for term in member.terms ?? [] {
          print(
            "  term chamber=\(term.chamber ?? "-") startYear=\(term.startYear.map(String.init) ?? "-") endYear=\(term.endYear.map(String.init) ?? "-")"
          )
        }
      }
    } else if arguments.first == "--related-bills" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(RelatedBillPage.self, from: bytes)
      print("pagination.count \(page.pagination.count)")
      for bill in page.items {
        print("bill \(bill.congress)/\(bill.type ?? "-")/\(bill.number)")
        print(bill.title ?? "(no source title)")
        for relationship in bill.relationshipDetails ?? [] {
          print(
            "  identifiedBy \(relationship.identifiedBy ?? "-"), type \(relationship.type ?? "-")")
        }
      }
    } else if arguments.first == "--sponsored-legislation" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(SponsoredLegislationPage.self, from: bytes)
      print("pagination.count \(page.pagination.count)")
      for record in page.items { printLegislation(record) }
    } else if arguments.first == "--subjects" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(BillSubjectPage.self, from: bytes)
      print("pagination.count \(page.pagination.count)")
      print(
        "policyArea \(page.policyArea?.name ?? "-"), updateDate \(page.policyArea?.updateDate ?? "-")"
      )
      for subject in page.items {
        print("subject \(subject.name), updateDate \(subject.updateDate ?? "-")")
      }
    } else if arguments.first == "--summaries" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(BillSummaryPage.self, from: bytes)
      print("pagination.count \(page.pagination.count)")
      for summary in page.summaries {
        print("versionCode \(summary.versionCode ?? "-"), actionDate \(summary.actionDate ?? "-")")
        print(summary.text ?? "(none)")
      }
    } else if arguments.first == "--summary-updates" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(BillSummaryUpdatePage.self, from: bytes)
      print("pagination.count \(page.pagination.count)")
      for summary in page.summaries {
        print("bill \(summary.bill.congress)/\(summary.bill.type.rawValue)/\(summary.bill.number)")
        print(
          "versionCode \(summary.versionCode ?? "-"), lastSummaryUpdateDate \(summary.lastSummaryUpdateDate ?? "-")"
        )
        print(summary.text ?? "(none)")
      }
    } else if arguments.first == "--text" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(BillTextVersionPage.self, from: bytes)
      print("pagination.count \(page.pagination.count)")
      for version in page.textVersions {
        print("type \(version.type ?? "-"), date \(version.date ?? "(none)")")
        for format in version.formats ?? [] {
          print("  format type=\(format.type ?? "-") url=\(format.url ?? "-")")
        }
      }
    } else {
      guard arguments.count == 1 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[0]))
      let detail = try JSONDecoder().decode(BillDetail.self, from: bytes)
      print(
        "Congress \(detail.bill.congress), source \(detail.bill.type.rawValue) \(detail.bill.number)"
      )
      print(detail.bill.title)
    }
  }

  static func printLawBill(_ bill: Bill) {
    print("bill \(bill.congress)/\(bill.type.rawValue)/\(bill.number)")
    print(bill.title)
    for law in bill.laws ?? [] {
      print("law number \(law.number ?? "-"), type \(law.type ?? "-")")
    }
  }

  static func printLegislation(_ record: MemberLegislation) {
    print(
      "congress \(record.congress), type \(record.type ?? "-"), number \(record.number ?? "-"), amendmentNumber \(record.amendmentNumber ?? "-")"
    )
    print(record.title ?? "(no source title)")
    print("introducedDate \(record.introducedDate ?? "-"), url \(record.url ?? "-")")
  }

  static func printMember(_ member: MemberProfile) {
    print("bioguideId \(member.bioguideId)")
    print("directOrderName \(member.directOrderName ?? "-")")
    print("currentMember \(member.currentMember.map(String.init) ?? "-")")
    for term in member.terms ?? [] {
      print(
        "  term congress=\(term.congress.map(String.init) ?? "-") chamber=\(term.chamber ?? "-") district=\(term.district.map(String.init) ?? "-")"
      )
    }
    for key in ["addressInformation", "leadership", "partyHistory", "previousNames"] {
      print("  rawFields[\(key)] present: \(member.rawFields[key] != nil)")
    }
  }

  enum DemoError: Error {
    case arguments
  }
}
