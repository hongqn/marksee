import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    // SwiftUI natively handles opening the first scene (Welcome) on launch or dock click 
    // when DocumentGroup is suppressed.
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }
}
