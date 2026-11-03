import Foundation

assert(destinationLabel("https://example.com/a/b?token=secret#section") == "example.com/a/b")
assert(destinationLabel("http://localhost:8080/a%20b") == "localhost:8080/a%20b")
assert(destinationLabel("http://[::1]:8080/path") == "[::1]:8080/path")
assert(destinationLabel("https://user:password@example.com/") == "example.com/")
assert(destinationLabel("mailto:person@example.com") == "mailto link")
assert(destinationLabel("file:///private/document") == "file link")
assert(destinationLabel("not a link") == "Link")
assert(standaloneLink("https://github.com/supabase/mcp/pull/508") == "https://github.com/supabase/mcp/pull/508")
assert(standaloneLink("HTTPS://example.com") != nil)
for text in ["", "lib.rs", "README.md", "example.com", "me@example.com", "Review https://example.com", "https://example.com then https://example.org", "👀 https://example.com"] {
    assert(standaloneLink(text) == nil)
}
print("Link preview checks passed.")
