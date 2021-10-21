//import Foundation
//import Flutter
//import AVKit
//import AVFoundation
//import GLKit
//
//
//
//class BetterPlayer: NSObject, FlutterPlatformView, FlutterStreamHandler, AVPictureInPictureControllerDelegate {
//
//    func view() -> UIView {
//        <#code#>
//    }
//
//    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
//        <#code#>
//    }
//
//    func onCancel(withArguments arguments: Any?) -> FlutterError? {
//        <#code#>
//    }
//
//    var player: AVPlayer
//    var loaderDelegate: BetterPlayerEzDrmAssetsLoaderDelegate
//    var eventChannel: FlutterEventChannel
//    var eventSink: FlutterEventSink
//    var preferredTransform: CGAffineTransform
//    var disposed: Bool
//    var isPlaying: Bool
//    var isLooping: Bool
//    var isInitialized: Bool
//    var key: String
//    var failedCount: CInt = 0
//    var playerLayer: AVPlayerLayer
//    var pictureInPicture: Bool
//    var observersAdded: Bool
//    var stalledCount: CInt = 0
//    var isStalledCheckStarted: Bool
//    var playerRate: CFloat = 0.0
//    var overriddenDuration: CInt = 0
//    var lastAvPlayerTimeControlStatus: AVPlayer.TimeControlStatus
//
//    init(frame: CGRect) {
////        self = super.init()
//
////        NSAssert(self, "super init cannot be nil")
//
//        isInitialized = false
//
//        isPlaying = false
//
//        disposed = false
//
//        player = AVPlayer()
//        player.actionAtItemEnd = AVPlayerActionAtItemEndNon
//
//        ///Fix for loading large videos
//        if available() {
//            player.automaticallyWaitsToMinimizeStalling = false
//        }
//
//        self.observersAdded = false
//
//        return self
//    }
//
//    func getView() -> UIView {
//
//        var playerView = BetterPlayerView(frame: CGRect.zero)
//
//           playerView.player = player
//
//           return playerView
//       }
//
////    init(frame: CGRect) {
////    }
////
////    func play() {
////    }
////    func pause() {
////    }
////    func updatePlayingState() {
////    }
////    func duration() -> Int64 {
////    }
////    func position() -> Int64 {
////    }
////
////    func setMixWithOthers(_ mixWithOthers: Bool) {
////    }
////
////    func seekTo(_ location: CInt) {
////    }
////    func setDataSourceAsset(_ asset: String, withKey key: String, withCertificateUrl certificateUrl: String, withLicenseUrl licenseUrl: String, cacheKey: String, cacheManager: CacheManager, overriddenDuration: CInt) {
////    }
////    func setDataSourceURL(_ url: URL, withKey key: String, withCertificateUrl certificateUrl: String, withLicenseUrl licenseUrl: String, withHeaders headers: NSDictionary, withCache useCache: Bool, cacheKey: String, cacheManager: CacheManager, overriddenDuration: CInt, videoExtension: String) {
////    }
////    func setVolume(_ volume: CDouble) {
////    }
////    func setSpeed(_ speed: CDouble, result: FlutterResult) {
////    }
////    func setAudioTrack(_ name: String, index: CInt) {
////    }
////    func setTrackParameters(_ width: CInt, _ height: CInt, _ bitrate: CInt) {
////    }
////    func enablePictureInPicture(_ frame: CGRect) {
////    }
////    func setPictureInPicture(_ pictureInPicture: Bool) {
////    }
////    func disablePictureInPicture() {
////    }
////    func absolutePosition() -> Int64 {
////    }
////
////    func FLTCMTimeToMillis(_ time: CMTime) -> Int64 {
////    }
////
////    func clear() {
////    }
////
////    func disposeSansEventChannel() {
////    }
////
////    func dispose() {
////    }
//
//}
