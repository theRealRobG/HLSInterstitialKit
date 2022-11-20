import Foundation

struct AssetListResponse: Encodable {
    let assets: [HLSInterstitialEvent.Asset]

    enum CodingKeys: String, CodingKey {
        case assets = "ASSETS"
    }
}
