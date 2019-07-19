import WebKit
import ReactiveSwift
import PromiseKit

final class BrowserContentWebViewDelegate: NSObject, WKNavigationDelegate {
    enum Event {
        case loadStarted
        case loadFailed(Error)
        case loadCompleted(Album?)
    }

    var events: Signal<Event, Never> { return eventSignal }
    private let (eventSignal, eventObserver) = Signal<Event, Never>.pipe()

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        eventObserver.send(value: .loadFailed(error))
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        eventObserver.send(value: .loadStarted)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        firstly {
            WKWebsiteDataStore.default().httpCookieStore.writeCookies(to: HTTPCookieStorage.shared)
        }.then {
            AlbumParser.album(in: webView)
        }.done {
            self.eventObserver.send(value: .loadCompleted($0))
        }.catch { _ in
            self.eventObserver.send(value: .loadCompleted(nil))
        }
    }
}
