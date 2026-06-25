import Foundation
import Security

enum SharedCredentialStoreError: Error {
    case invalidRecordIdentifier
    case encodingFailed
    case decodingFailed
    case keychainStatus(OSStatus)
}

final class SharedCredentialStore {
    static let shared = SharedCredentialStore()

    private let service = "com.nnprogui.keynestauth.credentials"
    private let accessGroup = "B765LGVPCC.com.nnprogui.keynestauth.shared"
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func save(_ credential: SharedCredential) throws {
        guard !credential.recordIdentifier.isEmpty else {
            throw SharedCredentialStoreError.invalidRecordIdentifier
        }

        var storedCredential = credential
        storedCredential.updatedAt = Date()

        let data: Data
        do {
            data = try encoder.encode(storedCredential)
        } catch {
            throw SharedCredentialStoreError.encodingFailed
        }

        let query = baseQuery(recordIdentifier: storedCredential.recordIdentifier)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw SharedCredentialStoreError.keychainStatus(updateStatus)
        }

        var addQuery = query
        attributes.forEach { addQuery[$0.key] = $0.value }

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw SharedCredentialStoreError.keychainStatus(addStatus)
        }
    }

    func credential(recordIdentifier: String) throws -> SharedCredential? {
        guard !recordIdentifier.isEmpty else {
            throw SharedCredentialStoreError.invalidRecordIdentifier
        }

        var query = baseQuery(recordIdentifier: recordIdentifier)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw SharedCredentialStoreError.keychainStatus(status)
        }
        guard let data = result as? Data else {
            throw SharedCredentialStoreError.decodingFailed
        }

        do {
            return try decoder.decode(SharedCredential.self, from: data)
        } catch {
            throw SharedCredentialStoreError.decodingFailed
        }
    }

    func delete(recordIdentifier: String) throws {
        guard !recordIdentifier.isEmpty else {
            throw SharedCredentialStoreError.invalidRecordIdentifier
        }

        let status = SecItemDelete(baseQuery(recordIdentifier: recordIdentifier) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SharedCredentialStoreError.keychainStatus(status)
        }
    }

    private func baseQuery(recordIdentifier: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: recordIdentifier
        ]

        query[kSecAttrAccessGroup as String] = accessGroup

        return query
    }
}
