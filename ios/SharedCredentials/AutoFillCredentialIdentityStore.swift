import AuthenticationServices
import Foundation

enum AutoFillCredentialIdentityStoreError: Error {
    case unavailable
    case noIdentities
    case registrationFailed
}

final class AutoFillCredentialIdentityStore {
    static let shared = AutoFillCredentialIdentityStore()

    private let store = ASCredentialIdentityStore.shared

    private init() {}

    func register(_ credential: SharedCredential, completion: @escaping (Result<Int, Error>) -> Void) {
        let identities = identities(from: credential)
        guard !identities.isEmpty else {
            completion(.failure(AutoFillCredentialIdentityStoreError.noIdentities))
            return
        }

        store.getState { [store] state in
            guard state.isEnabled else {
                completion(.failure(AutoFillCredentialIdentityStoreError.unavailable))
                return
            }

            store.saveCredentialIdentities(identities) { success, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                guard success else {
                    completion(.failure(AutoFillCredentialIdentityStoreError.registrationFailed))
                    return
                }
                completion(.success(identities.count))
            }
        }
    }

    private func identities(from credential: SharedCredential) -> [ASPasswordCredentialIdentity] {
        credential.domains
            .map(normalizedDomain)
            .filter { !$0.isEmpty }
            .removingDuplicates()
            .map { domain in
                let serviceIdentifier = ASCredentialServiceIdentifier(
                    identifier: domain,
                    type: .domain
                )
                let identity = ASPasswordCredentialIdentity(
                    serviceIdentifier: serviceIdentifier,
                    user: credential.username,
                    recordIdentifier: credential.recordIdentifier
                )
                identity.rank = 0
                return identity
            }
    }

    private func normalizedDomain(_ value: String) -> String {
        var domain = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if domain.isEmpty {
            return ""
        }

        if let url = URL(string: domain), let host = url.host {
            domain = host
        } else if let url = URL(string: "https://\(domain)"), let host = url.host {
            domain = host
        }

        return domain
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension Array where Element == String {
    func removingDuplicates() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}
