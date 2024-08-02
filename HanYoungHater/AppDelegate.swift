import Cocoa
import SwiftUI
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    var eventTap: CFMachPort?
    var currentInputString: String = ""
    var isAutoConvertOn: Bool = true
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        requestAccessibilityPermissions()
        
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        
        eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                     place: .headInsertEventTap,
                                     options: .defaultTap,
                                     eventsOfInterest: eventMask,
                                     callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                                        let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon!).takeUnretainedValue()
                                        return appDelegate.handleEvent(proxy: proxy, type: type, event: event)
                                     },
                                     userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        
        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        } else {
            print("Failed to create event tap")
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        if let eventTap = eventTap {
            CFMachPortInvalidate(eventTap)
        }
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            
            if let character = characterForKeyCode(keyCode) {
                currentInputString.append(character)
                print("Current Input String: \(currentInputString)")
                
//                if currentInputString.hasSuffix("님차") {
//                    replaceLastInput(with: "slack")
//                    currentInputString = ""
//                }
                if currentInputString.hasSuffix("ㄴㅣㅁㅊㅏ") {
                    replaceLastInput(with: "slack")
                    currentInputString = ""
                }
            }
        }
        return Unmanaged.passRetained(event)
    }
    
    private func characterForKeyCode(_ keyCode: Int64) -> String? {
        let keyMapping: [Int64: String] = [
            0x1: "ㄴ", // 1
            0x25: "ㅣ", // 25
            0x0: "ㅁ", // 0
            0x8: "ㅊ", // 8
            0x28: "ㅏ" // 40
            // 필요한 키코드 매핑 추가
        ]
        return keyMapping[keyCode]
    }
    
    private func replaceLastInput(with replacement: String) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        for _ in 0..<currentInputString.count {
            let backspace = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: true)
            backspace?.post(tap: .cghidEventTap)
            let backspaceUp = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: false)
            backspaceUp?.post(tap: .cghidEventTap)
        }
        
        for char in replacement {
            let keyCode = keyCode(for: char)
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
            keyDown?.post(tap: .cghidEventTap)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
            keyUp?.post(tap: .cghidEventTap)
        }
    }
    
    private func keyCode(for character: Character) -> CGKeyCode {
        // 대체할 문자열의 각 문자의 키코드를 반환합니다. 필요한 경우 추가하세요.
        let keyMapping: [Character: CGKeyCode] = [
            "s": 1,
            "l": 37,
            "a": 0,
            "c": 8,
            "k": 40
        ]
        return keyMapping[character] ?? 0
    }
    
    private func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let _ = AXIsProcessTrustedWithOptions(options)
    }

    private func getCurrentKeyboardInputSourceID() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeUnretainedValue() else {
            return nil
        }
        guard let sourceIDPointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return nil
        }
        let sourceID = Unmanaged<CFString>.fromOpaque(sourceIDPointer).takeUnretainedValue() as String
        return sourceID
    }

    private func isKoreanInputSourceActive() -> Bool {
        if let sourceID = getCurrentKeyboardInputSourceID() {
            return sourceID.contains("Hangul")
        }
        return false
    }
}

