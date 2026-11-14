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
- Swift 5.9+
- Xcode 15+

## Installation

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

`OpButtonSDK` still installs `LiveKitClient` `2.13.0` transitively, so you do not need a separate `pod "LiveKitClient"` entry.
The SDK is currently installed directly from this repository. The legacy CocoaPods spec publisher has been retired; SwiftPods packaging will be configured separately. The LiveKit spec source is still required.

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
