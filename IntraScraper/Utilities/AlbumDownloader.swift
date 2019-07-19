import Foundation
import AppKit
import PromiseKit
import Then

final class AlbumDownloader {
    enum Error: Swift.Error {
        case badPath(String)

        var localizedDescription: String {
            switch self {
            case .badPath(let path):
                return "Bad path in album: \(path)"
            }
        }
    }

    struct Dependencies {
        let window: NSWindow
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func download(album: Album) {
        firstly {
            chooseFolder()
        }.then {
            self.planDownloads(from: album, to: $0)
        }.then {
            self.getOverwritePermissionIfNeeded(downloadDescriptions: $0)
        }.then {
            self.startDownloads(title: album.title, downloadDescriptions: $0)
        }.catch { error in
            self.showError(album: album, error: error)
        }
    }

    // MARK: - Private

    private let dependencies: Dependencies

    private func planDownloads(from album: Album, to
        destinationDirectory: URL) -> Promise<[DownloadDescription]> {
        var downloadDescriptions: [DownloadDescription] = []
        for (index, item) in album.items.enumerated() {
            // Using appendingPathComponent will URL-escape the query parameter ?-sign in the path.
            guard let remoteURL = URL(string: album.url.absoluteString + item.path) else {
                return Error.badPath(item.path).asPromise()
            }

            let localFilename = String(format: "image_%04d.jpg", index + 1)
            let localURL = destinationDirectory.appendingPathComponent(localFilename)

            downloadDescriptions.append(DownloadDescription(
                remoteURL: remoteURL,
                localURL: localURL))
        }
        return .value(downloadDescriptions)
    }

    private func getOverwritePermissionIfNeeded(downloadDescriptions: [DownloadDescription]) -> Promise<[DownloadDescription]> {
        let conflictingFiles = downloadDescriptions
            .filter { FileManager.default.fileExists(atPath: $0.localURL.path) }

        if conflictingFiles.isEmpty {
            return .value(downloadDescriptions)
        }

        let alert = NSAlert().then {
            $0.messageText = "One or more files will be overwritten!"
            $0.informativeText = "Do you want to continue, and overwrite any pre-existing files in the download location?"
            $0.alertStyle = .warning
            $0.addButton(withTitle: "OK")
            $0.addButton(withTitle: "Cancel")
        }

        let permissionGranted = (alert.runModal() == .alertFirstButtonReturn)

        if permissionGranted {
            return .value(downloadDescriptions)
        } else {
            return PMKError.cancelled.asPromise()
        }
    }

    private func chooseFolder() -> Promise<URL> {
        let openPanel = NSOpenPanel().then {
            $0.title = "Select a Folder"
            $0.message = "Choose or create a folder to save the album images to."
            $0.showsResizeIndicator = true
            $0.canChooseDirectories = true
            $0.canChooseFiles = false
            $0.allowsMultipleSelection = false
            $0.canCreateDirectories = true
        }

        let pending = Promise<URL>.pending()

        openPanel.beginSheetModal(for: dependencies.window) { result -> Void in
            guard
                result == NSApplication.ModalResponse.OK,
                let url = openPanel.url
            else {
                pending.resolver.reject(PMKError.cancelled)
                return
            }
            pending.resolver.fulfill(url)
        }

        return pending.promise
    }

    private func startDownloads(title: String, downloadDescriptions: [DownloadDescription]) -> Promise<Void> {
        let downloadQueue = DownloadQueue(dependencies: DownloadQueue.Dependencies(title: title, downloadDescriptions: downloadDescriptions))
        let downloadViewController = DownloadViewController(dependencies: DownloadViewController.Dependencies(downloadQueue: downloadQueue))
        let sheetWindow = NSWindow(contentViewController: downloadViewController)
        dependencies.window.beginSheet(sheetWindow)
        return downloadQueue.promise.ensure {
            self.dependencies.window.endSheet(sheetWindow)
        }
    }

    private func showError(album: Album, error: Swift.Error? = nil) {
        var informativeText = "There was an error downloading images from the album \"\(album.title)\"."
        if let error = error, !error.localizedDescription.isEmpty {
            informativeText += "\n\n" + error.localizedDescription
        }

        let alert = NSAlert().then {
            $0.messageText = "Album Download Failed"
            $0.informativeText = informativeText
            $0.alertStyle = .warning
            $0.addButton(withTitle: "OK")
        }

        alert.runModal()
    }
}
