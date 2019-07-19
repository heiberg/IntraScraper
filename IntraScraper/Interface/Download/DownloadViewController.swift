import Cocoa
import SnapKit
import Then
import ReactiveSwift
import ReactiveCocoa
import PromiseKit

final class DownloadViewController: NSViewController {

    enum Constants {
        static let defaultSize = NSSize(width: 475, height: 125)
        static let titleFont = NSFont.boldSystemFont(ofSize: 14)
    }

    struct Dependencies {
        let downloadQueue: DownloadQueue
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    override func loadView() {
        view = NSView().then {
            $0.frame = CGRect(origin: .zero, size: Constants.defaultSize)
       }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private let dependencies: Dependencies

    private let titleView = NSTextField().then {
        $0.isBezeled = false
        $0.isEditable = false
        $0.backgroundColor = .clear
        $0.font = Constants.titleFont
        $0.alignment = .center
    }

    private let progressIndicator = NSProgressIndicator().then {
        $0.style = .bar
        $0.isIndeterminate = false
        $0.doubleValue = 0
        $0.minValue = 0
        $0.maxValue = 1
    }

    private let cancelButton = NSButton(title: "Cancel", target: nil, action: nil).then {
        $0.bezelStyle = .texturedRounded
    }

    private lazy var cancelButtonAction: Action<Void, Void, Never> = Action { [weak self] _ in
        self?.dependencies.downloadQueue.cancel()
        return SignalProducer(value: ())
    }

    private func setup() {
        view.addSubview(titleView)
        titleView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(Layout.Grid.gutter)
        }
        titleView.stringValue = "Downloading \"\(dependencies.downloadQueue.title)\""

        view.addSubview(progressIndicator)
        progressIndicator.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.Grid.gutter)
            $0.centerY.equalToSuperview()
        }
        progressIndicator.reactive.doubleValue <~ dependencies.downloadQueue.progress

        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview().inset(Layout.Grid.gutter)
        }
        cancelButton.reactive.pressed = CocoaAction(cancelButtonAction)
    }
}

