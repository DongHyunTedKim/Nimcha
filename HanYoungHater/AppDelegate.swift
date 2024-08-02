//
//  AppDelegate.swift
//  HanYoungHater
//
//  Created by Ted Kim on 8/2/24.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var eventTap: CFMachPort?
    var isAutoConvertOn: Bool = false
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                     place: .headInsertEventTap,
                                     options: .defaultTap,
                                     eventsOfInterest: CGEventMask(eventMask),
                                     callback: eventCallback,
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

    // 이벤트 콜백 함수
    private let eventCallback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
        let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon!).takeUnretainedValue()
        return appDelegate.handleEvent(proxy: proxy, type: type, event: event)
    }

    // 키 이벤트 처리 함수
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            print("Key pressed: \(keyCode)")
            
            if isAutoConvertOn {
                // 키보드 입력 변환 로직
                if let newEvent = transformKeyEvent(event: event) {
                    return Unmanaged.passRetained(newEvent)
                }
            }
        }
        return Unmanaged.passRetained(event)
    }

    // 키보드 입력 변환 함수
    private func transformKeyEvent(event: CGEvent) -> CGEvent? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        // 키보드 입력 변환 로직 예시
        let keyMapping: [Int64: Int64] = [
            0x12: 0x13, // 예: '해' -> 'g'
            // 더 많은 매핑 추가
        ]
        
        if let newKeyCode = keyMapping[keyCode] {
            event.setIntegerValueField(.keyboardEventKeycode, value: newKeyCode)
            return event
        }
        
        return nil
    }
}
