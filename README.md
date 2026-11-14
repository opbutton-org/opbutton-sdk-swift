# OpButton SDK for iOS

Lightweight Swift SDK for connecting iOS applications to the **OpButton** remote debug dashboard.

## Features

- **Remote UI** — Declarative panel builder with widgets (buttons, switches, inputs, tables, etc.)
- **Structured Logging** — Buffered log pipeline with categories, metadata, and custom attributes
- **Metrics** — System metrics (memory, threads, battery) + custom metric collectors
- **Live Streaming** — Screen broadcast via LiveKit/WebRTC with remote tap/long-press input and in-app touch overlay
- **Events & Revenue** — Structured event and purchase tracking

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 6.2+
- Xcode 26+

## Installation

### SwiftPods / Swift Package Manager

```ruby
platform :ios, '13.0'

target 'MyApp' do
    spm 'OpButtonSDK', '1.0.60', git: 'https://github.com/opbutton-org/opbutton-sdk-swift.git', products: ['OpButtonSDK']
end
```

Run `swiftpods install`. `OpButtonSDK` links the official LiveKit 2.15.1 XCFramework package.
The SwiftPods catalog also registers `OpButtonSDK` with the same repository and product name.

### CocoaPods

```ruby
source "https://cdn.cocoapods.org/"
source "https://github.com/livekit/podspecs.git"
source "https://github.com/opbutton-org/opbutton-sdk-swift-podspecs.git"

platform :ios, "13.0"

target "MyApp" do
    pod "OpButtonSDK", :git => "https://github.com/opbutton-org/opbutton-sdk-swift.git", :branch => "main"
end
```

`OpButtonSDK` still installs `LiveKitClient` `2.15.1` transitively, so you do not need a separate `pod "LiveKitClient"` entry.
The legacy CocoaPods spec publisher has been retired. For CocoaPods, install directly from this repository and retain the LiveKit spec source.

## Quick Start

```swift
import OpButtonSDK

// 1. Configure
let config = OpButtonConfig.Builder("https://opbutton.example.com", "opbutton_your_token")
    .setDeviceId("my-device")
    .setDeviceName("iPhone 15 (iOS 17)")
    .build()

// 2. Initialize
OpButton.initialize(config)

// 3. Build UI
let ui = OpButton.getUI()
let tab = ui.addTab("Controls")
let root = tab.vertical()

root.addButton("Restart")
    .variant("contained").color("error")
    .onClick { action in
        restartGame()
    }

root.addStat("FPS")
    .unit("fps")
    .valueProvider { String(game.fps) }

// 4. Send logs
OpButton.log(.info, "Game started")

// 5. Track events
OpButton.event("level_completed", metadata: ["level": 5, "score": 1200])

// 6. Shutdown on exit
OpButton.shutdown()
```

## Configuration

```swift
let logConfig = OpButtonLogConfig()
    .setEnabled(true)
    .setLogLevel(.info)
    .setAttributes(OpButtonLogAttributes()
        .put("app_version", "1.0.0")
        .putProvider("screen_name") { currentScreen })

let metricConfig = OpButtonMetricConfig()
    .setEnabled(true)
    .setSampleIntervalMs(200)

let sessionAttrs = OpButtonSessionAttributes()
    .put("install_id", installId)
    .putProvider("level") { currentLevel }

let config = OpButtonConfig.Builder("https://opbutton.example.com", "opbutton_token")
    .setLogConfig(logConfig)
    .setMetricConfig(metricConfig)
    .setSessionAttributes(sessionAttrs)
    .setAutoConnect(true)
    .build()
```

## Widgets

| Widget | Description |
|--------|-------------|
| `OpButtonButton` | Button with click callback |
| `OpButtonLabel` | Text label with optional auto-update |
| `OpButtonStat` | Numeric value with label and unit |
| `OpButtonSwitch` | Toggle switch |
| `OpButtonInput` | Text input field |
| `OpButtonSelect` | Dropdown selection |
| `OpButtonTextarea` | Multi-line text input |
| `OpButtonTable` | Data table (read-only) |
| `OpButtonLogs` | Log output display |

## Session Lifecycle

```swift
class MySessionHandler: OpButtonSessionListener {
    func onOpButtonSessionConnecting() { print("Connecting...") }
    func onOpButtonSessionWaitingApproval(_ requestId: String) { print("Waiting approval") }
    func onOpButtonSessionStarted(_ token: String) { print("Session active!") }
    func onOpButtonSessionClosed() { print("Session closed") }
    func onOpButtonSessionRejected() { print("Rejected") }
    func onOpButtonSessionAuthFailed() { print("Auth failed") }
    func onOpButtonSessionError(_ error: OpButtonError) { print("Error: \(error.message)") }
}

OpButton.addSessionListener(MySessionHandler())
```

## Metrics

Built-in metrics collected automatically:
- Memory (RSS)
- Thread count
- Battery level & charging state

Add custom collectors:

```swift
class GameMetrics: OpButtonMetricCollector {
    func collect(_ out: inout [OpButtonMetricEntry]) {
        out.append(OpButtonMetricEntry(.fps, Double(game.fps)))
        out.append(OpButtonMetricEntry(.drawCalls, Double(renderer.drawCalls)))
    }
}

OpButton.getMetrics().addCollector(GameMetrics())
```

## License

See [LICENSE](../LICENSE) for details.

## Objective-C command tabs

`OpButtonBridge.createCommandTab(_:title:)` returns an `OpButtonCommandTab` for Objective-C hosts. Add command buttons with `addButton(_:title:onClick:)`. Call `close()` before the host releases its handlers; it removes the tab and unregisters its callbacks. Create and close command tabs on the main thread, where SDK actions are dispatched.
