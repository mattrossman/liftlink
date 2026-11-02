# Link Copier

A macOS menu bar prototype. Hold the configured modifier keys and click to copy the link under the pointer. The default is Control + Option. Configure the shortcut and login behavior from the menu bar settings. The menu bar reports success or failure. The modified click is consumed even when no link is found; ordinary clicks pass through.

Quit Link Copier before rebuilding so reopening it runs the new build. Build with the macOS Command Line Tools and a code-signing identity named `Link Copier Local Development` in the login keychain. The identity is local to this Mac and is not included in the repository:

```sh
./build.sh
open build/LinkCopier.app
```

Grant Link Copier Accessibility permission in System Settings, then quit and reopen the app. Some apps do not expose link destinations through Accessibility. The clipboard is unchanged if a URL cannot be found.
