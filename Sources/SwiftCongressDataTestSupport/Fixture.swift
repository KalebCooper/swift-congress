// Bundle resource loading requires Foundation on portable platforms.
import Foundation

package enum Fixture: String {
  /// Recorded https://api.congress.gov/v3/bill/119/hr/1/actions?format=json&limit=250.
  case actions119 = "actions119.json"
  /// Recorded https://api.congress.gov/v3/amendment/114/samdt/5129?format=json.
  case amendment_114_samdt_5129_detail = "amendment-114-samdt-5129-detail.json"
  /// Recorded https://api.congress.gov/v3/amendment/116/samdt/946?format=json.
  case amendment_116_samdt_946_detail = "amendment-116-samdt-946-detail.json"
  /// Recorded https://api.congress.gov/v3/amendment/117/hamdt/173?format=json.
  case amendment_117_hamdt_173_detail = "amendment-117-hamdt-173-detail.json"
  /// Recorded https://api.congress.gov/v3/amendment/117?format=json&limit=2&offset=0.
  case amendment_117_inventory_first = "amendment-117-inventory-first.json"
  /// Recorded https://api.congress.gov/v3/amendment/117/samdt/2137?format=json.
  case amendment_117_samdt_2137_detail = "amendment-117-samdt-2137-detail.json"
  /// Recorded https://api.congress.gov/v3/amendment/117/samdt/2564?format=json.
  case amendment_117_samdt_2564_detail = "amendment-117-samdt-2564-detail.json"
  /// Recorded https://api.congress.gov/v3/amendment/97/suamdt/3?format=json.
  case amendment_97_suamdt_3_detail = "amendment-97-suamdt-3-detail.json"
  /// Recorded https://api.congress.gov/v3/amendment/97/suamdt?format=json&limit=2&offset=0.
  case amendment_97_suamdt_first = "amendment-97-suamdt-first.json"
  /// Recorded https://api.congress.gov/v3/amendment?format=json&limit=2&offset=0.
  case amendment_inventory_first = "amendment-inventory-first.json"
  /// Recorded bill117-hr3076-committees-first; exact request provenance is in manifest.json.
  case bill117_hr3076_committees_first = "bill117-hr3076-committees-first.json"
  /// Recorded bill117-hr3076-committees-terminal; exact request provenance is in manifest.json.
  case bill117_hr3076_committees_terminal = "bill117-hr3076-committees-terminal.json"
  /// Recorded https://api.congress.gov/v3/bill/117/s/3580/cosponsors?format=json&limit=15&offset=0.
  case bill117_s3580_cosponsors_first = "bill117-s3580-cosponsors-first.json"
  /// Recorded https://api.congress.gov/v3/bill/117/s/3580/cosponsors?offset=15&limit=15&format=json.
  case bill117_s3580_cosponsors_next = "bill117-s3580-cosponsors-next.json"
  /// Recorded https://api.congress.gov/v3/bill/117/s/3580/cosponsors?offset=30&limit=15&format=json.
  case bill117_s3580_cosponsors_terminal = "bill117-s3580-cosponsors-terminal.json"
  /// Recorded https://api.congress.gov/v3/bill/119/hr/1?format=json.
  case bill119 = "bill119.json"
  /// Recorded https://api.congress.gov/v3/bill/119/hr/1/cosponsors?format=json&limit=2&offset=0.
  case bill119_hr1_cosponsors_current = "bill119-hr1-cosponsors-current.json"
  /// Recorded https://api.congress.gov/v3/bill/119/hr/22/cosponsors?format=json&limit=1&offset=0.
  case bill119_hr22_cosponsors_house = "bill119-hr22-cosponsors-house.json"
  /// Recorded bill119-s5-related-first; exact request provenance is in manifest.json.
  case bill119_s5_related_first = "bill119-s5-related-first.json"
  /// Recorded bill119-s5-related-terminal; exact request provenance is in manifest.json.
  case bill119_s5_related_terminal = "bill119-s5-related-terminal.json"
  /// Recorded bill119-s5-subjects-first; exact request provenance is in manifest.json.
  case bill119_s5_subjects_first = "bill119-s5-subjects-first.json"
  /// Recorded bill119-s5-subjects-policy-first; exact request provenance is in manifest.json.
  case bill119_s5_subjects_policy_first = "bill119-s5-subjects-policy-first.json"
  /// Recorded bill119-s5-subjects-policy-next; exact request provenance is in manifest.json.
  case bill119_s5_subjects_policy_next = "bill119-s5-subjects-policy-next.json"
  /// Recorded bill119-s5-subjects-policy-window; exact request provenance is in manifest.json.
  case bill119_s5_subjects_policy_window = "bill119-s5-subjects-policy-window.json"
  /// Recorded bill119-s5-subjects-terminal; exact request provenance is in manifest.json.
  case bill119_s5_subjects_terminal = "bill119-s5-subjects-terminal.json"
  /// Recorded bill summary offset 0; exact request provenance is in manifest.json.
  case bill119_summaries_first = "bill119-summaries-first.json"
  /// Recorded bill summary offset 2, following the provider link.
  case bill119_summaries_next = "bill119-summaries-next.json"
  /// Recorded bill summary offset 4, following the provider link.
  case bill119_summaries_terminal = "bill119-summaries-terminal.json"
  /// Recorded https://api.congress.gov/v3/bill/119/hr/1/text?format=json&limit=2&offset=0.
  case bill119_text_first = "bill119-text-first.json"
  /// Recorded https://api.congress.gov/v3/bill/119/hr/1/text?offset=2&limit=2&format=json.
  case bill119_text_next = "bill119-text-next.json"
  /// Recorded https://api.congress.gov/v3/bill/119/hr/1/text?offset=4&limit=2&format=json.
  case bill119_text_offset4 = "bill119-text-offset4.json"
  /// Recorded https://api.congress.gov/v3/bill/119/hr/1/text?offset=5&limit=2&format=json.
  case bill119_text_terminal = "bill119-text-terminal.json"
  /// Recorded https://api.congress.gov/v3/bill/6/hr/1?format=json.
  case bill6 = "bill6.json"
  /// Recorded https://api.congress.gov/v3/bill/6/hr/1/text?format=json.
  case bill6_text = "bill6-text.json"
  /// Recorded https://api.congress.gov/v3/bill/82/s/677?format=json.
  case bill82 = "bill82.json"
  /// Recorded bill82-s677-subjects-sparse; exact request provenance is in manifest.json.
  case bill82_s677_subjects_sparse = "bill82-s677-subjects-sparse.json"
  /// Recorded historical empty summary response; exact provenance is in manifest.json.
  case bill82_summaries_sparse = "bill82-summaries-sparse.json"
  /// Recorded https://api.congress.gov/v3/bill/82/s/677/text?format=json.
  case bill82_text = "bill82-text.json"
  /// Recorded bill93-hjres1-subjects-historical; exact request provenance is in manifest.json.
  case bill93_hjres1_subjects_historical = "bill93-hjres1-subjects-historical.json"
  /// Recorded https://api.congress.gov/v3/bill/117/hr/3076/amendments?format=json&limit=16&offset=0.
  case bill_117_hr_3076_amendments_first = "bill-117-hr-3076-amendments-first.json"
  /// Recorded https://api.congress.gov/v3/bill/117/hr/3076/amendments?offset=16&limit=16&format=json.
  case bill_117_hr_3076_amendments_next = "bill-117-hr-3076-amendments-next.json"
  /// Recorded https://api.congress.gov/v3/bill/117/hr/3076/amendments?offset=32&limit=16&format=json.
  case bill_117_hr_3076_amendments_terminal = "bill-117-hr-3076-amendments-terminal.json"
  /// Recorded https://api.congress.gov/v3/bill/6?format=json&limit=2&offset=0.
  case bills6_first = "bills6-first.json"
  /// Recorded https://api.congress.gov/v3/bill/6?offset=2&limit=2&format=json.
  case bills6_next = "bills6-next.json"
  /// Recorded committee-118-house-hspw00; exact request provenance is in manifest.json.
  case committee_118_house_hspw00 = "committee-118-house-hspw00.json"
  /// Recorded committee-directory-all-first; exact request provenance is in manifest.json.
  case committee_directory_all_first = "committee-directory-all-first.json"
  /// Recorded committee-directory-congress-119; exact request provenance is in manifest.json.
  case committee_directory_congress_119 = "committee-directory-congress-119.json"
  /// Recorded committee-directory-congress-119-joint-chain-first; exact request provenance is in manifest.json.
  case committee_directory_congress_119_joint_chain_first =
    "committee-directory-congress-119-joint-chain-first.json"
  /// Recorded committee-directory-congress-119-joint-chain-terminal; exact request provenance is in manifest.json.
  case committee_directory_congress_119_joint_chain_terminal =
    "committee-directory-congress-119-joint-chain-terminal.json"
  /// Recorded committee-directory-congress-119-joint-first; exact request provenance is in manifest.json.
  case committee_directory_congress_119_joint_first =
    "committee-directory-congress-119-joint-first.json"
  /// Recorded committee-directory-joint; exact request provenance is in manifest.json.
  case committee_directory_joint = "committee-directory-joint.json"
  /// Recorded committee-house-hspw00; exact request provenance is in manifest.json.
  case committee_house_hspw00 = "committee-house-hspw00.json"
  /// Recorded committee bills chain-first; exact request provenance is in manifest.json.
  case committee_house_hspw00_bills_chain_first = "committee-house-hspw00-bills-chain-first.json"
  /// Recorded committee bills chain-terminal; exact request provenance is in manifest.json.
  case committee_house_hspw00_bills_chain_terminal =
    "committee-house-hspw00-bills-chain-terminal.json"
  /// Recorded committee bills first; exact request provenance is in manifest.json.
  case committee_house_hspw00_bills_first = "committee-house-hspw00-bills-first.json"
  /// Recorded committee bills window-first; exact request provenance is in manifest.json.
  case committee_house_hspw00_bills_window_first = "committee-house-hspw00-bills-window-first.json"
  /// Recorded committee reports chain-first; exact request provenance is in manifest.json.
  case committee_house_hspw00_reports_chain_first =
    "committee-house-hspw00-reports-chain-first.json"
  /// Recorded committee reports chain-terminal; exact request provenance is in manifest.json.
  case committee_house_hspw00_reports_chain_terminal =
    "committee-house-hspw00-reports-chain-terminal.json"
  /// Recorded committee reports first; exact request provenance is in manifest.json.
  case committee_house_hspw00_reports_first = "committee-house-hspw00-reports-first.json"
  /// Recorded committee reports window-first; exact request provenance is in manifest.json.
  case committee_house_hspw00_reports_window_first =
    "committee-house-hspw00-reports-window-first.json"
  /// Recorded committee-house-hspw14; exact request provenance is in manifest.json.
  case committee_house_hspw14 = "committee-house-hspw14.json"
  /// Recorded committee House communications chain-first; exact request provenance is in manifest.json.
  case committee_house_hsso00_house_communications_chain_first =
    "committee-house-hsso00-house-communications-chain-first.json"
  /// Recorded committee House communications chain-next; exact request provenance is in manifest.json.
  case committee_house_hsso00_house_communications_chain_next =
    "committee-house-hsso00-house-communications-chain-next.json"
  /// Recorded committee House communications chain-terminal; exact request provenance is in manifest.json.
  case committee_house_hsso00_house_communications_chain_terminal =
    "committee-house-hsso00-house-communications-chain-terminal.json"
  /// Recorded committee House communications first; exact request provenance is in manifest.json.
  case committee_house_hsso00_house_communications_first =
    "committee-house-hsso00-house-communications-first.json"
  /// Recorded committee-joint-jcov00; exact request provenance is in manifest.json.
  case committee_joint_jcov00 = "committee-joint-jcov00.json"
  /// Recorded https://api.congress.gov/v3/committee-report/109/hrpt/519?format=json.
  case committee_report_109_hrpt_519_detail = "committee-report-109-hrpt-519-detail.json"
  /// Recorded https://api.congress.gov/v3/committee-report/109/hrpt/519/text?format=json&limit=1&offset=0.
  case committee_report_109_hrpt_519_text_first = "committee-report-109-hrpt-519-text-first.json"
  /// Recorded https://api.congress.gov/v3/committee-report/109/hrpt/519/text?offset=1&limit=1&format=json.
  case committee_report_109_hrpt_519_text_next = "committee-report-109-hrpt-519-text-next.json"
  /// Recorded https://api.congress.gov/v3/committee-report/109/hrpt/519/text?offset=3&limit=1&format=json.
  case committee_report_109_hrpt_519_text_terminal =
    "committee-report-109-hrpt-519-text-terminal.json"
  /// Recorded https://api.congress.gov/v3/committee-report/109/hrpt/519/text?offset=2&limit=1&format=json.
  case committee_report_109_hrpt_519_text_third = "committee-report-109-hrpt-519-text-third.json"
  /// Recorded https://api.congress.gov/v3/committee-report/116/hrpt/333?format=json.
  case committee_report_116_hrpt_333_conference_detail =
    "committee-report-116-hrpt-333-conference-detail.json"
  /// Recorded https://api.congress.gov/v3/committee-report/117?format=json&limit=2&offset=0&conference=false.
  case committee_report_117_conference_false_first =
    "committee-report-117-conference-false-first.json"
  /// Recorded https://api.congress.gov/v3/committee-report/117?format=json&limit=2&offset=0&conference=true.
  case committee_report_117_conference_true_first =
    "committee-report-117-conference-true-first.json"
  /// Recorded https://api.congress.gov/v3/committee-report/117/erpt/5?format=json.
  case committee_report_117_erpt_5_detail = "committee-report-117-erpt-5-detail.json"
  /// Recorded https://api.congress.gov/v3/committee-report/117?format=json&limit=2&offset=0.
  case committee_report_117_inventory_first = "committee-report-117-inventory-first.json"
  /// Recorded https://api.congress.gov/v3/committee-report/117/SRPT/1?format=json.
  case committee_report_117_srpt_1_detail = "committee-report-117-srpt-1-detail.json"
  /// Recorded https://api.congress.gov/v3/committee-report/117/srpt?format=json&limit=96&offset=0.
  case committee_report_117_srpt_chain_first = "committee-report-117-srpt-chain-first.json"
  /// Recorded https://api.congress.gov/v3/committee-report/117/srpt?offset=96&limit=96&format=json.
  case committee_report_117_srpt_chain_next = "committee-report-117-srpt-chain-next.json"
  /// Recorded https://api.congress.gov/v3/committee-report/117/srpt?offset=192&limit=96&format=json.
  case committee_report_117_srpt_chain_terminal = "committee-report-117-srpt-chain-terminal.json"
  /// Recorded https://api.congress.gov/v3/committee-report/117/srpt?format=json&limit=2&offset=0.
  case committee_report_117_srpt_first = "committee-report-117-srpt-first.json"
  /// Recorded https://api.congress.gov/v3/committee-report?format=json&limit=2&offset=0.
  case committee_report_inventory_first = "committee-report-inventory-first.json"
  /// Recorded committee Senate communications chain-first; exact request provenance is in manifest.json.
  case committee_senate_slet00_senate_communications_chain_first =
    "committee-senate-slet00-senate-communications-chain-first.json"
  /// Recorded committee Senate communications chain-next; exact request provenance is in manifest.json.
  case committee_senate_slet00_senate_communications_chain_next =
    "committee-senate-slet00-senate-communications-chain-next.json"
  /// Recorded committee Senate communications chain-terminal; exact request provenance is in manifest.json.
  case committee_senate_slet00_senate_communications_chain_terminal =
    "committee-senate-slet00-senate-communications-chain-terminal.json"
  /// Recorded committee Senate communications first; exact request provenance is in manifest.json.
  case committee_senate_slet00_senate_communications_first =
    "committee-senate-slet00-senate-communications-first.json"
  /// Recorded committee nominations chain-first; exact request provenance is in manifest.json.
  case committee_senate_slia00_nominations_chain_first =
    "committee-senate-slia00-nominations-chain-first.json"
  /// Recorded committee nominations chain-next; exact request provenance is in manifest.json.
  case committee_senate_slia00_nominations_chain_next =
    "committee-senate-slia00-nominations-chain-next.json"
  /// Recorded committee nominations chain-terminal; exact request provenance is in manifest.json.
  case committee_senate_slia00_nominations_chain_terminal =
    "committee-senate-slia00-nominations-chain-terminal.json"
  /// Recorded committee nominations first; exact request provenance is in manifest.json.
  case committee_senate_slia00_nominations_first = "committee-senate-slia00-nominations-first.json"
  /// Recorded committee-senate-ssju00; exact request provenance is in manifest.json.
  case committee_senate_ssju00 = "committee-senate-ssju00.json"
  /// Recorded https://api.congress.gov/v3/congress?format=json&limit=2&offset=0.
  case congresses_first = "congresses-first.json"
  /// Recorded https://api.congress.gov/v3/congress?offset=118&limit=2&format=json.
  case congresses_last = "congresses-last.json"
  /// Recorded https://api.congress.gov/v3/congress?offset=2&limit=2&format=json.
  case congresses_next = "congresses-next.json"
  /// Recorded crs-report-if10199; exact request provenance is in manifest.json.
  case crs_report_if10199 = "crs-report-if10199.json"
  /// Recorded crs-report-r47175; exact request provenance is in manifest.json.
  case crs_report_r47175 = "crs-report-r47175.json"
  /// Recorded crs-reports-day-first; exact request provenance is in manifest.json.
  case crs_reports_day_first = "crs-reports-day-first.json"
  /// Recorded crs-reports-day-inventory; exact request provenance is in manifest.json.
  case crs_reports_day_inventory = "crs-reports-day-inventory.json"
  /// Recorded crs-reports-day-terminal; exact request provenance is in manifest.json.
  case crs_reports_day_terminal = "crs-reports-day-terminal.json"
  /// Recorded crs-reports-first; exact request provenance is in manifest.json.
  case crs_reports_first = "crs-reports-first.json"
  /// Recorded crs-reports-window-first; exact request provenance is in manifest.json.
  case crs_reports_window_first = "crs-reports-window-first.json"
  /// Recorded law response; exact request provenance is in manifest.json.
  case law117_private_first = "law117-private-first.json"
  /// Recorded law response; exact request provenance is in manifest.json.
  case law117_private_next = "law117-private-next.json"
  /// Recorded law response; exact request provenance is in manifest.json.
  case law117_private_terminal = "law117-private-terminal.json"
  /// Recorded law response; exact request provenance is in manifest.json.
  case law117_private1 = "law117-private1.json"
  /// Recorded law response; exact request provenance is in manifest.json.
  case law119_inventory = "law119-inventory.json"
  /// Recorded law response; exact request provenance is in manifest.json.
  case law119_public_inventory = "law119-public-inventory.json"
  /// Recorded law response; exact request provenance is in manifest.json.
  case law119_public1 = "law119-public1.json"
  /// Recorded law response; exact request provenance is in manifest.json.
  case law93_public1 = "law93-public1.json"
  /// Recorded https://api.congress.gov/v3/member/A000375?format=json.
  case member_A000375 = "member-A000375.json"
  /// Recorded C001136 cosponsored legislation discovery; exact provenance is in manifest.json.
  case member_c001136_cosponsored_legislation_discovery =
    "member-c001136-cosponsored-legislation-discovery.json"
  /// Recorded C001136 cosponsored legislation first; exact provenance is in manifest.json.
  case member_c001136_cosponsored_legislation_first =
    "member-c001136-cosponsored-legislation-first.json"
  /// Recorded C001136 cosponsored legislation next; exact provenance is in manifest.json.
  case member_c001136_cosponsored_legislation_next =
    "member-c001136-cosponsored-legislation-next.json"
  /// Recorded C001136 cosponsored legislation terminal; exact provenance is in manifest.json.
  case member_c001136_cosponsored_legislation_terminal =
    "member-c001136-cosponsored-legislation-terminal.json"
  /// Recorded C001136 sponsored legislation discovery; exact provenance is in manifest.json.
  case member_c001136_sponsored_legislation_discovery =
    "member-c001136-sponsored-legislation-discovery.json"
  /// Recorded C001136 sponsored legislation first; exact provenance is in manifest.json.
  case member_c001136_sponsored_legislation_first =
    "member-c001136-sponsored-legislation-first.json"
  /// Recorded C001136 sponsored legislation next; exact provenance is in manifest.json.
  case member_c001136_sponsored_legislation_next = "member-c001136-sponsored-legislation-next.json"
  /// Recorded C001136 sponsored legislation terminal; exact provenance is in manifest.json.
  case member_c001136_sponsored_legislation_terminal =
    "member-c001136-sponsored-legislation-terminal.json"
  /// Recorded https://api.congress.gov/v3/member/H000324?format=json.
  case member_H000324 = "member-H000324.json"
  /// Recorded https://api.congress.gov/v3/member/L000174?format=json.
  case member_L000174 = "member-L000174.json"
  /// Recorded L000174 cosponsored row: amendmentNumber 5164, URL /v3/amendment/114/samdt/5164.
  case member_l000174_cosponsored_legislation_discovery =
    "member-l000174-cosponsored-legislation-discovery.json"
  /// Recorded L000174 sponsored row: amendmentNumber 5136, URL /v3/amendment/114/samdt/5136.
  case member_l000174_sponsored_legislation_discovery =
    "member-l000174-sponsored-legislation-discovery.json"
  /// Recorded https://api.congress.gov/v3/member/P000610?format=json.
  case member_P000610 = "member-P000610.json"
  /// Recorded https://api.congress.gov/v3/member/congress/117?currentMember=true&format=json&limit=2&offset=0.
  case members117_current = "members117-current.json"
  /// Recorded https://api.congress.gov/v3/member/congress/117?currentMember=false&format=json&limit=2&offset=0.
  case members117_first = "members117-first.json"
  /// Recorded https://api.congress.gov/v3/member/congress/117?currentMember=false&offset=2&limit=2&format=json.
  case members117_next = "members117-next.json"
  /// Recorded https://api.congress.gov/v3/member/congress/117?currentMember=false&offset=556&limit=2&format=json.
  case members117_terminal = "members117-terminal.json"
  /// Recorded /v3/member/congress/118/TX/15; exact query provenance is in manifest.json.
  case members118_tx15_current = "members118-tx15-current.json"
  /// Recorded /v3/member/congress/118/TX/15; exact query provenance is in manifest.json.
  case members118_tx15_historical = "members118-tx15-historical.json"
  /// Recorded /v3/member/AK; exact query provenance is in manifest.json.
  case members_ak_current_first = "members-ak-current-first.json"
  /// Recorded /v3/member/AK; exact query provenance is in manifest.json.
  case members_ak_current_terminal = "members-ak-current-terminal.json"
  /// Recorded /v3/member/AK/0; exact query provenance is in manifest.json.
  case members_ak_district0_current = "members-ak-district0-current.json"
  /// Recorded /v3/member/AK; exact query provenance is in manifest.json.
  case members_ak_historical = "members-ak-historical.json"
  /// Recorded /v3/member/DC/0?currentMember=true&format=json.
  case members_dc_district0_current = "members-dc-district0-current.json"
  /// Recorded https://api.congress.gov/v3/member?currentMember=false&format=json&limit=2&offset=0.
  case members_default_first = "members-default-first.json"
  /// Recorded https://api.congress.gov/v3/member?currentMember=false&offset=2&limit=2&format=json.
  case members_default_next = "members-default-next.json"
  /// Recorded https://api.congress.gov/v3/member?format=json&limit=2&offset=0.
  case members_first = "members-first.json"
  /// Recorded /v3/member/NY with omitted initial limit; exact provenance is in manifest.json.
  case members_ny_default_first = "members-ny-default-first.json"
  /// Recorded /v3/member/NY with omitted initial limit; exact provenance is in manifest.json.
  case members_ny_default_next = "members-ny-default-next.json"
  /// Recorded https://api.congress.gov/v3/member?format=json&fromDateTime=2026-09-01T00:00:00Z&limit=2&offset=0&toDateTime=2026-09-25T00:00:00Z.
  case members_window = "members-window.json"
  /// Recorded Congress 119 House bill finite-window summary feed.
  case summary_updates119_hr_window = "summary-updates119-hr-window.json"
  /// Recorded Congress 119 finite-window summary feed.
  case summary_updates119_window = "summary-updates119-window.json"
  /// Recorded recent-day default summary feed.
  case summary_updates_default = "summary-updates-default.json"
  /// Recorded sorted finite-window summary feed.
  case summary_updates_window = "summary-updates-window.json"
  /// Recorded provider-linked sorted feed page, retaining its malformed next link.
  case summary_updates_window_next = "summary-updates-window-next.json"
  /// Recorded finite-window feed offset 0 without optional sort; provenance is in manifest.json.
  case summary_updates_window_unsorted_first = "summary-updates-window-unsorted-first.json"
  /// Recorded unsorted finite-window feed offset 2, following the provider link.
  case summary_updates_window_unsorted_next = "summary-updates-window-unsorted-next.json"
  /// Recorded unsorted finite-window feed offset 6, the provider-linked terminal page.
  case summary_updates_window_unsorted_terminal = "summary-updates-window-unsorted-terminal.json"
  /// Recorded unsorted finite-window feed offset 4, following the provider link.
  case summary_updates_window_unsorted_third = "summary-updates-window-unsorted-third.json"

  package func data() throws -> Data {
    guard
      let url = Bundle.module.url(
        forResource: rawValue, withExtension: nil, subdirectory: "Fixtures")
    else {
      throw CocoaError(.fileNoSuchFile)
    }
    return try Data(contentsOf: url)
  }
}

package let suiteTimeLimitMinutes = 1
