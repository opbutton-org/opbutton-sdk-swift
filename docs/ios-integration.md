# iOS Integration Guide

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

`OpButtonSDK` still pulls `LiveKitClient` `2.13.0` transitively, so you do not need to add a separate `pod "LiveKitClient"` line.
The SDK is currently installed directly from this repository. The legacy CocoaPods spec publisher has been retired; SwiftPods packaging will be configured separately. The LiveKit spec source is still required.

## Basic Setup

### 1. Import

```swift
import OpButtonSDK
```

### 2. Initialize

Initialize the SDK as early as possible (e.g., in `AppDelegate.application(_:didFinishLaunchingWithOptions:)` or your app's `@main` entry):

```swift
let config = OpButtonConfig.Builder("https://opbutton.example.com", "opbutton_your_api_token")
    .setDeviceId("my-device-id")
    .setDeviceName("iPhone 15 Pro (iOS 17.2)")
    .build()

OpButton.initialize(config)
```

If `deviceId` or `deviceName` are not set, the SDK auto-detects them from `UIDevice`.

## Live Input

On iOS, `LIVE_TAP` and `LIVE_LONG_PRESS` are dispatched as synthetic touches into the active application window.

That means your existing UIKit or engine touch pipeline can intercept remote input without any extra integration code in the host app.

### 3. Auto-connect vs Manual

By default `autoConnect` is `true` — the SDK connects immediately after `initialize()`.

To connect manually:

```swift
let config = OpButtonConfig.Builder(url, token)
    .setAutoConnect(false)
    .build()

OpButton.initialize(config)

// Later, when ready:
OpButton.connect()
```

## Session Attributes

Attach static and dynamic attributes to the session:

```swift
let attrs = OpButtonSessionAttributes()
    .put("app_version", Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
    .put("build_number", Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")
    .put("install_id", installId)
    .putProvider("current_level") { gameState.currentLevel }
    .putProvider("player_coins") { gameState.coins }

let config = OpButtonConfig.Builder(url, token)
    .setSessionAttributes(attrs)
    .build()
```

- **Static** attributes are sent once at connect time
- **Dynamic** providers are polled on each action cycle; only changed values are sent

### Supported Attribute Value Types

- `String`
- `Int`, `Double`, `Float`
- `Bool`
- `nil` (sent as JSON `null`)

## Session Status

```swift
let status = OpButton.getStatus()
// .disconnected, .connecting, .waitingApproval, .active,
// .authFailed, .rejected, .closed, .error
```

## Session Lifecycle Listener

```swift
class MyListener: OpButtonSessionListener {
    func onOpButtonSessionConnecting() {
        print("SDK is connecting to the server")
    }

    func onOpButtonSessionWaitingApproval(_ requestId: String) {
        print("Waiting for dashboard approval: \(requestId)")
    }

    func onOpButtonSessionStarted(_ sessionToken: String) {
        print("Session is active!")
    }

    func onOpButtonSessionClosed() {
        print("Session closed")
    }

    func onOpButtonSessionRejected() {
        print("Connection rejected by dashboard user")
    }

    func onOpButtonSessionAuthFailed() {
        print("API token is invalid (HTTP 401)")
    }

    func onOpButtonSessionError(_ error: OpButtonError) {
        print("Error: \(error.message)")
    }
}

// Register via config
let config = OpButtonConfig.Builder(url, token)
    .setSessionListener(MyListener())
    .build()

// Or add/remove at runtime
OpButton.addSessionListener(listener)
OpButton.removeSessionListener(listener)
```

## Disconnect & Shutdown

```swift
// Disconnect but keep SDK alive (can reconnect later)
OpButton.disconnect()

// Full shutdown — releases all resources
// After this, initialize() can be called again
OpButton.shutdown()
```
