import AuthenticationServices

final class CredentialProviderViewController: ASCredentialProviderViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        // Credential identities are registered by the containing app.
    }

    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        completeRequest(for: credentialIdentity)
    }

    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        completeRequest(for: credentialIdentity)
    }

    private func completeRequest(for credentialIdentity: ASPasswordCredentialIdentity) {
        guard let recordIdentifier = credentialIdentity.recordIdentifier,
              !recordIdentifier.isEmpty else {
            cancelRequest(code: .credentialIdentityNotFound)
            return
        }

        do {
            guard let credential = try SharedCredentialStore.shared.credential(recordIdentifier: recordIdentifier) else {
                cancelRequest(code: .credentialIdentityNotFound)
                return
            }

            let passwordCredential = ASPasswordCredential(
                user: credential.username,
                password: credential.password
            )
            extensionContext.completeRequest(
                withSelectedCredential: passwordCredential,
                completionHandler: nil
            )
        } catch {
            cancelRequest(code: .failed)
        }
    }

    private func cancelRequest(code: ASExtensionError.Code) {
        let error = NSError(
            domain: ASExtensionErrorDomain,
            code: code.rawValue
        )
        extensionContext.cancelRequest(withError: error)
    }
}
