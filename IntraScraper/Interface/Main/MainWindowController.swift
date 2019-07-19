import Cocoa
import SnapKit

final class MainWindowController: NSWindowController {
    init() {
        super.init(window: MainWindow())
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        guard
            let window = window,
            let contentView = window.contentView
        else { return }

        let browserView = BrowserView()
        contentView.addSubview(browserView)
        browserView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

