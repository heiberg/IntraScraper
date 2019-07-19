import Cocoa
import SnapKit
import ReactiveSwift
import ReactiveCocoa
import Then

final class BrowserChromeAlbumView: NSView {

    enum Constants {
        static let itemHeight: CGFloat = Layout.Grid.units(2)
        static let statusMessageFont = NSFont.systemFont(ofSize: 16)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - State

    var pageState: BrowserPageState = .initial {
        didSet {
            update()
        }
    }

    // MARK: - Events

    enum Event {
        case download(Album)
    }

    var events: Signal<Event, Never> { return eventSignal }
    private let (eventSignal, eventObserver) = Signal<Event, Never>.pipe()

    // MARK: - Private

    private let statusMessageView = NSTextField().then {
        $0.isBezeled = false
        $0.isEditable = false
        $0.backgroundColor = .clear
        $0.font = Constants.statusMessageFont
        $0.alignment = .center
    }
    
    private let downloadButton = NSButton(title: "", target: nil, action: nil).then {
        $0.keyEquivalent = "\r"
        $0.bezelStyle = .rounded
    }

    private lazy var downloadButtonAction: Action<Void, Void, Never> = Action { [weak self] _ in
        if let self = self, case let .album(album) = self.pageState {
            self.eventObserver.send(value: .download(album))
        }
        return SignalProducer(value: ())
    }

    private func setup() {
        setContentHuggingPriority(.defaultHigh, for: .vertical)

        addSubview(statusMessageView)
        statusMessageView.snp.makeConstraints {
            $0.top.bottom.centerX.equalToSuperview()
            $0.width.lessThanOrEqualToSuperview()
            $0.height.equalTo(Constants.itemHeight)
        }
        statusMessageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        addSubview(downloadButton)
        downloadButton.snp.makeConstraints {
            $0.top.bottom.centerX.equalToSuperview()
            $0.width.lessThanOrEqualToSuperview()
            $0.height.equalTo(Constants.itemHeight)
        }
        downloadButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        downloadButton.reactive.pressed = CocoaAction(downloadButtonAction)

        update()
    }

    private func update() {
        switch pageState {
        case .initial:
            downloadButton.isHidden = true
            statusMessageView.isHidden = false
            statusMessageView.stringValue = "Use the address bar to navigate to an Intra album."
        case .loading:
            downloadButton.isHidden = true
            statusMessageView.isHidden = false
            statusMessageView.stringValue = "Loading..."
        case .noAlbum:
            downloadButton.isHidden = true
            statusMessageView.isHidden = false
            statusMessageView.stringValue = "No album found on this page."
        case .album(let album):
            downloadButton.isHidden = false
            downloadButton.title = "Download album \"\(album.title)\""
            downloadButton.sizeToFit()
            statusMessageView.isHidden = true
        }
    }
}
