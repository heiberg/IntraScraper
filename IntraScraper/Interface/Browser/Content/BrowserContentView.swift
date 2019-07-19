import Cocoa
import WebKit
import Then
import ReactiveSwift
import ReactiveCocoa

final class BrowserContentView: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Browser State

    struct State {
        let url: URL?
        let canGoBack: Bool
        let canGoForward: Bool
        let pageState: BrowserPageState

        static let initial = State(
            url: nil,
            canGoBack: false,
            canGoForward: false,
            pageState: .initial
        )
    }

    var state: Property<State> { return Property(mutableState) }
    private let mutableState = MutableProperty(State.initial)

    // MARK: - Chrome View Events

    func handle(browserChromeViewEvent event: BrowserChromeView.Event) {
        switch event {
        case .reload:
            webView.reload()
        case let .load(urlRequest):
            webView.load(urlRequest)
        case .goBack:
            webView.goBack()
        case .goForward:
            webView.goForward()
        }
    }

    // MARK: - Private

    private let webViewDelegate = BrowserContentWebViewDelegate()
    private let webViewConfiguration = WKWebViewConfiguration()

    private lazy var webView: WKWebView = WKWebView(frame: bounds, configuration: webViewConfiguration).then {
        $0.navigationDelegate = webViewDelegate
    }

    private let errorView = BrowserContentErrorView()

    private func setup() {
        addSubview(webView)
        webView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        webView.isHidden = true

        addSubview(errorView)
        errorView.snp.makeConstraints {
            $0.edges.equalTo(webView)
        }
        errorView.isHidden = true

        webViewDelegate.events
            .observe(on: UIScheduler())
            .observeValues { [weak self] event in
                self?.processWebViewDelegateEvent(event)
            }
    }

    private func processWebViewDelegateEvent(_ event: BrowserContentWebViewDelegate.Event) {
        let error: Error?
        let pageState: BrowserPageState
        let url: URL?
        switch event {
        case .loadStarted:
            url = nil
            error = nil
            pageState = .loading
        case .loadFailed(let e):
            url = nil
            error = e
            pageState = .noAlbum
        case .loadCompleted(let album):
            url = webView.url
            error = nil
            if let album = album {
                pageState = .album(album)
            } else {
                pageState = .noAlbum
            }
        }

        self.errorView.show(error: error)
        self.webView.isHidden = (error == nil) ? false : true
        self.errorView.isHidden = (error == nil) ? true : false

        mutableState.value = State(
            url: url,
            canGoBack: webView.canGoBack,
            canGoForward: webView.canGoForward,
            pageState: pageState
        )
    }
}

extension Reactive where Base: BrowserContentView {
    var browserChromeViewEvents: BindingTarget<BrowserChromeView.Event> {
        return makeBindingTarget {
            $0.handle(browserChromeViewEvent: $1)
        }
    }
}
