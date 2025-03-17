import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var window: NSWindow!

    func applicationDidFinishLaunching(_: Notification) {
        window.makeKeyAndOrderFront(self)
    }
}
