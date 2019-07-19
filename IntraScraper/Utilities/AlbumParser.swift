import Foundation
import WebKit
import PromiseKit

enum AlbumParser {
    static func album(in webView: WKWebView) -> Promise<Album> {
        return firstly {
            webView.evaluateJavaScript(.promise, AlbumParser.albumJS)
        }.compactMap {
            $0 as? [String: Any]
        }.map {
            let data = try JSONSerialization.data(withJSONObject: $0, options: [])
            let album = try JSONDecoder().decode(Album.self, from: data)
            return album
        }
    }

    // MARK: - Private

    private static let albumJS = """
var album = document.getElementsByClassName('sk-photoalbums')[0];

var title = 'Untitled';
try {
    title = album.getElementsByClassName('h-ta-c')[0].innerText;
} catch {}

var albumJSON = JSON.parse(album.getAttribute('data-clientlogic-settings-photoalbum'));
var items = albumJSON['GalleryModel']['Items'].map(function (item) {
    return {
        "path": item["Source"],
        "description": item["Description"] || "No description",
    };
});

var result = {
    "url": window.location.origin,
    "title": title,
    "items": items
};

result;
"""

}
