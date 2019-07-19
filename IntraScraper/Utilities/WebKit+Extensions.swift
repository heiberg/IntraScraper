import Foundation
import WebKit
import PromiseKit

extension WKWebView {
    func evaluateJavaScript(_ namespacer: PMKNamespacer, _ javascript: String) -> Promise<Any?> {
        let (promise, resolver) = Promise<Any?>.pending()

        DispatchQueue.main.async { [weak self] in
            self?.evaluateJavaScript(javascript) { result, error in
                if let error = error {
                    resolver.reject(error)
                } else {
                    resolver.fulfill(result)
                }
            }
        }

        return promise
    }
}

extension WKHTTPCookieStore {
    func writeCookies(to storage: HTTPCookieStorage) -> Promise<Void> {
        return Promise { seal in
            getAllCookies { cookies in
                for cookie in cookies {
                    storage.setCookie(cookie)
                }
                seal.fulfill(())
            }
        }
    }
}
