//
//  AppDelegate.swift
//  EjectionSeat
//
//  Created by Alea Kootz on 4/17/18.
//  Copyright © 2024 Alea Kootz. All rights reserved.
//

import Cocoa
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate, NSWindowDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let menu: NSMenu = NSMenu()
    var aboutWindow: NSWindow?
    var lastVolume: String = ""
    let version: String = Bundle.main.infoDictionary?["CFBundleVersion"] as! String

    private let successCategoryID = "EJECT_SUCCESS"
    private let failureCategoryID = "EJECT_FAILURE"
    private let ejectActionID = "EJECT_RETRY"

    func delay(_ seconds: Int, block: @escaping () -> Void){
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds), execute: block)
    }
    
    func play(_ name: String){
        let sound = NSSound(named: NSSound.Name(name))
        sound?.play()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        //statusItem.title = "EjectionSeat"
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        statusItem.button?.image = NSImage(systemSymbolName: "eject.fill", accessibilityDescription: "Eject")?.withSymbolConfiguration(symbolConfig)
        statusItem.button?.image?.isTemplate = true
        statusItem.menu = menu
        statusItem.menu?.delegate = self
        makeAboutWindow()
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
        if let subMenu = makeSubMenu() {
            menu.addItem(NSMenuItem(title: "Eject All", action: #selector(AppDelegate.ejectAll(_:)), keyEquivalent: "e"))
            menu.addItem(NSMenuItem(title: "Eject", action: nil, keyEquivalent: ""))
            menu.setSubmenu(subMenu, for: (menu.item(withTitle: "Eject"))!)
        } else {
            menu.addItem(NSMenuItem(title: "Nothing to eject", action: nil, keyEquivalent: ""))
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About", action: #selector(AppDelegate.aboutWindowDisplay(_:)), keyEquivalent: "a"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.quit(_:)), keyEquivalent: "q"))
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
    
    func makeSubMenu() -> NSMenu? {
        guard let urls = getURLList(), urls.count > 0 else { return nil }
        let subMenu = NSMenu()
        var titles: [String] = []
        for url in urls {
            titles.append(url.pathComponents[url.pathComponents.endIndex-1])
        }
        titles = titles.sorted{$0.caseInsensitiveCompare($1) == .orderedAscending}
        var numKey = 0
        for title in titles {
            numKey += 1
            subMenu.addItem(NSMenuItem(title: title, action: #selector(AppDelegate.eject(_:)), keyEquivalent: "\(numKey)"))
        }
        return subMenu
    }
    
    @objc func quit(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    @objc func eject(_ sender: NSMenuItem) {
        guard let urls = getURLList(), urls.count > 0 else { return }
        for url in urls {
            if url.pathComponents[url.pathComponents.endIndex-1] == sender.title {
                lastVolume = sender.title
                guard (try? NSWorkspace().unmountAndEjectDevice(at: url)) != nil else {
                    showNotificationFailure()
                    return
                }
                showNotificationSuccess()
            }
        }
    }
    
    @objc func ejectAll(_ sender: NSMenuItem) {
        var hideError = true
        var keepGoing = true
        while keepGoing {
            var anySuccess = false
            guard let urls = getURLList(), urls.count > 0 else { return }
            for url in urls {
                lastVolume = url.pathComponents[url.pathComponents.endIndex-1]
                guard (try? NSWorkspace().unmountAndEjectDevice(at: url)) != nil else {
                    if !hideError {
                        showNotificationFailure()
                    }
                    continue
                }
                showNotificationSuccess()
                anySuccess = true
            }
            keepGoing = hideError
            hideError = anySuccess
        }
    }
    
    func showNotificationSuccess() {
        let content = UNMutableNotificationContent()
        content.title = lastVolume
        content.body = "Ejected safely!"
        content.categoryIdentifier = successCategoryID
        play("Success")
        deliver(content, identifier: "Success \(lastVolume)", removeAfter: 3)
    }

    func showNotificationFailure() {
        let content = UNMutableNotificationContent()
        content.title = lastVolume
        content.body = "Failed to eject."
        content.categoryIdentifier = failureCategoryID
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
            let volume = response.notification.request.content.title
            eject(NSMenuItem(title: volume, action: nil, keyEquivalent: ""))
        }
        completionHandler()
    }

    func getURLList()->[URL]? {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsRemovableKey, .volumeIsEjectableKey]
        guard var urls = FileManager().mountedVolumeURLs(includingResourceValuesForKeys: keys, options: []) else {
            return nil
        }
        for url in urls {
            let components = url.pathComponents
            if components.count < 2 || components[1] != "Volumes"{
                urls.remove(at: urls.index(of: url)!)
            }
        }
        return urls;
    }
}

