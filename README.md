# Link Copier

A macOS menu bar prototype. Control + Option + click attempts to copy the link under the pointer. The menu bar reports success or failure. The modified click is consumed even when no link is found; ordinary clicks pass through.

Build with the macOS Command Line Tools and a code-signing identity named `Link Copier Local Development` in the login keychain. The identity is local to this Mac and is not included in the repository:

```sh
./build.sh
open build/LinkCopier.app
```

Grant Link Copier Accessibility permission in System Settings, then quit and reopen the app. Some apps do not expose link destinations through Accessibility. The clipboard is unchanged if a URL cannot be found.
