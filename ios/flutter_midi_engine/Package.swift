// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_midi_engine",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "flutter-midi-engine", targets: ["flutter_midi_engine"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_midi_engine",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // Built-in soundfont used by loadSoundfont('') (see tool/generate_soundfont.py)
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("AudioToolbox"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreAudio")
            ]
        )
    ]
)
