import Foundation

enum Layout {
    enum Grid {
        static let unit: CGFloat = 11
        static let gutter = unit

        static func units(_ num: CGFloat) -> CGFloat {
            return unit * num
        }
    }
}
