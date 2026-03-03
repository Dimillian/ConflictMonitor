import ProjectDescription

let project = Project(
    name: "ConflictMonitor",
    options: .options(
        automaticSchemesOptions: .enabled()
    ),
    targets: [
        .target(
            name: "ConflictMonitor",
            destinations: .macOS,
            product: .app,
            bundleId: "com.dimillian.conflictmonitor",
            deploymentTargets: .macOS("13.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": .string("ConflictMonitor"),
                "LSUIElement": .boolean(true)
            ]),
            sources: ["ConflictMonitor/Sources/**"]
        )
    ]
)

