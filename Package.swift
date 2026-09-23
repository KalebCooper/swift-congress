// swift-tools-version:6.2

import PackageDescription

// Products and dependencies are introduced with their first working service implementation.
let package = Package(
  name: "swift-congress",
  platforms: [
    .iOS(.v26), .macOS(.v26), .tvOS(.v26), .visionOS(.v26), .watchOS(.v26),
  ],
  products: [],
  traits: [.default(enabledTraits: [])],
  dependencies: [],
  targets: [],
  swiftLanguageModes: [.v6]
)

// Every future target uses these settings, including test and fixture targets.
var swiftSettings: [SwiftSetting] {
  [
    .defaultIsolation(nil),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .strictMemorySafety(),
  ]
}
