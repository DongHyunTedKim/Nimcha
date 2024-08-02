import Cocoa
import SwiftUI
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    var eventTap: CFMachPort?
    var isAutoConvertOn: Bool = false
    var isKorean: Bool = false
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        requestAccessibilityPermissions()
        self.isAutoConvertOn = true // 자동 전환 기능 활성화

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
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
        print("-------------------")
        print("Event type: \(type.rawValue)")

        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            print("- Key pressed: \(keyCode)")

            isKorean = isKoreanInputSourceActive()
//            if isKoreanInputSourceActive() {
//                print("현재 한글 입력 모드입니다.")
//            } else {
//                print("현재 영어 입력 모드입니다.")
//            }
            if let inputSource = getCurrentKeyboardInputSourceID() {
                print("- source: \(inputSource)")
            }

            if isAutoConvertOn {
                if let newEvent = transformKeyEvent(event: event) {
                    return Unmanaged.passRetained(newEvent)
                }
            }
        }
        return Unmanaged.passRetained(event)
    }

    private func transformKeyEvent(event: CGEvent) -> CGEvent? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        let keyMapping: [Int64: Int64] = [
            //0x12: 0x05, // '1' -> 'ㅎ'
            //0x05: 012, // 'ㅎ' -> '1'
            0x1C: 0x43, // 'ㅌ' -> 'x'
            //    ...
            // 더 많은 매핑 추가
        ]
        
        if let newKeyCode = keyMapping[keyCode] {
            event.setIntegerValueField(.keyboardEventKeycode, value: newKeyCode)
            print("- New keycode: \(newKeyCode)")
            return event
        }
        
        return nil
    }

    private func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let _ = AXIsProcessTrustedWithOptions(options)
    }
    
    func getCurrentKeyboardInputSourceID() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeUnretainedValue() else {
            return nil
        }
        guard let sourceIDPointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return nil
        }
        let sourceID = Unmanaged<CFString>.fromOpaque(sourceIDPointer).takeUnretainedValue() as String
        
        if sourceID.contains("Korean") {
            return "Korean"
        }
        else if sourceID.contains("ABC") {
            return "US"
        }
        return "unknown sourceID = \(sourceID)"
    }

    private func isKoreanInputSourceActive() -> Bool {
        if let sourceID = getCurrentKeyboardInputSourceID() {
            return sourceID.contains("2SetKorean")
        }
        return false
    }
}
