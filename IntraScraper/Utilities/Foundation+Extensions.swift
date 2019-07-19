import Foundation
import PromiseKit

extension Error {
    func asPromise<T>() -> Promise<T> {
        return Promise(error: self)
    }
}

extension URL {
    static func fromSloppyString(_ string: String) -> URL? {
        let types: NSTextCheckingResult.CheckingType = [.link]
        guard
            let detector = try? NSDataDetector(types: types.rawValue),
            let match = detector.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
        else { return nil }

        guard match.range.length == string.utf16.count else {
            // The string is only considered a link if the match covers the whole string
            return nil
        }

        return match.url
    }
}

extension URLSession {
    public func cancellableDownloadTask(with convertible: URLRequestConvertible, to saveLocation: URL, overwriteExisting: Bool = false) -> (promise: Promise<(saveLocation: URL, response: URLResponse)>, cancel: () -> Void) {
        let pending = Promise<(saveLocation: URL, response: URLResponse)>.pending()
        let task = downloadTask(with: convertible.pmkRequest, completionHandler: { tmp, rsp, err in
            if let error = err {
                pending.resolver.reject(error)
            } else if let rsp = rsp, let tmp = tmp {

                // Validate HTTP response code
                guard let httpResponse = rsp as? HTTPURLResponse else {
                    pending.resolver.reject(NetworkError.badResponse)
                    return
                }
                guard httpResponse.statusCode >= 200, httpResponse.statusCode <= 299 else {
                    pending.resolver.reject(NetworkError.httpStatusCodeError(httpResponse.statusCode))
                    return
                }

                // Prepare destination
                if overwriteExisting {
                    do {
                        try FileManager.default.removeItem(at: saveLocation)
                    } catch {}
                }

                // Move file to destination
                do {
                    try FileManager.default.moveItem(at: tmp, to: saveLocation)
                    pending.resolver.fulfill((saveLocation, rsp))
                } catch {
                    pending.resolver.reject(error)
                }
            } else {
                pending.resolver.reject(PMKError.invalidCallingConvention)
            }
        })
        task.resume()
        return (pending.promise, { task.cancel() })
    }
}
