# Contributing

## Build and run

Install the macOS Command Line Tools, then run:

```sh
./build.sh
open build/LiftLink.app
```

Quit LiftLink before rebuilding, using its menu bar menu or `killall LiftLink`. Repeat the commands above to build and relaunch it.

## Code signing

Use a stable signing identity to retain Accessibility access across rebuilds. The default ad hoc signature can require approval again after code changes.

### One-time setup

1. In **Keychain Access → Certificate Assistant → Create a Certificate**, choose **Self Signed Root** and **Code Signing**. Name it `LiftLink Local Development` and save its certificate and private key in the login keychain. An existing code-signing identity also works.
2. Save your certificate's name in the ignored local configuration.

   ```sh
   printf '%s\n' 'LiftLink Local Development' > .signing-identity
   ```

   `LIFTLINK_SIGNING_IDENTITY` overrides this file. Recreate the configuration and signing identity on each Mac.
3. Run `./build.sh`. If Keychain prompts, confirm it names **codesign** and your key, then choose **Always Allow**. This authorizes `codesign` to use that key for other projects too. Do not grant all applications access.
4. Open `build/LiftLink.app`, enable it in **System Settings → Privacy & Security → Accessibility**, then quit and reopen it. When switching from ad hoc signing, remove the old Accessibility entry and add the newly signed app once.

Keep the same certificate/private key and the bundle identifier in `Info.plist`. Recreating a certificate with the same name changes its identity. Verify the setup by changing code, rebuilding, relaunching, and copying a link without another approval prompt.

### Checks and troubleshooting

```sh
security find-identity -p codesigning
codesign --verify --strict --verbose=2 build/LiftLink.app
codesign -dr - build/LiftLink.app
```

The designated requirement should retain the same bundle identifier and certificate fingerprint across builds.

- A vague **identity** prompt can come from the private key's label or access-control descriptions. Check both on the matching key before approving access. Renaming the certificate alone may leave the prompt unchanged.
- Self-signed keys can appear under **Matching identities** while `security find-identity -v` lists none. Check the build and signature.
- If an agent cannot find a key that Keychain Access shows, retry with login-keychain access outside its sandbox.

Apple documentation

- https://support.apple.com/guide/keychain-access/create-self-signed-certificates-kyca8916/mac
- https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements
- https://developer.apple.com/documentation/security/access-control-lists

## Pre-releases

Run the **Release preview** workflow on `main` to publish the next `0.0.x` pre-release. The workflow builds an ad hoc-signed Apple Silicon app and attaches a ZIP to the release. It sets the app version for the release; source builds use `0.0.0`. Failed runs can leave a tag, so version numbers may have gaps.

```sh
gh workflow run release.yml --ref main
```

## Design goals

- If text looks clickable, LiftLink's shortcut should copy its destination from any app.
- Prefer standard platform APIs that benefit multiple apps. Reserve app-specific workarounds for widely used apps such as Chrome.
