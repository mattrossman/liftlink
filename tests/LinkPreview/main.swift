import Foundation

assert(destinationLabel("https://example.com/a/b?token=secret#section") == "example.com/a/b")
assert(destinationLabel("http://localhost:8080/a%20b") == "localhost:8080/a%20b")
assert(destinationLabel("http://[::1]:8080/path") == "[::1]:8080/path")
assert(destinationLabel("https://user:password@example.com/") == "example.com/")
assert(destinationLabel("mailto:person@example.com") == "mailto link")
assert(destinationLabel("file:///private/document") == "file link")
assert(destinationLabel("not a link") == "Link")
print("Link preview checks passed.")
