// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "POIService",
	platforms: [
		.iOS(.v16)
	],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "POIService",
			targets: ["POIService"]
		),
		.library(
			name: "ToursprungPOI",
			targets: ["ToursprungPOI"]
		),
		.library(
			name: "ApplePOI",
			targets: ["ApplePOI"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git", from: "4.1.1")
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "POIService",
			dependencies: [
				.product(name: "SFSafeSymbols", package: "SFSafeSymbols")
			]
		),
		.target(
			name: "ToursprungPOI",
			dependencies: ["POIService"]
		),
		.target(
			name: "ApplePOI",
			dependencies: ["POIService"]
		)
	]
)
