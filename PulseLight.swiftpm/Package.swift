// swift-tools-version: 5.6
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "PulseLight",
    platforms: [.iOS("16.0")],
    products: [
        .iOSApplication(
            name: "PulseLight",
            targets: ["AppModule"],
            bundleIdentifier: "nikhil.pulselight",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .presetColor(.red),
            supportedDeviceFamilies: [.pad, .phone],
            supportedInterfaceOrientations: [
                .portrait,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .camera(purposeString: "PulseLight uses your rear camera and flashlight to detect pulse from your fingertip.")
            ],
            appCategory: .healthcareFitness
        )
    ],
    targets: [
        .executableTarget(name: "AppModule", path: ".")
    ]
)
