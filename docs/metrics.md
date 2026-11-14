# Metrics

## Configuration

```swift
let metricConfig = OpButtonMetricConfig()
    .setEnabled(true)
    .setSampleIntervalMs(200)    // How often collectors are polled (100–1000ms, default: 200)
    .setBufferSize(2000)         // Max buffered entries (default: 2000)
    .setBatchSize(200)           // Max entries per request (default: 200)

let config = OpButtonConfig.Builder(url, token)
    .setMetricConfig(metricConfig)
    .build()
```

## Built-in Metrics

When metrics are enabled, the SDK automatically collects:

| Metric | Type Key | Unit | Aggregation |
|--------|----------|------|-------------|
| Memory (RSS) | `memory` | bytes | gauge |
| Thread count | `thread_count` | — | gauge |
| Battery level | `battery_level` | % | gauge |
| Battery charging | `battery_charging` | — | gauge |

## Built-in Metric Type Constants

| Constant | Key | Unit | Aggregation |
|----------|-----|------|-------------|
| `.fps` | fps | — | gauge |
| `.frameTime` | frame_time | ms | gauge |
| `.memory` | memory | bytes | gauge |
| `.videoMemory` | video_memory | bytes | gauge |
| `.cpuUsage` | cpu_usage | % | gauge |
| `.networkRx` | network_rx | bytes/s | rate |
| `.networkTx` | network_tx | bytes/s | rate |
| `.batteryLevel` | battery_level | % | gauge |
| `.batteryCharging` | battery_charging | — | gauge |
| `.drawCalls` | draw_calls | — | gauge |
| `.threadCount` | thread_count | — | gauge |

## Custom Metric Types

```swift
let drawCalls = OpButtonMetricType.create("draw_calls")
let errors = OpButtonMetricType.create("errors", unit: "", aggregation: .counter)
let latency = OpButtonMetricType.create("request_latency", unit: "ms", aggregation: .gauge)
```

## Aggregation Modes

| Mode | Description | Use case |
|------|-------------|----------|
| `.gauge` | Last/average value | FPS, memory, battery |
| `.counter` | Values are summed | Request count, errors |
| `.rate` | Per-second rate | Network bytes/s |

## Manual Recording

```swift
let metrics = OpButton.getMetrics()

metrics.record(.fps, 60.0)
metrics.record(.memory, Double(processMemory))
metrics.record(.drawCalls, Double(renderer.drawCallCount))

// With explicit timestamp
metrics.record(.cpuUsage, 45.2, timestampMs: Int64(Date().timeIntervalSince1970 * 1000))
```

## Custom Collectors

Collectors are called automatically at the configured sample interval:

```swift
class GameMetrics: OpButtonMetricCollector {
    func collect(_ out: inout [OpButtonMetricEntry]) {
        out.append(OpButtonMetricEntry(.fps, Double(game.currentFps)))
        out.append(OpButtonMetricEntry(.drawCalls, Double(renderer.drawCalls)))

        let customType = OpButtonMetricType.create("active_particles")
        out.append(OpButtonMetricEntry(customType, Double(particleSystem.activeCount)))
    }
}

// Register via config
let metricConfig = OpButtonMetricConfig()
    .addCollector(GameMetrics())

// Or at runtime
OpButton.getMetrics().addCollector(GameMetrics())
OpButton.getMetrics().removeCollector(myCollector)
```

## Runtime Settings

```swift
let metrics = OpButton.getMetrics()
metrics.setSampleIntervalMs(500)
metrics.setBufferSize(5000)
metrics.setBatchSize(100)
```
