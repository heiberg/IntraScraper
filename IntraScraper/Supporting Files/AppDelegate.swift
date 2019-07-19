import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let windowController = MainWindowController()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        WebDataCleaner.clean()
        windowController.showWindow(self)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
