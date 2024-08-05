import Cocoa
import SwiftUI
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var eventTap: CFMachPort?
    @Published var currentInputSource: String = ""
    @Published var currentInputString: String = ""
    @Published var isAutoConvertOn: Bool = false
    
    
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
        if type == .keyDown && isAutoConvertOn && isKoreanInputSourceActive() {
            
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            
            if let character = characterForKeyCode(keyCode) {
                currentInputString.append(character)
                print("Current Input String: \(currentInputString)")
                
                if currentInputString.hasSuffix("ㄴㅣㅁㅊㅏ") { // "님차"가 입력되면
                    currentInputString = "님ㅊㅏ"
                    replaceLastInput(with: "slack") // "slack"으로 대체하고
                    currentInputString = "" // 지금까지 입력받던 currentInputString을 초기화하고
                    switchToEnglishInputSource() // 영어 입력 소스로 전환합니다.
                }
                
                else if currentInputString.hasSuffix("ㅜㅐㅅㅑㅐㅜ") { // "ㅜㅐ샤ㅐㅜ"가 입력되면
                    replaceLastInput(with: "notion") // "notion"으로 대체하고
                    currentInputString = "" // 지금까지 입력받던 currentInputString을 초기화하고
                    switchToEnglishInputSource() // 영어 입력 소스로 전환합니다.
                }
                
                else if currentInputString.hasSuffix("ㅊㅗㄱㅐㅡㄷ") {
                    replaceLastInput(with: "chrome")
                    currentInputString = ""
                    switchToEnglishInputSource()
                }
                
                else if currentInputString.hasSuffix("ㄴㅁㄹㅁㄱㅑ"){
                    replaceLastInput(with: "safari")
                    currentInputString = ""
                    switchToEnglishInputSource()
                }
            }
            
        }
        return Unmanaged.passRetained(event)
    }
    
    
    private func characterForKeyCode(_ keyCode: Int64) -> String? {
        let keyMapping: [Int64: String] = [
            // 필요한 키코드 매핑 추가
            // - 님차 for Slack
            0x1: "ㄴ", // 1, s
            0x25: "ㅣ", // 25, l
            0x0: "ㅁ", // 0, a
            0x8: "ㅊ", // 8, c
            0x28: "ㅏ", // 40, k
            
            // - ㅜㅐ샤ㅐㅜ for Notion
            0x2D: "ㅜ", // 45, n
            0x1F: "ㅐ", // 31, o
            0x11: "ㅅ", // 17, t
            0x22: "ㅑ", // 34, i
            //0x1F: "ㅐ", // 31, o
            //0x2D: "ㅜ", // 45, n

            // 초개ㅡㄷ for Chrome
            //0x08: "ㅊ", // 8, c
            0x04: "ㅗ", // 4, h
            0x0F: "ㄱ", // 15, r
            //0x1F: "ㅐ", // 31, o
            0x2E: "ㅡ", // 46, m
            0x0E: "ㄷ", // 14, e
            
            // ㄴㅁㄹㅁ갸 for Sarari
            //0x01: "ㄴ", // 1, s
            //0x00: "ㅁ", // 0, a
            0x03: "ㄹ", // 3, f
            //0x00: "ㅁ", // 0, a
            //0x0F: "ㄱ", // 15, r
            //0x22: "ㅑ", // 34, i

            
            // ALL: 필요시 위로 가져다 쓰기
//            0x02: "d", // 2
//            0x05: "g", // 5
//            0x06: "z", // 6
//            0x07: "x", // 7
//            0x09: "v", // 9
//            0x0B: "b", // 11
//            0x0C: "q", // 12
//            0x0D: "w", // 13
//            0x10: "y", // 16
//            0x12: "1", // 18
//            0x13: "2", // 19
//            0x14: "3", // 20
//            0x15: "4", // 21
//            0x16: "6", // 22
//            0x17: "5", // 23
//            0x18: "=", // 24
//            0x19: "9", // 25
//            0x1A: "7", // 26
//            0x1B: "-", // 27
//            0x1C: "8", // 28
//            0x1D: "0", // 29
//            0x1E: "]", // 30
//            0x20: "u", // 32
//            0x21: "[", // 33
//            0x23: "p", // 35
//            0x26: "j", // 38
//            0x27: "'", // 39
//            0x29: ";", // 41
//            0x2A: "\\", // 42
//            0x2B: ",", // 43
//            0x2C: "/", // 44
//            0x2F: ".", // 47
//            0x32: "`", // 50
//            0x31: " ", // 49 (Space)
//            0x24: "\n", // 36 (Return)
//            0x30: "\t", // 48 (Tab)
//            0x33: "\u{8}", // 51 (Delete)
//            0x35: "\u{1B}", // 53 (Esc)
//            0x37: "\u{2318}", // 55 (Command)
//            0x38: "\u{21E7}", // 56 (Shift)
//            0x39: "\u{21EA}", // 57 (Caps Lock)
//            0x3A: "\u{2325}", // 58 (Option)
//            0x3B: "\u{2303}", // 59 (Control)
//            0x7A: "F1", // 122
//            0x78: "F2", // 120
//            0x63: "F3", // 99
//            0x76: "F4", // 118
//            0x60: "F5", // 96
//            0x61: "F6", // 97
//            0x62: "F7", // 98
//            0x64: "F8", // 100
//            0x65: "F9", // 101
//            0x6D: "F10", // 109
//            0x67: "F11", // 103
//            0x6F: "F12" // 111
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
        // 대체할 문자열의 각 문자의 키코드를 반환합니다.
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
            return sourceID.contains("Korean")
        }
        return false
    }
    
    /* func updateCurrentInputSource()
       입력 소스 변경된 것을 앱에 표시하기 위해 사용
     */
    func updateCurrentInputSource() {
        if isKoreanInputSourceActive() {
            currentInputSource = "한글"
        } else {
            currentInputSource = "영어"
        }
    }
    
    private func switchToEnglishInputSource() {
        guard let sourceList = TISCreateInputSourceList(nil, false)?.takeUnretainedValue() as? [TISInputSource] else { return }
        
        for source in sourceList {
            guard let sourceIDPointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { continue }
            let sourceID = Unmanaged<CFString>.fromOpaque(sourceIDPointer).takeUnretainedValue() as String
            
            if sourceID.contains("com.apple.keylayout.ABC") {
                TISSelectInputSource(source)
                print("입력소스가 변경됐습니다. (한글->영어)")
                updateCurrentInputSource()
                return
            }
        }
        print("영어 입력 소스를 찾을 수 없습니다.")
    }
}

