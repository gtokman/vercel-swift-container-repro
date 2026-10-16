// swift-tools-version: 6.3
import PackageDescription

// Hello world on Hummingbird, with the same dependencies as our production server (an AI chat
// backend), to reproduce its build times on Vercel's container runtime.
let package = Package(
    name: "HelloServer",
    platforms: [.macOS(.v26)],  // AnyLanguageModel needs 26 on macOS; Linux ignores this
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.27.0"),
        .package(
            url: "https://github.com/gtokman/AnyLanguageModel.git",
            revision: "f185a6c5857dbe68b6dfc9525f2f9f8e349079a6",
            traits: ["AsyncHTTPClient"]
        ),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.24.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
        .package(url: "https://github.com/mattt/JSONSchema.git", from: "1.3.0"),
        .package(url: "https://github.com/valkey-io/valkey-swift.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "HelloServer",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "AnyLanguageModel", package: "AnyLanguageModel"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Valkey", package: "valkey-swift"),
                .product(name: "JSONSchema", package: "JSONSchema"),
            ]
        ),
    ]
)
