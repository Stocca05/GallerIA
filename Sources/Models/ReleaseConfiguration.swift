import Foundation

enum ReleaseConfiguration {
    private static var values: [String: String] {
        guard let url = Bundle.main.url(forResource: "ReleaseConfiguration", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let values = try? PropertyListDecoder().decode([String: String].self, from: data) else { return [:] }
        return values
    }
    static func publicURL(_ value: String?) -> URL? {
        guard let value, let url = URL(string: value), url.scheme == "https",
              let host = url.host, !host.isEmpty, !host.hasSuffix(".invalid"),
              host != "example.com", url.user == nil, url.password == nil else { return nil }
        return url
    }
    static var privacyURL: URL? { publicURL(values["PrivacyPolicyURL"]) }
    static var supportURL: URL? { publicURL(values["SupportURL"]) }
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static var version: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
