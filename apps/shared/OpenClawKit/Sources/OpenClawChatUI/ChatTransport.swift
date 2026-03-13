import Foundation

public enum OpenAEONChatTransportEvent: Sendable {
    case health(ok: Bool)
    case tick
    case chat(OpenAEONChatEventPayload)
    case agent(OpenAEONAgentEventPayload)
    case seqGap
}

public protocol OpenAEONChatTransport: Sendable {
    func requestHistory(sessionKey: String) async throws -> OpenAEONChatHistoryPayload
    func sendMessage(
        sessionKey: String,
        message: String,
        thinking: String,
        idempotencyKey: String,
        attachments: [OpenAEONChatAttachmentPayload]) async throws -> OpenAEONChatSendResponse

    func abortRun(sessionKey: String, runId: String) async throws
    func listSessions(limit: Int?) async throws -> OpenAEONChatSessionsListResponse

    func requestHealth(timeoutMs: Int) async throws -> Bool
    func events() -> AsyncStream<OpenAEONChatTransportEvent>

    func setActiveSessionKey(_ sessionKey: String) async throws
}

extension OpenAEONChatTransport {
    public func setActiveSessionKey(_: String) async throws {}

    public func abortRun(sessionKey _: String, runId _: String) async throws {
        throw NSError(
            domain: "OpenAEONChatTransport",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "chat.abort not supported by this transport"])
    }

    public func listSessions(limit _: Int?) async throws -> OpenAEONChatSessionsListResponse {
        throw NSError(
            domain: "OpenAEONChatTransport",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "sessions.list not supported by this transport"])
    }
}
