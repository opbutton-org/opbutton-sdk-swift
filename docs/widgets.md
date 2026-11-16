# Widgets

The OpButton SDK provides a declarative UI system for building remote debug panels.

## Overview

```swift
let ui = OpButton.getUI()
let tab = ui.addTab("Game Controls")
let root = tab.vertical()

root.addButton("Restart")
    .variant("contained").color("error")
    .onClick { action in restartGame() }

root.addStat("FPS")
    .unit("fps")
    .valueProvider { String(game.fps) }
```

## Tabs

Each module/service creates its own tab:

```swift
let tab = OpButton.getUI().addTab("My Tab")

// Set a custom id
tab.setId("my-custom-tab-id")
```

Adding a tab with the same title replaces the existing one.

## Layouts

Tabs start with a root layout direction:

```swift
let root = tab.vertical()   // stack children top-to-bottom
// or
let root = tab.horizontal() // stack children left-to-right
```

Nest layouts:

```swift
let row = root.addHorizontal()
row.addButton("A").onClick { _ in doA() }
row.addPadding(1.0)
row.addButton("B").onClick { _ in doB() }
```

### Collapsible Sections

```swift
let section = root.addCollapsible("Advanced Options")
section.addSwitch("Debug Mode").defaultValue(false)
section.addInput("Server URL").defaultValue("https://...")
```

### Padding

```swift
root.addPadding(1.0) // flexible spacer with weight 1.0
```

## Widget Types

### Button

```swift
root.addButton("Click Me")
    .variant("contained")  // "contained", "outlined", "text"
    .color("primary")      // "primary", "secondary", "error", "warning", "info", "success"
    .disabled(false)
    .onClick { action in
        handleClick()
        OpButton.acknowledgeAction(action.id)
    }
```

### Label

```swift
root.addLabel("Status: OK")
    .color("success")

// Auto-updating label
root.addLabel("")
    .textProvider { "Players: \(game.playerCount)" }
```

### Stat

```swift
root.addStat("FPS")
    .value("60")
    .unit("fps")

// Auto-updating stat
root.addStat("Memory")
    .unit("MB")
    .valueProvider { String(format: "%.1f", memoryMB) }
```

### Switch

```swift
root.addSwitch("Debug Mode")
    .defaultValue(false)
    .onChange { action in
        setDebugMode(action.value)
    }
```

### Input

```swift
root.addInput("Player Name")
    .inputType("text")       // "text", "number", "password"
    .defaultValue("Player1")
    .placeholder("Enter name...")
    .onSubmit { action in
        setPlayerName(action.value)
    }
```

### Select

```swift
root.addSelect("Difficulty")
    .options([
        ["easy", "Easy"],
        ["normal", "Normal"],
        ["hard", "Hard"]
    ])
    .defaultValue("normal")
    .onChange { action in
        setDifficulty(action.value)
    }
```

### Textarea

```swift
root.addTextarea("Notes")
    .rows(4)
    .defaultValue("")
    .onSubmit { action in
        saveNotes(action.value)
    }
```

### Table

```swift
root.addTable("Inventory")
    .columns([
        ["name", "Item"],
        ["count", "Count"],
        ["rarity", "Rarity"]
    ])
    .rows([
        ["name": "Sword", "count": 1, "rarity": "Epic"],
        ["name": "Shield", "count": 2, "rarity": "Common"]
    ])
```

### Logs

```swift
root.addLogs("Application Logs")
    .maxLines(100)
```

## Value Providers

Value providers allow widgets to automatically update:

```swift
root.addLabel("")
    .textProvider { gameState.currentScreen }

root.addStat("Score")
    .valueProvider { String(gameState.score) }
```

The SDK polls providers on each cycle and only sends changes.

## Action Handling

### Per-Widget Callbacks

```swift
root.addButton("Restart").onClick { action in
    restartGame()
    OpButton.acknowledgeAction(action.id)
}
```

### Global Action Listener

```swift
class MyActionHandler: OpButtonActionListener {
    func onOpButtonActionReceived(_ action: OpButtonAction) {
        print("Action: \(action.actionType) on widget \(action.widgetId)")
    }
}

OpButton.addActionListener(MyActionHandler())
```

## Action Types

| Type | Trigger |
|------|---------|
| `.click` | Button pressed |
| `.change` | Input/Select value changed |
| `.toggle` | Switch toggled |
| `.liveStart` | Live stream requested |
| `.liveStop` | Live stream stop requested |
| `.liveTap` | Remote tap during live stream |
| `.liveLongPress` | Remote long press during live stream |

## Acknowledging Actions

```swift
OpButton.acknowledgeAction(action.id)

// With response payload
OpButton.acknowledgeAction(action.id, ["result": "success", "value": 42])
```

## Retained layout options

Elements receive generated IDs automatically. Layout edits preserve IDs; removing
or replacing a tree detaches its callbacks and providers. Serialize tree edits on
the host UI thread. The SDK ID counter itself is thread-safe.

Rows and columns support gap, padding, align, justify, wrap and inherited density.
Use a grid for equal-width commands: columns is the maximum column count, and
minCellWidth allows automatic reduction on narrow panels. Placement supports
content width, numeric width, fill with a weight, minimum/maximum width and
alignSelf. Dimensions are dashboard CSS pixels. Radio options stay in one group;
slider changes are sent on release/keyboard commit, with a numeric value.

Install the updated backend and dashboard before using these extensions. Protocol
version 2 remains compatible with existing panels. Optional public ID aliases
retain their existing meaning and are unnecessary for creating elements.

```swift
let root = ui.addTab("Game").vertical().gap(12).padding(8)
let commands = root.addGrid().columns(3).minCellWidth(140).gap(8)
commands.addButton("Restart")
commands.addButton("Clear logs")
let row = root.addHorizontal().gap(8).align("end")
row.addSelect("Language").options([["en", "English"], ["ru", "Русский"]])
    .defaultValue("en").fill().minWidth(160)
row.addButton("Apply").width(120)
root.addRadioGroup("Difficulty").options([["easy", "Easy"], ["hard", "Hard"]])
    .defaultValue("easy").optionDirection("horizontal")
root.addSlider("Speed").range(0.5, 3, 0.1).defaultValue(1).unit("x").fill()
    .onChange { (action: OpButtonSliderAction) in setSpeed(action.value) }
```
