import Foundation

public protocol OpButtonSessionListener: AnyObject {
    func onOpButtonSessionConnecting()
    func onOpButtonSessionWaitingApproval(_ requestId: String)
    func onOpButtonSessionStarted(_ sessionToken: String)
    func onOpButtonSessionClosed()
    func onOpButtonSessionRejected()
    func onOpButtonSessionAuthFailed()
    func onOpButtonSessionError(_ error: OpButtonError)
}

public extension OpButtonSessionListener {
    func onOpButtonSessionConnecting() {}
    func onOpButtonSessionWaitingApproval(_ requestId: String) {}
    func onOpButtonSessionStarted(_ sessionToken: String) {}
    func onOpButtonSessionClosed() {}
    func onOpButtonSessionRejected() {}
    func onOpButtonSessionAuthFailed() {}
    func onOpButtonSessionError(_ error: OpButtonError) {}
}
