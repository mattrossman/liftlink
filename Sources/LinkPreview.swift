import Foundation

func standaloneLink(_ text: String) -> String? {
    let lowercaseText = text.lowercased()
    guard lowercaseText.hasPrefix("https://") || lowercaseText.hasPrefix("http://") else { return nil }
    guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
    let range = NSRange(location: 0, length: text.utf16.count)
    // shortcut: only whole HTTP(S) URL text elements, use text markers if editors combine URLs with prose.
    guard let match = detector.firstMatch(in: text, range: range), match.range == range,
          let url = match.url else { return nil }
    return url.absoluteString
}

func destinationLabel(_ value: String) -> String {
    guard let url = URLComponents(string: value) else { return "Link" }
    if let host = url.host, !host.isEmpty {
        let port = url.port.map { ":\($0)" } ?? ""
        return host + port + url.percentEncodedPath
    }
    if let scheme = url.scheme { return "\(scheme) link" }
    return "Link"
}
