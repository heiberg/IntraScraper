import Foundation
import ReactiveSwift
import PromiseKit

final class DownloadQueue {

    struct Dependencies {
        let title: String
        let downloadDescriptions: [DownloadDescription]
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        startDownloads()
    }

    var title: String {
        return dependencies.title
    }

    var promise: Promise<Void> {
        return pending.promise
    }

    var progress: Property<Double> {
        return Property(mutableProgress)
    }

    func cancel() {
        isCancelled = true
        cancelActiveDownload?()
    }

    // MARK: - Private

    private let dependencies: Dependencies
    private var pending = Promise<Void>.pending()
    private let mutableProgress = MutableProperty<Double>(0)
    private var isCancelled = false
    private var cancelActiveDownload: (() -> Void)?

    private func startDownloads() {
        var fifo: Promise<Void> = .value(())

        for (index, download) in dependencies.downloadDescriptions.enumerated() {
            fifo = fifo.then { _ -> Promise<Void> in
                guard !self.isCancelled else { throw PMKError.cancelled }
                self.mutableProgress.value = Double(index) / Double(self.dependencies.downloadDescriptions.count)

                let downloadTask = URLSession.shared.cancellableDownloadTask(
                    with: URLRequest(url: download.remoteURL),
                    to: download.localURL,
                    overwriteExisting: true)

                self.cancelActiveDownload = {
                    downloadTask.cancel()
                }

                return downloadTask.promise.asVoid()
            }
        }

        fifo = firstly {
            fifo
        }.get { _ in
            self.mutableProgress.value = 1
        }

        fifo.pipe(to: pending.resolver.resolve)
    }
}
