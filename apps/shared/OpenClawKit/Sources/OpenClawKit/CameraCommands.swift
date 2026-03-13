import Foundation

public enum OpenAEONCameraCommand: String, Codable, Sendable {
    case list = "camera.list"
    case snap = "camera.snap"
    case clip = "camera.clip"
}

public enum OpenAEONCameraFacing: String, Codable, Sendable {
    case back
    case front
}

public enum OpenAEONCameraImageFormat: String, Codable, Sendable {
    case jpg
    case jpeg
}

public enum OpenAEONCameraVideoFormat: String, Codable, Sendable {
    case mp4
}

public struct OpenAEONCameraSnapParams: Codable, Sendable, Equatable {
    public var facing: OpenAEONCameraFacing?
    public var maxWidth: Int?
    public var quality: Double?
    public var format: OpenAEONCameraImageFormat?
    public var deviceId: String?
    public var delayMs: Int?

    public init(
        facing: OpenAEONCameraFacing? = nil,
        maxWidth: Int? = nil,
        quality: Double? = nil,
        format: OpenAEONCameraImageFormat? = nil,
        deviceId: String? = nil,
        delayMs: Int? = nil)
    {
        self.facing = facing
        self.maxWidth = maxWidth
        self.quality = quality
        self.format = format
        self.deviceId = deviceId
        self.delayMs = delayMs
    }
}

public struct OpenAEONCameraClipParams: Codable, Sendable, Equatable {
    public var facing: OpenAEONCameraFacing?
    public var durationMs: Int?
    public var includeAudio: Bool?
    public var format: OpenAEONCameraVideoFormat?
    public var deviceId: String?

    public init(
        facing: OpenAEONCameraFacing? = nil,
        durationMs: Int? = nil,
        includeAudio: Bool? = nil,
        format: OpenAEONCameraVideoFormat? = nil,
        deviceId: String? = nil)
    {
        self.facing = facing
        self.durationMs = durationMs
        self.includeAudio = includeAudio
        self.format = format
        self.deviceId = deviceId
    }
}
