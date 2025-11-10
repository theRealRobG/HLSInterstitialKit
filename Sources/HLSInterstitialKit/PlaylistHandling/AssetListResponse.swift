import Foundation

struct AssetListResponse: Encodable {
    let assets: [HLSInterstitialEvent.Asset]
    let tracking: Tracking

    enum CodingKeys: String, CodingKey {
        case assets = "ASSETS"
        case tracking = "TRACKING"
    }
}

struct Tracking: Encodable {
    let id: String
    let urls: [String]

    init() {
        self.id = "test"
        self.urls = ["https://example.com/beacons/impression.png", "https://example.com/beacons/complete.png"]
    }
}
