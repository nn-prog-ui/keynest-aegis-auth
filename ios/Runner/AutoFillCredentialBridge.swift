import Flutter
import Foundation

final class AutoFillCredentialBridge {
    private static let channelName = "fela/shared_credentials"

    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "saveCredential":
                saveCredential(arguments: call.arguments, result: result)
            case "getCredential":
                getCredential(arguments: call.arguments, result: result)
            case "listCredentials":
                listCredentials(result: result)
            case "deleteCredential":
                deleteCredential(arguments: call.arguments, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func saveCredential(arguments: Any?, result: FlutterResult) {
        do {
            let credential = try credentialFromArguments(arguments)
            try SharedCredentialStore.shared.save(credential)
            result(["recordIdentifier": credential.recordIdentifier])
        } catch {
            result(FlutterError(code: "credential_save_failed", message: "Credential could not be saved.", details: nil))
        }
    }

    private static func getCredential(arguments: Any?, result: FlutterResult) {
        guard let recordIdentifier = recordIdentifierFromArguments(arguments) else {
            result(FlutterError(code: "invalid_record_identifier", message: "recordIdentifier is required.", details: nil))
            return
        }

        do {
            guard let credential = try SharedCredentialStore.shared.credential(recordIdentifier: recordIdentifier) else {
                result(nil)
                return
            }
            result(dictionary(from: credential))
        } catch {
            result(FlutterError(code: "credential_read_failed", message: "Credential could not be read.", details: nil))
        }
    }

    private static func listCredentials(result: FlutterResult) {
        do {
            let credentials = try SharedCredentialStore.shared.credentials()
            result(credentials.map { listDictionary(from: $0) })
        } catch {
            result(FlutterError(code: "credential_list_failed", message: "Credentials could not be listed.", details: nil))
        }
    }

    private static func deleteCredential(arguments: Any?, result: FlutterResult) {
        guard let recordIdentifier = recordIdentifierFromArguments(arguments) else {
            result(FlutterError(code: "invalid_record_identifier", message: "recordIdentifier is required.", details: nil))
            return
        }

        do {
            try SharedCredentialStore.shared.delete(recordIdentifier: recordIdentifier)
            result(nil)
        } catch {
            result(FlutterError(code: "credential_delete_failed", message: "Credential could not be deleted.", details: nil))
        }
    }

    private static func credentialFromArguments(_ arguments: Any?) throws -> SharedCredential {
        guard let dictionary = arguments as? [String: Any],
              let serviceName = dictionary["serviceName"] as? String,
              let username = dictionary["username"] as? String,
              let password = dictionary["password"] as? String else {
            throw SharedCredentialStoreError.encodingFailed
        }

        let recordIdentifier = (dictionary["recordIdentifier"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? UUID().uuidString
        let domains = dictionary["domains"] as? [String] ?? []
        let monthlyPrice = decimal(from: dictionary["monthlyPrice"])
        let renewalDate = date(from: dictionary["renewalDate"])

        return SharedCredential(
            recordIdentifier: recordIdentifier,
            serviceName: serviceName,
            domains: domains,
            loginURL: dictionary["loginUrl"] as? String,
            username: username,
            password: password,
            totpSecret: dictionary["totpSecret"] as? String,
            monthlyPrice: monthlyPrice,
            currency: dictionary["currency"] as? String,
            billingCycle: dictionary["billingCycle"] as? String,
            renewalDate: renewalDate,
            paymentMethod: dictionary["paymentMethod"] as? String,
            cancelURL: dictionary["cancelUrl"] as? String
        )
    }

    private static func recordIdentifierFromArguments(_ arguments: Any?) -> String? {
        if let recordIdentifier = arguments as? String, !recordIdentifier.isEmpty {
            return recordIdentifier
        }
        if let dictionary = arguments as? [String: Any],
           let recordIdentifier = dictionary["recordIdentifier"] as? String,
           !recordIdentifier.isEmpty {
            return recordIdentifier
        }
        return nil
    }

    private static func dictionary(from credential: SharedCredential) -> [String: Any] {
        var dictionary: [String: Any] = [
            "recordIdentifier": credential.recordIdentifier,
            "serviceName": credential.serviceName,
            "domains": credential.domains,
            "username": credential.username,
            "password": credential.password,
            "updatedAt": ISO8601DateFormatter().string(from: credential.updatedAt)
        ]

        dictionary["loginUrl"] = credential.loginURL
        dictionary["totpSecret"] = credential.totpSecret
        dictionary["monthlyPrice"] = credential.monthlyPrice.map { NSDecimalNumber(decimal: $0).stringValue }
        dictionary["currency"] = credential.currency
        dictionary["billingCycle"] = credential.billingCycle
        dictionary["renewalDate"] = credential.renewalDate.map { ISO8601DateFormatter().string(from: $0) }
        dictionary["paymentMethod"] = credential.paymentMethod
        dictionary["cancelUrl"] = credential.cancelURL
        return dictionary
    }

    private static func listDictionary(from credential: SharedCredential) -> [String: Any] {
        var dictionary: [String: Any] = [
            "recordIdentifier": credential.recordIdentifier,
            "serviceName": credential.serviceName,
            "domains": credential.domains,
            "username": credential.username,
            "hasTotpSecret": credential.totpSecret?.isEmpty == false,
            "updatedAt": ISO8601DateFormatter().string(from: credential.updatedAt)
        ]

        dictionary["loginUrl"] = credential.loginURL
        dictionary["monthlyPrice"] = credential.monthlyPrice.map { NSDecimalNumber(decimal: $0).stringValue }
        dictionary["currency"] = credential.currency
        dictionary["billingCycle"] = credential.billingCycle
        dictionary["renewalDate"] = credential.renewalDate.map { ISO8601DateFormatter().string(from: $0) }
        dictionary["paymentMethod"] = credential.paymentMethod
        dictionary["cancelUrl"] = credential.cancelURL
        return dictionary
    }

    private static func decimal(from value: Any?) -> Decimal? {
        if let number = value as? NSNumber {
            return number.decimalValue
        }
        if let string = value as? String {
            return Decimal(string: string)
        }
        return nil
    }

    private static func date(from value: Any?) -> Date? {
        guard let string = value as? String else {
            return nil
        }
        return ISO8601DateFormatter().date(from: string)
    }
}
