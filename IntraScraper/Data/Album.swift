import Foundation

struct Album: Decodable {
    let url: URL
    let title: String
    let items: [AlbumItem]
}

struct AlbumItem: Decodable {
    let path: String
    let description: String?
}
