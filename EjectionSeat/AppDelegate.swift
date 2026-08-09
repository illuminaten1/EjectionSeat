//
//  AppDelegate.swift
//  EjectionSeat
//
//  Created by Alea Kootz on 4/17/18.
//  Copyright © 2024 Alea Kootz. All rights reserved.
//

import Cocoa
import UserNotifications
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate, NSWindowDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let menu: NSMenu = NSMenu()
    var aboutWindow: NSWindow?
    var preferencesWindow: NSWindow?
    var lastVolume: String = ""
    let version: String = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "?"

    private let successCategoryID = "EJECT_SUCCESS"
    private let failureCategoryID = "EJECT_FAILURE"
    private let ejectActionID = "EJECT_RETRY"
    private let playSoundsKey = "PlaySounds"

    func delay(_ seconds: Int, block: @escaping () -> Void){
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds), execute: block)
    }
    
    func play(_ name: String){
        guard UserDefaults.standard.bool(forKey: playSoundsKey) else { return }
        let sound = NSSound(named: NSSound.Name(name))
        sound?.play()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        //statusItem.title = "EjectionSeat"
        UserDefaults.standard.register(defaults: [playSoundsKey: true])
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        statusItem.button?.image = NSImage(systemSymbolName: "eject.fill", accessibilityDescription: "Eject")?.withSymbolConfiguration(symbolConfig)
        statusItem.button?.image?.isTemplate = true
        statusItem.menu = menu
        statusItem.menu?.delegate = self
        makeAboutWindow()
        makePreferencesWindow()
        configureNotifications()
    }

    func configureNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let ejectAction = UNNotificationAction(identifier: ejectActionID, title: "Eject", options: [])
        let failureCategory = UNNotificationCategory(identifier: failureCategoryID, actions: [ejectAction], intentIdentifiers: [], options: [])
        let successCategory = UNNotificationCategory(identifier: successCategoryID, actions: [], intentIdentifiers: [], options: [])
        center.setNotificationCategories([successCategory, failureCategory])

        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func makeMenu() {
        menu.removeAllItems()
        if let urls = getURLList(), urls.count > 0 {
            menu.addItem(NSMenuItem(title: "Eject All", action: #selector(AppDelegate.ejectAll(_:)), keyEquivalent: "e"))
            menu.addItem(NSMenuItem.separator())
            let entries = urls
                .map { (title: $0.pathComponents[$0.pathComponents.endIndex-1], url: $0) }
                .sorted { $0.title.caseInsensitiveCompare($1.title) == .orderedAscending }
            for (index, entry) in entries.enumerated() {
                // Only digits 1-9 make valid single-character key equivalents.
                let keyEquivalent = index < 9 ? "\(index + 1)" : ""
                let item = NSMenuItem(title: entry.title, action: #selector(AppDelegate.eject(_:)), keyEquivalent: keyEquivalent)
                item.representedObject = entry.url
                menu.addItem(item)
            }
        } else {
            menu.addItem(NSMenuItem(title: "Nothing to eject", action: nil, keyEquivalent: ""))
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About", action: #selector(AppDelegate.aboutWindowDisplay(_:)), keyEquivalent: "a"))
        menu.addItem(NSMenuItem(title: "Preferences…", action: #selector(AppDelegate.preferencesWindowDisplay(_:)), keyEquivalent: ","))
        addLaunchAtLoginMenuItem()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.quit(_:)), keyEquivalent: "q"))
    }

    private func addLaunchAtLoginMenuItem() {
        guard #available(macOS 13.0, *) else { return }
        let item = NSMenuItem(title: "Launch at Login", action: #selector(AppDelegate.toggleLaunchAtLogin(_:)), keyEquivalent: "")
        item.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(item)
    }

    @available(macOS 13.0, *)
    @objc func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("EjectionSeat: failed to toggle Launch at Login — \(error.localizedDescription)")
        }
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        makeMenu()
    }
    
    func makeAboutWindow(){
        let aboutView = NSView(frame: NSMakeRect(0, 0, 192, 256))
        let aboutImage = NSImageView(image: NSApplication.shared.applicationIconImage)
        let aboutTextTitle = NSTextView(frame: NSMakeRect(0, 0, 192, 16))
        let aboutTextBody = NSTextView(frame: NSMakeRect(0, 0, 192, 12))

        aboutView.addSubview(aboutImage)
        aboutView.addSubview(aboutTextTitle)
        aboutView.addSubview(aboutTextBody)


        aboutImage.setFrameSize(NSSize(width: 128, height: 128))
        aboutImage.setFrameOrigin(NSPoint(x:32,y:96))
        aboutImage.imageAlignment = NSImageAlignment.alignCenter
        
        aboutTextTitle.setFrameOrigin(NSPoint(x:0,y:60))
        aboutTextTitle.font = NSFont.titleBarFont(ofSize: 16)
        aboutTextTitle.textColor = NSColor.textColor
        aboutTextTitle.alignment = NSTextAlignment.center
        aboutTextTitle.backgroundColor = NSColor.clear
        aboutTextTitle.string = "EjectionSeat.app"
        aboutTextTitle.isEditable = false
        
        aboutTextBody.setFrameOrigin(NSPoint(x:0,y:24))
        aboutTextBody.font = NSFont.systemFont(ofSize: 12)
        aboutTextBody.textColor = NSColor.gray
        aboutTextBody.alignment = NSTextAlignment.center
        aboutTextBody.backgroundColor = NSColor.clear
        aboutTextBody.string = "Developed by Alea Kootz\nVersion \(version)"
        aboutTextBody.isEditable = false
        
        aboutWindow = NSWindow.init(contentRect: aboutView.frame, styleMask: [.titled, .closable], backing: NSWindow.BackingStoreType.buffered, defer:false)
        aboutWindow?.contentView = aboutView
        aboutWindow?.backgroundColor = NSColor.windowBackgroundColor
        aboutWindow?.isReleasedWhenClosed = false
        aboutWindow?.title = "EjectionSeat.app"
    }
    
    @objc func aboutWindowDisplay(_ sender:NSMenuItem) {
        aboutWindow?.cascadeTopLeft(from: NSEvent.mouseLocation)
        aboutWindow?.orderFrontRegardless()
    }

    func makePreferencesWindow() {
        let prefsView = NSView(frame: NSMakeRect(0, 0, 240, 60))

        let soundCheckbox = NSButton(checkboxWithTitle: "Play sound on eject", target: self, action: #selector(AppDelegate.togglePlaySounds(_:)))
        soundCheckbox.setFrameOrigin(NSPoint(x: 20, y: 20))
        soundCheckbox.sizeToFit()
        soundCheckbox.state = UserDefaults.standard.bool(forKey: playSoundsKey) ? .on : .off
        prefsView.addSubview(soundCheckbox)

        preferencesWindow = NSWindow(contentRect: prefsView.frame, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        preferencesWindow?.contentView = prefsView
        preferencesWindow?.isReleasedWhenClosed = false
        preferencesWindow?.title = "Preferences"
    }

    @objc func preferencesWindowDisplay(_ sender: NSMenuItem) {
        preferencesWindow?.cascadeTopLeft(from: NSEvent.mouseLocation)
        preferencesWindow?.orderFrontRegardless()
    }

    @objc func togglePlaySounds(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: playSoundsKey)
    }

    @objc func quit(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    @objc func eject(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        ejectVolume(at: url)
    }

    @discardableResult
    private func ejectVolume(at url: URL) -> Bool {
        lastVolume = url.pathComponents[url.pathComponents.endIndex-1]
        do {
            try NSWorkspace().unmountAndEjectDevice(at: url)
            showNotificationSuccess()
            return true
        } catch {
            showNotificationFailure(url: url, error: error)
            return false
        }
    }

    @objc func ejectAll(_ sender: NSMenuItem) {
        guard let urls = getURLList(), urls.count > 0 else { return }
        // First pass: try everything quietly — some failures are transient
        // (e.g. a volume briefly busy) and clear up on a second attempt.
        let stillMounted = attemptEject(urls, reportFailures: false)
        // Second pass: retry only what's left, and this time report failures.
        if !stillMounted.isEmpty {
            attemptEject(stillMounted, reportFailures: true)
        }
    }

    /// Attempts to eject each URL, returning those that failed.
    @discardableResult
    private func attemptEject(_ urls: [URL], reportFailures: Bool) -> [URL] {
        var failedURLs: [URL] = []
        for url in urls {
            lastVolume = url.pathComponents[url.pathComponents.endIndex-1]
            do {
                try NSWorkspace().unmountAndEjectDevice(at: url)
                showNotificationSuccess()
            } catch {
                failedURLs.append(url)
                if reportFailures {
                    showNotificationFailure(url: url, error: error)
                }
            }
        }
        return failedURLs
    }
    
    func showNotificationSuccess() {
        let content = UNMutableNotificationContent()
        content.title = lastVolume
        content.body = "Ejected safely!"
        content.categoryIdentifier = successCategoryID
        play("Success")
        deliver(content, identifier: "Success \(lastVolume)", removeAfter: 3)
    }

    func showNotificationFailure(url: URL, error: Error? = nil) {
        let content = UNMutableNotificationContent()
        content.title = lastVolume
        content.body = error?.localizedDescription ?? "Failed to eject."
        content.categoryIdentifier = failureCategoryID
        content.userInfo = ["url": url.absoluteString]
        play("Failure")
        deliver(content, identifier: "Failure \(lastVolume)", removeAfter: 60)
    }

    private func deliver(_ content: UNMutableNotificationContent, identifier: String, removeAfter seconds: Int) {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        delay(seconds) {
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == ejectActionID || response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            if let urlString = response.notification.request.content.userInfo["url"] as? String,
               let url = URL(string: urlString) {
                ejectVolume(at: url)
            }
        }
        completionHandler()
    }

    func getURLList() -> [URL]? {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsRemovableKey, .volumeIsEjectableKey]
        guard let urls = FileManager().mountedVolumeURLs(includingResourceValuesForKeys: keys, options: []) else {
            return nil
        }
        return urls.filter { url in
            let components = url.pathComponents
            return components.count >= 2 && components[1] == "Volumes"
        }
    }
}

