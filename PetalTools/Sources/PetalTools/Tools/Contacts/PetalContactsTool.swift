//
//  PetalContactsTool.swift
//  PetalTools
//
//  Created by Assistant on 4/9/25.
//

#if os(iOS)
import Foundation
import Contacts
import PetalCore

/// A tool to list and search iOS Contacts.
public final class PetalContactsTool: OllamaCompatibleTool, MLXCompatibleTool {

    public init() {}

    // MARK: - PetalTool Protocol

    public let uuid: UUID = .init()
    public var id: String { "petalContactsTool" }
    public var name: String { "Petal Contacts Tool" }
    public var description: String { "Lists or searches contacts and returns names, phone numbers, and emails." }
    public var triggerKeywords: [String] { ["contacts", "phone", "email", "number"] }
    public var domain: String { "contacts" }
    public var requiredPermission: PetalToolPermission { .basic }

    public var parameters: [PetalToolParameter] {
        [
            PetalToolParameter(
                name: "action",
                description: "Action to perform: 'listContacts' or 'searchContacts'",
                dataType: .string,
                required: true,
                example: AnyCodable("searchContacts")
            ),
            PetalToolParameter(
                name: "query",
                description: "Name or substring to search when action is 'searchContacts'",
                dataType: .string,
                required: false,
                example: AnyCodable("Alice")
            ),
            PetalToolParameter(
                name: "limit",
                description: "Maximum number of contacts to return",
                dataType: .number,
                required: false,
                example: AnyCodable(10)
            ),
            PetalToolParameter(
                name: "includePhones",
                description: "Whether to include phone numbers in results",
                dataType: .boolean,
                required: false,
                example: AnyCodable(true)
            ),
            PetalToolParameter(
                name: "includeEmails",
                description: "Whether to include email addresses in results",
                dataType: .boolean,
                required: false,
                example: AnyCodable(true)
            )
        ]
    }

    // MARK: - IO Types

    public struct Input: Codable, Sendable {
        public let action: String
        public let query: String?
        public let limit: Int?
        public let includePhones: Bool?
        public let includeEmails: Bool?

        // Public memberwise initializer so other modules can construct Input
        public init(
            action: String,
            query: String? = nil,
            limit: Int? = nil,
            includePhones: Bool? = nil,
            includeEmails: Bool? = nil
        ) {
            self.action = action
            self.query = query
            self.limit = limit
            self.includePhones = includePhones
            self.includeEmails = includeEmails
        }
    }

    public struct ContactOutput: Codable, Sendable {
        public let identifier: String
        public let displayName: String
        public let givenName: String
        public let familyName: String
        public let phoneNumbers: [String]
        public let emails: [String]
    }

    public struct Output: Codable, Sendable {
        public let contacts: [ContactOutput]
    }

    // MARK: - Execution

    public func execute(_ input: Input) async throws -> Output {
        let store = CNContactStore()
        try await requestContactsAccess(store)

        let includePhones = input.includePhones ?? true
        let includeEmails = input.includeEmails ?? true
        var keys: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor
        ]
        if includePhones { keys.append(CNContactPhoneNumbersKey as CNKeyDescriptor) }
        if includeEmails { keys.append(CNContactEmailAddressesKey as CNKeyDescriptor) }

        let contacts: [CNContact]
        switch input.action {
        case "searchContacts":
            guard let query = input.query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return Output(contacts: [])
            }
            let predicate = CNContact.predicateForContacts(matchingName: query)
            contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
        case "listContacts":
            var fetched: [CNContact] = []
            let request = CNContactFetchRequest(keysToFetch: keys)
            try store.enumerateContacts(with: request) { contact, _ in
                fetched.append(contact)
            }
            contacts = fetched
        default:
            return Output(contacts: [])
        }

        let limited = contacts.prefix(max(0, input.limit ?? 50))
        let outputs: [ContactOutput] = limited.map { contact in
            let phones: [String] = includePhones ? contact.phoneNumbers.map { $0.value.stringValue } : []
            let emails: [String] = includeEmails ? contact.emailAddresses.compactMap { $0.value as String } : []
            let displayName = [contact.givenName, contact.familyName].joined(separator: " ").trimmingCharacters(in: .whitespaces)
            return ContactOutput(
                identifier: contact.identifier,
                displayName: displayName.isEmpty ? "(No Name)" : displayName,
                givenName: contact.givenName,
                familyName: contact.familyName,
                phoneNumbers: phones,
                emails: emails
            )
        }

        return Output(contacts: outputs)
    }

    // MARK: - Permissions

    private func requestContactsAccess(_ store: CNContactStore) async throws {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized:
            return
        case .notDetermined:
            let granted = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                store.requestAccess(for: .contacts) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
            if !granted { throw PetalToolError.permissionDenied }
        case .denied, .restricted:
            throw PetalToolError.permissionDenied
        @unknown default:
            throw PetalToolError.internalError("Unknown contacts authorization status")
        }
    }

    // MARK: - Ollama Definition

    public func asOllamaTool() -> OllamaTool {
        OllamaTool(
            type: "function",
            function: OllamaFunction(
                name: id,
                description: description,
                parameters: OllamaFunctionParameters(
                    type: "object",
                    properties: [
                        "action": OllamaFunctionProperty(
                            type: "string",
                            description: "Action to perform: 'listContacts' or 'searchContacts'"
                        ),
                        "query": OllamaFunctionProperty(
                            type: "string",
                            description: "Name or substring to search when action is 'searchContacts'"
                        ),
                        "limit": OllamaFunctionProperty(
                            type: "number",
                            description: "Maximum number of contacts to return"
                        ),
                        "includePhones": OllamaFunctionProperty(
                            type: "boolean",
                            description: "Whether to include phone numbers in results"
                        ),
                        "includeEmails": OllamaFunctionProperty(
                            type: "boolean",
                            description: "Whether to include email addresses in results"
                        )
                    ],
                    required: ["action"]
                )
            )
        )
    }

    // MARK: - MLX Definition

    public func asMLXToolDefinition() -> MLXToolDefinition {
        MLXToolDefinition(
            type: "function",
            function: MLXFunctionDefinition(
                name: "petalContactsTool",
                description: description,
                parameters: MLXParametersDefinition(
                    type: "object",
                    properties: [
                        "action": MLXParameterProperty(
                            type: "string",
                            description: "Action to perform: 'listContacts' or 'searchContacts'"
                        ),
                        "query": MLXParameterProperty(
                            type: "string",
                            description: "Name or substring to search when action is 'searchContacts'"
                        ),
                        "limit": MLXParameterProperty(
                            type: "number",
                            description: "Maximum number of contacts to return"
                        ),
                        "includePhones": MLXParameterProperty(
                            type: "boolean",
                            description: "Whether to include phone numbers in results"
                        ),
                        "includeEmails": MLXParameterProperty(
                            type: "boolean",
                            description: "Whether to include email addresses in results"
                        )
                    ],
                    required: ["action"]
                )
            )
        )
    }
}
#endif


