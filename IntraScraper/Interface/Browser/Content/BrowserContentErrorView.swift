import Cocoa
import SnapKit
import ReactiveSwift
import Then

final class BrowserContentErrorView: NSView {

    enum Constants {
        static let maximumErrorMessageWidth = Layout.Grid.units(25)
        static let errorFont = NSFont.systemFont(ofSize: 16)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(error: Error?) {
        errorMessageView.stringValue = error?.localizedDescription ?? ""
    }

    private let errorMessageView = NSTextField().then {
        $0.isBezeled = false
        $0.isEditable = false
        $0.backgroundColor = .clear
        $0.font = Constants.errorFont
        $0.alignment = .center
    }

    private func setup() {
        addSubview(errorMessageView)
        errorMessageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.lessThanOrEqualTo(Constants.maximumErrorMessageWidth)
            $0.width.lessThanOrEqualToSuperview()
        }
    }
}
