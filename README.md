# LiftLink

Copy a link with a click.

Hold **Control + Option** and click a link to copy its address. Change the shortcut and sound, or start LiftLink at login, from the menu bar.

## Get started

Requires macOS 13 or later and the macOS Command Line Tools.

```sh
./build.sh
open build/LiftLink.app
```

Allow LiftLink to control your computer in **System Settings → Privacy & Security → Accessibility**, then reopen the app. Some apps don't expose link destinations. LiftLink intercepts the click even when it can't copy the link, and leaves the clipboard unchanged.

Quit LiftLink before rebuilding to run the new build. Without a signing identity, builds use ad hoc signing. Set `LIFTLINK_SIGNING_IDENTITY` to use a stable signing identity; otherwise, macOS may ask for Accessibility access again after a rebuild.
