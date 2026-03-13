import Foundation

public enum OpenAEONContactsCommand: String, Codable, Sendable {
    case search = "contacts.search"
    case add = "contacts.add"
}

public struct OpenAEONContactsSearchParams: Codable, Sendable, Equatable {
    public var query: String?
    public var limit: Int?

    public init(query: String? = nil, limit: Int? = nil) {
        self.query = query
        self.limit = limit
    }
}

public struct OpenAEONContactsAddParams: Codable, Sendable, Equatable {
    public var givenName: String?
    public var familyName: String?
    public var organizationName: String?
    public var displayName: String?
    public var phoneNumbers: [String]?
    public var emails: [String]?

    public init(
        givenName: String? = nil,
        familyName: String? = nil,
        organizationName: String? = nil,
        displayName: String? = nil,
        phoneNumbers: [String]? = nil,
        emails: [String]? = nil)
    {
        self.givenName = givenName
        self.familyName = familyName
        self.organizationName = organizationName
        self.displayName = displayName
        self.phoneNumbers = phoneNumbers
        self.emails = emails
    }
}

public struct OpenAEONContactPayload: Codable, Sendable, Equatable {
    public var identifier: String
    public var displayName: String
    public var givenName: String
    public var familyName: String
    public var organizationName: String
    public var phoneNumbers: [String]
    public var emails: [String]

    public init(
        identifier: String,
        displayName: String,
        givenName: String,
        familyName: String,
        organizationName: String,
        phoneNumbers: [String],
        emails: [String])
    {
        self.identifier = identifier
        self.displayName = displayName
        self.givenName = givenName
        self.familyName = familyName
        self.organizationName = organizationName
        self.phoneNumbers = phoneNumbers
        self.emails = emails
    }
}

public struct OpenAEONContactsSearchPayload: Codable, Sendable, Equatable {
    public var contacts: [OpenAEONContactPayload]

    public init(contacts: [OpenAEONContactPayload]) {
        self.contacts = contacts
    }
}

public struct OpenAEONContactsAddPayload: Codable, Sendable, Equatable {
    public var contact: OpenAEONContactPayload

    public init(contact: OpenAEONContactPayload) {
        self.contact = contact
    }
}
