import Cocoa

final class MainWindow: NSWindow {
    enum Constants {
        static let defaultSize = NSSize(width: 1000, height: 800)
        static let minimumSize = NSSize(width: 700, height: 500)
    }

    init() {
        let screenRect = NSScreen.main!.frame

        let initialContentRect = NSRect(
            x: (screenRect.width - Constants.defaultSize.width) / 2,
            y: (screenRect.height - Constants.defaultSize.height) / 2,
            width: Constants.defaultSize.width,
            height: Constants.defaultSize.height
        )

        super.init(
            contentRect: initialContentRect,
            styleMask: [.titled, .resizable, .miniaturizable, .closable],
            backing: .buffered,
            defer: false
        )

        title = "IntraScraper"
        minSize = Constants.minimumSize
    }
}
