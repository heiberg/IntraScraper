import Foundation
import AppKit
import ReactiveSwift
import ReactiveCocoa

extension Reactive where Base: NSProgressIndicator {
    var doubleValue: BindingTarget<Double> {
        return makeBindingTarget {
            $0.doubleValue = $1
        }
    }
}
