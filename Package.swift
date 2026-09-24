// swift-tools-version:6.2

import PackageDescription

// Models remain independent of the optional transport graph.
let package = Package(
  name: "swift-congress",
  platforms: [
    .iOS(.v26), .macOS(.v26), .tvOS(.v26), .visionOS(.v26), .watchOS(.v26),
  ],
  products: [
    .library(name: "SwiftCongressBioguide", targets: ["SwiftCongressBioguide"]),
    .library(name: "SwiftCongressBioguideModels", targets: ["SwiftCongressBioguideModels"]),
    .library(name: "SwiftCongressData", targets: ["SwiftCongressData"]),
    .library(name: "SwiftCongressDataModels", targets: ["SwiftCongressDataModels"]),
  ],
  traits: [
    .default(enabledTraits: []),
    .trait(name: "HTTPPortable", description: "Enable the portable HTTP transport."),
  ],
  dependencies: [
    // Portable SHA-256 verifies extracted profile bytes against the supplied snapshot manifest.
    .package(url: "https://github.com/apple/swift-crypto.git", from: "5.0.0"),
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.6.0"),
    // 1.3.1 provides response capture and the portable page decode contract.
    .package(
      url: "https://github.com/KalebCooper/swifty-networking.git", from: "1.3.1",
      traits: [.trait(name: "HTTPPortable", condition: .when(traits: ["HTTPPortable"]))]),
  ],
  targets: [
    .executableTarget(
      name: "CongressBioguideDemo",
      dependencies: ["SwiftCongressBioguide", "SwiftCongressBioguideModels"],
      path: "Examples/CongressBioguideDemo", swiftSettings: swiftSettings),
    .executableTarget(
      name: "CongressDataDemo", dependencies: ["SwiftCongressData", "SwiftCongressDataModels"],
      path: "Examples/CongressDataDemo", swiftSettings: swiftSettings),
    .target(
      name: "SwiftCongressBioguide",
      dependencies: [
        .product(name: "Crypto", package: "swift-crypto"), "SwiftCongressBioguideModels",
      ], swiftSettings: swiftSettings),
    .target(name: "SwiftCongressBioguideModels", swiftSettings: swiftSettings),
    .target(
      name: "SwiftCongressBioguideTestSupport", resources: [.copy("Fixtures")],
      swiftSettings: swiftSettings),
    .target(
      name: "SwiftCongressData",
      dependencies: [
        .product(name: "HTTPCore", package: "swifty-networking"),
        .product(
          name: "HTTPPortable", package: "swifty-networking",
          condition: .when(traits: ["HTTPPortable"])),
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(
          name: "HTTPURLSession", package: "swifty-networking",
          condition: .when(platforms: [.iOS, .macCatalyst, .macOS, .tvOS, .visionOS, .watchOS])),
        "SwiftCongressDataModels",
      ], swiftSettings: swiftSettings),
    .target(name: "SwiftCongressDataModels", swiftSettings: swiftSettings),
    .target(
      name: "SwiftCongressDataTestSupport", resources: [.copy("Fixtures")],
      swiftSettings: swiftSettings),
    .testTarget(
      name: "SwiftCongressBioguideModelsTests",
      dependencies: ["SwiftCongressBioguideModels", "SwiftCongressBioguideTestSupport"],
      swiftSettings: swiftSettings),
    .testTarget(
      name: "SwiftCongressBioguideTests",
      dependencies: [
        "SwiftCongressBioguide", "SwiftCongressBioguideModels", "SwiftCongressBioguideTestSupport",
      ], swiftSettings: swiftSettings),
    .testTarget(
      name: "SwiftCongressDataModelsTests",
      dependencies: ["SwiftCongressDataModels", "SwiftCongressDataTestSupport"],
      swiftSettings: swiftSettings),
    .testTarget(
      name: "SwiftCongressDataTests",
      dependencies: [
        .product(name: "HTTPCore", package: "swifty-networking"),
        .product(name: "HTTPTesting", package: "swifty-networking"),
        .product(name: "HTTPTypes", package: "swift-http-types"),
        "SwiftCongressData", "SwiftCongressDataModels", "SwiftCongressDataTestSupport",
      ], swiftSettings: swiftSettings),
  ],
  swiftLanguageModes: [.v6]
)

// Library, fixture, and test targets share the same strict isolation and memory settings.
var swiftSettings: [SwiftSetting] {
  [
    .defaultIsolation(nil),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .strictMemorySafety(),
  ]
}
