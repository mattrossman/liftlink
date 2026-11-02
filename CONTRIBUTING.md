# Contributing

## Build and run

Install the macOS Command Line Tools, then run:

```sh
./build.sh
open build/LiftLink.app
```

Quit LiftLink before rebuilding so reopening it runs the new build.

## Code signing

By default, the build uses ad hoc signing. To use a stable signing identity, set `LIFTLINK_SIGNING_IDENTITY` or put its name in `.signing-identity`. Without a stable identity, macOS may ask for Accessibility access again after a rebuild.

## Pre-releases

Run the **Release preview** workflow on `main` to publish the next `0.0.x` pre-release. The workflow builds an ad hoc-signed Apple Silicon app and attaches a ZIP to the release. It sets the app version for the release; source builds use `0.0.0`. Failed runs can leave a tag, so version numbers may have gaps.

```sh
gh workflow run release.yml --ref main
```
