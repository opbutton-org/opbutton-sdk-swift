import Foundation

/// Typed action for ``OpButtonSwitch`` change events.
/// Provides a strongly-typed ``value`` instead of raw payload access.
public final class OpButtonSwitchAction {
    public let action: OpButtonAction
    public let value: Bool

    init(_ action: OpButtonAction) {
        self.action = action
        self.value = action.payload?["value"] as? Bool ?? false
    }
}

/// Typed action for ``OpButtonInput`` submit events.
public final class OpButtonInputAction {
    public let action: OpButtonAction
    public let value: String

    init(_ action: OpButtonAction) {
        self.action = action
        self.value = action.payload?["value"] as? String ?? ""
    }
}

/// Typed action for ``OpButtonSelect`` change events.
public final class OpButtonSelectAction {
    public let action: OpButtonAction
    public let value: String

    init(_ action: OpButtonAction) {
        self.action = action
        self.value = action.payload?["value"] as? String ?? ""
    }
}

/// Typed action for ``OpButtonTextarea`` submit events.
public final class OpButtonTextareaAction {
    public let action: OpButtonAction
    public let value: String

    init(_ action: OpButtonAction) {
        self.action = action
        self.value = action.payload?["value"] as? String ?? ""
    }
}


public final class OpButtonRadioGroupAction {
    public let action: OpButtonAction
    public let value: String

    init(_ action: OpButtonAction) {
        self.action = action
        self.value = action.payload?["value"] as? String ?? ""
    }
}


public final class OpButtonSliderAction {
    public let action: OpButtonAction
    public let value: Double

    init(_ action: OpButtonAction) {
        self.action = action
        self.value = action.payload?["value"] as? Double ?? 0
    }
}
