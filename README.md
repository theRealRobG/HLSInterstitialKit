# HLSInterstitialKit
This package is intended to provide a manifest stitching approach to integrate with the new proposal for HLS Interstitials. This is more of a fun side-project, that demonstrates the concept of client-side manifest stitching as a methodology for modifying playback, because Apple are providing an official client API for scheduling interstitial events, and so there is actually little to no technical reason to use this methodology (as far as I can see).

The implementation is based on revision `1.0b3` of the [Getting Started With HLS Interstitials](https://developer.apple.com/streaming/GettingStartedWithHLSInterstitials.pdf) guide.

This repo contains the `Sources` for the manifest stitching approach, and also, a [reference app](./ReferenceApp/ReferenceApp.xcodeproj) that demonstrates utilisation and functionality of the package. Currently, the reference app has a hard-coded expectation of which provisioning profile it expects, but anyone pulling the repo can just update this to one that makes sense for them; but bear in mind, that any provisioning profile used, will need to have the `com.apple.developer.coremedia.hls.interstitial-preview` entitlement.
