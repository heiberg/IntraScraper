import Cocoa
import SnapKit
import ReactiveSwift
import ReactiveCocoa

final class BrowserView: NSView {

    enum Constants {
        static let chromeHeight = 150
    }

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setup() {
        let browserChromeView = BrowserChromeView()
        addSubview(browserChromeView)
        browserChromeView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        let browserContentView = BrowserContentView()
        addSubview(browserContentView)
        browserContentView.snp.makeConstraints {
            $0.top.equalTo(browserChromeView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        browserChromeView.reactive.browserContentViewState <~ browserContentView.state
        browserContentView.reactive.browserChromeViewEvents <~ browserChromeView.events
    }
}
