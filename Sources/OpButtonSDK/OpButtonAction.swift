import Foundation

public final class OpButtonAction {
    public let id: String
    public let sessionId: String
    public let widgetId: Int
    public let actionType: OpButtonActionType
    public let status: OpButtonActionStatus
    public let payload: [String: Any]?

    init(id: String, sessionId: String, widgetId: Int,
         actionType: OpButtonActionType, status: OpButtonActionStatus,
         payload: [String: Any]?) {
        self.id = id
        self.sessionId = sessionId
        self.widgetId = widgetId
        self.actionType = actionType
        self.status = status
        self.payload = payload
    }

    static func fromJson(_ json: [String: Any]) -> OpButtonAction {
        return OpButtonAction(
            id: json["id"] as? String ?? "",
            sessionId: json["session_id"] as? String ?? "",
            widgetId: json["widget_id"] as? Int ?? 0,
            actionType: OpButtonActionType.from(json["action_type"] as? String ?? ""),
            status: OpButtonActionStatus.from(json["status"] as? String ?? ""),
            payload: json["payload"] as? [String: Any]
        )
    }
}
