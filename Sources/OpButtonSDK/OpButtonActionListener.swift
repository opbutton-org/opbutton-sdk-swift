import Foundation

public protocol OpButtonActionListener: AnyObject {
    func onOpButtonActionReceived(_ action: OpButtonAction)
}
