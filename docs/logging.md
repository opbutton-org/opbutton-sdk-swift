# Logging

## Configuration

```swift
let logConfig = OpButtonLogConfig()
    .setEnabled(true)
    .setLogLevel(.info)        // Minimum level (default: .info)
    .setBatchSize(100)         // Max logs per request (default: 100)
    .setBufferSize(1000)       // Max buffered logs (default: 1000)

let config = OpButtonConfig.Builder(url, token)
    .setLogConfig(logConfig)
    .build()
```

## Basic Logging

```swift
OpButton.log(.debug, "Debug message")
OpButton.log(.info, "Player joined the game")
OpButton.log(.warning, "Low memory warning")
OpButton.log(.error, "Failed to load asset")
OpButton.log(.critical, "Unrecoverable error")
```

## Logging with Category and Thread

```swift
OpButton.log(.info, "Texture loaded", category: "assets", thread: "render")
```

## Logging with Metadata

```swift
OpButton.log(.info, "Item purchased", metadata: [
    "item_id": "sword_01",
    "price": 100,
    "currency": "gold"
])

OpButton.log(.error, "Network request failed",
          category: "network", thread: "bg",
          metadata: ["url": "/api/save", "status_code": 500])
```

## Pre-built Log Entries

```swift
let entry = OpButtonLogEntry(
    level: .info,
    message: "Custom log entry",
    category: "game",
    thread: Thread.current.name,
    metadata: ["key": "value"]
)
OpButton.log(entry)

// Convenience constructors
OpButton.log(OpButtonLogEntry.debug("Debug"))
OpButton.log(OpButtonLogEntry.info("Info"))
OpButton.log(OpButtonLogEntry.warning("Warning"))
OpButton.log(OpButtonLogEntry.error("Error"))
OpButton.log(OpButtonLogEntry.critical("Critical"))
```

## Log Attributes

Attach static and dynamic attributes to every log entry:

```swift
let logAttrs = OpButtonLogAttributes()
    .put("app_version", "1.2.3")
    .put("platform", "iOS")
    .putProvider("screen_name") { currentScreen }
    .putProvider("user_id") { currentUserId }

let logConfig = OpButtonLogConfig()
    .setAttributes(logAttrs)
```

- **Static** attributes are set once
- **Dynamic** providers are resolved at each `log()` call

## Events

Structured event entries with automatic categorization:

```swift
OpButton.event("level_completed")

OpButton.event("level_completed", metadata: [
    "level": 5,
    "score": 12000,
    "time_seconds": 45
])

OpButton.event("boss_defeated",
            category: "combat",
            metadata: ["boss_name": "Dragon"])
```

## Revenue Events

```swift
OpButton.revenue("subscription_purchased")

OpButton.revenue("iap_completed", metadata: [
    "product_id": "remove_ads",
    "price": 4.99
])
```

## Screen Tracking

```swift
OpButton.changeScreen(screenType: "game", screenName: "Level 5")
OpButton.changeScreen(screenType: "menu", screenName: "Main Menu")
OpButton.changeScreen(screenType: "shop", screenName: "Item Shop")
```

## In-App Products

```swift
// Publish product catalog
OpButton.setInAppProducts([
    ["product_id": "remove_ads", "price": "$4.99", "title": "Remove Ads"],
    ["product_id": "coin_pack", "price": "$1.99", "title": "100 Coins"]
])

// Track owned products
OpButton.setOwnedInAppProducts(["remove_ads"])

// Record a purchase
OpButton.purchaseInApp(
    transactionId: "TXN_12345",
    productIds: ["coin_pack"],
    metadata: ["source": "shop_screen"]
)
```

## SDK Internal Logging

Intercept SDK's own diagnostic logs:

```swift
class MyLogHandler: OpButtonLoggerListener {
    func onOpButtonLoggerMessage(_ level: OpButtonLogLevel, tag: String, message: String, error: Error?) {
        print("[\(tag)] \(level.rawValue): \(message)")
    }
}

let config = OpButtonConfig.Builder(url, token)
    .setLoggerListener(MyLogHandler())
    .build()
```
