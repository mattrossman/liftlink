import AppKit
import ApplicationServices

final class LinkCopier: NSObject, NSApplicationDelegate {
    private var status: NSStatusItem!
    private var tap: CFMachPort?
    private var swallowedDown = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.image = NSImage(systemSymbolName: "link", accessibilityDescription: "Link Copier")
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Control + Option + Click to copy", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit Link Copier", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        status.menu = menu

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            show("Enable Accessibility, then restart Link Copier")
            return
        }
        let mask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.leftMouseUp.rawValue)
        tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(mask), callback: { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            return Unmanaged<LinkCopier>.fromOpaque(refcon).takeUnretainedValue().handle(type, event)
        }, userInfo: Unmanaged.passUnretained(self).toOpaque())
        guard let tap else { show("Could not monitor clicks"); return }
        CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0), .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        if type == .leftMouseUp && swallowedDown {
            swallowedDown = false
            return nil
        }
        guard type == .leftMouseDown, event.flags.contains([.maskControl, .maskAlternate]) else {
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
                    NSSound(named: "Glass")?.play()
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

    private func show(_ message: String) {
        status.button?.title = "  \(message)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.status.button?.title = "" }
    }
}

let app = NSApplication.shared
let delegate = LinkCopier()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
