import Foundation
import AppKit
import SnapKit

final class BrowserChromeAddressBarView: NSView {

    let textField = NSTextField().then {
        $0.placeholderString = "Website Address"
        $0.font = .systemFont(ofSize: 14)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setup() {
        addSubview(textField)
        textField.snp.makeConstraints {
            $0.leading.trailing.centerY.equalToSuperview()
        }
    }
}
