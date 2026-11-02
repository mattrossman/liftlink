import Foundation

func destinationLabel(_ value: String) -> String {
    guard let url = URLComponents(string: value) else { return "Link" }
    if let host = url.host, !host.isEmpty {
        let port = url.port.map { ":\($0)" } ?? ""
        return host + port + url.percentEncodedPath
    }
    if let scheme = url.scheme { return "\(scheme) link" }
    return "Link"
}
