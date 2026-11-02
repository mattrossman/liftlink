import AppKit
import ApplicationServices
import ServiceManagement

private let modifierOptions: [(String, CGEventFlags)] = [
    ("Control", .maskControl), ("Option", .maskAlternate),
    ("Command", .maskCommand), ("Shift", .maskShift),
]
private let modifierMask: CGEventFlags = [.maskControl, .maskAlternate, .maskCommand, .maskShift]
private let defaultModifiers: CGEventFlags = [.maskControl, .maskAlternate]
private let soundOptions = ["None", "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"]

private func shortcutLabel(_ flags: CGEventFlags) -> String {
    let names = modifierOptions.filter { flags.contains($0.1) }.map { $0.0 }
    return names.joined(separator: " + ")
}

final class ShortcutRecorder: NSButton {
    var onRecord: ((CGEventFlags) -> Void)?
    private var recording = false
    private var recorded: CGEventFlags = []

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        recording = true
        recorded = []
        title = "Press shortcut…"
        window?.makeFirstResponder(self)
    }

    override func resignFirstResponder() -> Bool {
        if recording {
            recording = false
            onRecord?([])
        }
        return super.resignFirstResponder()
    }

    override func flagsChanged(with event: NSEvent) {
        guard recording else { return }
        let flags = CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue)).intersection(modifierMask)
        if !flags.isEmpty {
            recorded.formUnion(flags)
            title = shortcutLabel(recorded)
        } else if !recorded.isEmpty {
            recording = false
            onRecord?(recorded)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            recording = false
            onRecord?([])
        } else {
            NSSound.beep()
        }
    }
}

final class LinkCopier: NSObject, NSApplicationDelegate {
    private var status: NSStatusItem!
    private var tap: CFMachPort?
    private var swallowedDown = false
    private var messageClear: DispatchWorkItem?
    private var settingsWindow: NSWindow?
    private var shortcutButton: ShortcutRecorder?
    private var loginButton: NSButton?
    private var loginStatus: NSTextField?
    private var shortcutItem: NSMenuItem?
    private var soundMenu: NSPopUpButton?
    private var soundName: String { UserDefaults.standard.string(forKey: "sound") ?? "Glass" }
    private var modifiers: CGEventFlags {
        guard UserDefaults.standard.object(forKey: "modifiers") != nil else { return defaultModifiers }
        return CGEventFlags(rawValue: UInt64(UserDefaults.standard.integer(forKey: "modifiers")))
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.image = NSImage(systemSymbolName: "link", accessibilityDescription: "Link Copier")
        let menu = NSMenu()
        shortcutItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        menu.addItem(shortcutItem!)
        updateShortcutTitle()
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Link Copier", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        status.menu = menu

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            status.button?.title = "  Accessibility required"
            menu.insertItem(NSMenuItem(title: "Enable Accessibility, then restart Link Copier", action: nil, keyEquivalent: ""), at: 0)
            return
        }
        let mask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.leftMouseUp.rawValue)
        tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(mask), callback: { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            return Unmanaged<LinkCopier>.fromOpaque(refcon).takeUnretainedValue().handle(type, event)
        }, userInfo: Unmanaged.passUnretained(self).toOpaque())
        guard let tap else {
            status.button?.title = "  Click monitor unavailable"
            menu.insertItem(NSMenuItem(title: "Quit and reopen Link Copier", action: nil, keyEquivalent: ""), at: 0)
            return
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0), .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            swallowedDown = false
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        if type == .leftMouseUp && swallowedDown {
            swallowedDown = false
            return nil
        }
        guard type == .leftMouseDown, event.flags.intersection(modifierMask) == modifiers else {
            return Unmanaged.passUnretained(event)
        }
        swallowedDown = true
        let point = event.location
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var url = Self.link(at: point)
            for _ in 0..<3 where url == nil {
                Thread.sleep(forTimeInterval: 0.1)
                url = Self.link(at: point)
            }
            DispatchQueue.main.async {
                guard let self else { return }
                if let url {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url, forType: .string)
                    self.show("Link copied")
                    self.playSound()
                } else {
                    self.show("No link found")
                    NSSound.beep()
                }
            }
        }
        return nil
    }

    private static func link(at point: CGPoint) -> String? {
        let system = AXUIElementCreateSystemWide()
        var found: AXUIElement?
        guard AXUIElementCopyElementAtPosition(system, Float(point.x), Float(point.y), &found) == .success else { return nil }
        var current = found
        for _ in 0..<5 {
            guard let element = current else { break }
            var role: CFTypeRef?
            var value: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role) == .success,
               (role as? String) == "AXLink",
               AXUIElementCopyAttributeValue(element, kAXURLAttribute as CFString, &value) == .success,
               let url = value as? URL, let scheme = url.scheme, !scheme.isEmpty {
                return url.absoluteString
            }
            var parent: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &parent) == .success,
                  let parent, CFGetTypeID(parent) == AXUIElementGetTypeID() else { break }
            current = (parent as! AXUIElement)
        }
        return nil
    }

    private func updateShortcutTitle() {
        shortcutItem?.title = shortcutLabel(modifiers) + " + Click to copy"
        shortcutButton?.title = shortcutLabel(modifiers)
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 360, height: 300), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "Link Copier Settings"
            window.isReleasedWhenClosed = false
            let stack = NSStackView()
            stack.orientation = .vertical
            stack.alignment = .leading
            stack.spacing = 12
            stack.translatesAutoresizingMaskIntoConstraints = false
            window.contentView?.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 20),
                stack.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -20),
                stack.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 20),
            ])
            stack.addArrangedSubview(NSTextField(labelWithString: "Hold these keys and click a link:"))
            let recorder = ShortcutRecorder(title: shortcutLabel(modifiers), target: nil, action: nil)
            recorder.onRecord = { [weak self] flags in
                guard let self else { return }
                if !flags.isEmpty {
                    UserDefaults.standard.set(Int(flags.rawValue), forKey: "modifiers")
                }
                self.updateShortcutTitle()
            }
            shortcutButton = recorder
            stack.addArrangedSubview(recorder)
            stack.addArrangedSubview(NSTextField(wrappingLabelWithString: "Click the shortcut, then press your modifier keys. Press Escape to cancel."))
            stack.addArrangedSubview(NSTextField(labelWithString: "Copy sound:"))
            let soundRow = NSStackView()
            soundRow.orientation = .horizontal
            soundRow.spacing = 12
            let sounds = NSPopUpButton()
            sounds.addItems(withTitles: soundOptions)
            sounds.selectItem(withTitle: soundName)
            sounds.target = self
            sounds.action = #selector(changeSound)
            soundMenu = sounds
            soundRow.addArrangedSubview(sounds)
            soundRow.addArrangedSubview(NSButton(title: "Preview", target: self, action: #selector(previewSound)))
            stack.addArrangedSubview(soundRow)
            let login = NSButton(checkboxWithTitle: "Open at login", target: self, action: #selector(changeLogin))
            loginButton = login
            stack.addArrangedSubview(login)
            let status = NSTextField(wrappingLabelWithString: "")
            loginStatus = status
            stack.addArrangedSubview(status)
            window.center()
            settingsWindow = window
        }
        refreshLoginStatus()
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func changeSound() {
        guard let title = soundMenu?.selectedItem?.title else { return }
        UserDefaults.standard.set(title, forKey: "sound")
    }

    @objc private func previewSound() {
        playSound()
    }

    private func playSound() {
        if soundName != "None" { NSSound(named: soundName)?.play() }
    }

    private func refreshLoginStatus() {
        let state = SMAppService.mainApp.status
        loginButton?.state = (state == .enabled || state == .requiresApproval) ? .on : .off
        loginStatus?.stringValue = state == .requiresApproval ? "Allow Link Copier in System Settings > General > Login Items." : ""
    }

    @objc private func changeLogin() {
        do {
            if loginButton?.state == .on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refreshLoginStatus()
        } catch {
            refreshLoginStatus()
            loginStatus?.stringValue = "Could not update login item: \(error.localizedDescription)"
        }
    }

    private func show(_ message: String) {
        messageClear?.cancel()
        status.button?.title = "  \(message)"
        let clear = DispatchWorkItem { [weak self] in self?.status.button?.title = "" }
        messageClear = clear
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: clear)
    }
}

let app = NSApplication.shared
let delegate = LinkCopier()
app.delegate = delegate
app.run()
