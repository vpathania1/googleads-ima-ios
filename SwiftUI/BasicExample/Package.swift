// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "BasicExample",
  platforms: [.iOS(.v17)],
  dependencies: [
    .package(
      url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-ios",
      from: "3.22.0"
    )
  ],
  targets: [
    .executableTarget(
      name: "BasicExample",
      dependencies: [
        .product(
          name: "GoogleInteractiveMediaAds",
          package: "swift-package-manager-google-interactive-media-ads-ios"
        )
      ],
      path: "Sources/BasicExample"
    )
  ]
)
