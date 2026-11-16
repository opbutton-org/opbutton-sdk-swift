import CryptoKit
import Foundation
import Security

final class OpButtonDeviceCredentialStore {
    private let service = "org.opbutton.sdk.device-credential"

    func getOrCreate(baseUrl: String, deviceId: String, configured: String?) throws -> String {
        if let configured = configured { return configured }
        let account = key(baseUrl: baseUrl, deviceId: deviceId)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess {
            guard let data = result as? Data,
                  let value = String(data: data, encoding: .utf8),
                  Self.valid(value) else {
                throw OpButtonError("Stored device credential is invalid")
            }
            return value
        }
        if status != errSecItemNotFound && status != errSecSuccess {
            throw OpButtonError("Unable to read device credential from Keychain (\(status))")
        }
        var bytes = [UInt8](repeating: 0, count: 48)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            throw OpButtonError("Unable to generate device credential")
        }
        let value = Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        try save(baseUrl: baseUrl, deviceId: deviceId, value: value)
        return value
    }

    func save(baseUrl: String, deviceId: String, value: String) throws {
        guard Self.valid(value) else {
            throw OpButtonError(
                "Device credential must contain 32 to 256 printable ASCII characters")
        }
        let account = key(baseUrl: baseUrl, deviceId: deviceId)
        let match: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let data = Data(value.utf8)
        let updateStatus = SecItemUpdate(
            match as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw OpButtonError("Unable to update device credential in Keychain (\(updateStatus))")
        }
        var add = match
        add[kSecValueData as String] = data
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        #endif
        let addStatus = SecItemAdd(add as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw OpButtonError("Unable to store device credential in Keychain (\(addStatus))")
        }
    }

    private func key(baseUrl: String, deviceId: String) -> String {
        SHA256.hash(data: Data("\(baseUrl)\u{0}\(deviceId)".utf8))
            .map { String(format: "%02x", $0) }.joined()
    }

    private static func valid(_ value: String) -> Bool {
        (32...256).contains(value.count) && value.unicodeScalars.allSatisfy {
            (0x21...0x7e).contains($0.value)
        }
    }
}
