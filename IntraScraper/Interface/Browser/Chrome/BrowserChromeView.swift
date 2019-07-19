import Cocoa
import ReactiveSwift
import ReactiveCocoa
import Then

final class BrowserChromeView: NSView {

    enum Constants {
        static let spacing: CGFloat = Layout.Grid.units(1)
        static let itemHeight: CGFloat = 27
        static let navigationButtonWidth: CGFloat = itemHeight
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Events

    enum Event {
        case reload
        case load(URLRequest)
        case goBack
        case goForward
    }

    var events: Signal<Event, Never> { return eventSignal }
    private let (eventSignal, eventObserver) = Signal<Event, Never>.pipe()

    // MARK: - Public

    func update(browserContentViewState: BrowserContentView.State) {
        backButton.isEnabled = browserContentViewState.canGoBack
        forwardButton.isEnabled = browserContentViewState.canGoForward
        if let addressString = browserContentViewState.url?.absoluteString {
            addressBarView.textField.stringValue = addressString
        }
        reloadButton.isEnabled = (browserContentViewState.url != nil)
        albumView.pageState = browserContentViewState.pageState
    }

    // MARK: - Private

    private let backButton = NSButton(title: "", target: nil, action: nil).then {
        $0.image = NSImage(named: NSImage.goBackTemplateName)
        $0.bezelStyle = .texturedSquare
    }
    private lazy var backButtonAction: Action<Void, Void, Never> = Action { [weak self] _ in
        self?.eventObserver.send(value: .goBack)
        return SignalProducer(value: ())
    }

    private let forwardButton = NSButton(title: "", target: nil, action: nil).then {
        $0.image = NSImage(named: NSImage.goForwardTemplateName)
        $0.bezelStyle = .texturedSquare
    }
    private lazy var forwardButtonAction: Action<Void, Void, Never> = Action { [weak self] _ in
        self?.eventObserver.send(value: .goForward)
        return SignalProducer(value: ())
    }

    private let addressBarView = BrowserChromeAddressBarView()

    private let reloadButton = NSButton(title: "", target: nil, action: nil).then {
        $0.image = NSImage(named: NSImage.refreshTemplateName)
        $0.bezelStyle = .texturedSquare
    }
    private lazy var reloadButtonAction: Action<Void, Void, Never> = Action { [weak self] _ in
        self?.eventObserver.send(value: .reload)
        return SignalProducer(value: ())
    }

    private let albumView = BrowserChromeAlbumView()

    private func setup() {
        addSubview(backButton)
        backButton.snp.makeConstraints {
            $0.top.equalToSuperview().inset(Constants.spacing)
            $0.leading.equalToSuperview().inset(Layout.Grid.gutter)
            $0.height.equalTo(Constants.itemHeight)
            $0.width.equalTo(Constants.navigationButtonWidth)
        }
        backButton.reactive.pressed = CocoaAction(backButtonAction)

        addSubview(forwardButton)
        forwardButton.snp.makeConstraints {
            $0.top.equalToSuperview().inset(Constants.spacing)
            $0.leading.equalTo(backButton.snp.trailing)
            $0.height.equalTo(Constants.itemHeight)
            $0.width.equalTo(Constants.navigationButtonWidth)
        }
        forwardButton.reactive.pressed = CocoaAction(forwardButtonAction)

        addSubview(addressBarView)
        addressBarView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(Constants.spacing)
            $0.leading.equalTo(forwardButton.snp.trailing).offset(Constants.spacing)
            $0.height.equalTo(Constants.itemHeight)
        }
        addressBarView.textField.reactive.stringValues
            .observe(on: UIScheduler())
            .observeValues { [weak self] addressString in
                self?.attemptLoad(addressString: addressString)
            }

        addSubview(reloadButton)
        reloadButton.snp.makeConstraints {
            $0.top.equalToSuperview().inset(Constants.spacing)
            $0.leading.equalTo(addressBarView.snp.trailing).offset(Constants.spacing)
            $0.trailing.equalToSuperview().inset(Layout.Grid.gutter)
            $0.height.equalTo(Constants.itemHeight)
            $0.width.equalTo(Constants.navigationButtonWidth)
        }
        reloadButton.reactive.pressed = CocoaAction(reloadButtonAction)

        addSubview(albumView)
        albumView.snp.makeConstraints {
            $0.top.equalTo(addressBarView.snp.bottom).offset(Constants.spacing)
            $0.bottom.equalToSuperview().inset(Constants.spacing)
            $0.leading.trailing.equalToSuperview().inset(Layout.Grid.gutter)
        }
        albumView.events
            .observe(on: UIScheduler())
            .observeValues { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .download(let album):
                    guard let window = self.window else { break }
                    let albumDownloaderDependencies = AlbumDownloader.Dependencies(window: window)
                    let albumDownloader = AlbumDownloader(dependencies: albumDownloaderDependencies)
                    albumDownloader.download(album: album)
                }
            }

        let bottomSeparator = NSView().then {
            $0.wantsLayer = true
            $0.layer?.backgroundColor = NSColor.gray.cgColor
        }
        addSubview(bottomSeparator)
        bottomSeparator.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }

    private func attemptLoad(addressString: String?) {
        guard
            let addressString = addressString,
            let url = URL.fromSloppyString(addressString)
        else { return }

        self.eventObserver.send(value: .load(URLRequest(url: url)))
    }
}

extension Reactive where Base: BrowserChromeView {
    var browserContentViewState: BindingTarget<BrowserContentView.State> {
        return makeBindingTarget {
            $0.update(browserContentViewState: $1)
        }
    }
}
