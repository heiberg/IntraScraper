import Foundation

enum BrowserPageState {
    case initial
    case loading
    case noAlbum
    case album(Album)
}
