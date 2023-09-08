import Flutter
import AVFoundation
import AVFAudio
import UIKit

class Constants{
    static let eventChannelName = "hls_downloader/downloadingStatus"
}

public class SwiftBetterPlayerPlugin: NSObject, FlutterPlugin {
    
    public static let shared = SwiftBetterPlayerPlugin()
    
    public static var viewController = FlutterViewController()
    private var flutterResult: FlutterResult?
    private static var channel : FlutterMethodChannel?
    private static var registrar: FlutterPluginRegistrar?
    
    /// The AVAssetDownloadURLSession to use for managing AVAssetDownloadTasks.
    /// Internal map of AVAggregateAssetDownloadTask to its corresponding Asset.
    fileprivate var downloaderList = [Int: HlsDownloader]()
    
    private var urlAssetObserver: NSKeyValueObservation?
    
    private var textureCount = -1
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        viewController = (UIApplication.shared.delegate?.window??.rootViewController)! as! FlutterViewController
        channel = FlutterMethodChannel(name: "better_player_channel", binaryMessenger: registrar.messenger())
        let instance = SwiftBetterPlayerPlugin.shared
        registrar.addMethodCallDelegate(instance, channel: channel!)
        self.registrar = registrar
    }
    
    
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAssetStateChanged(_:)),
                                               name: .AssetDownloadStateChanged, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAssetProgressChanged(_:)),
                                               name: .AssetDownloadProgress, object: nil)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        flutterResult = result
        switch call.method  {
            
        case "createDownloader": do {
            if let args = call.arguments as? [String: Any], let url = args["url"] as? String, let title = args["title"] as? String, let duration = args["duration"] as? Int {
                let configuration : DownloadConfiguration = DownloadConfiguration(url: url, title: title, duration: duration)
                let textureId = getNewTextureId()
                let channelName = "\(Constants.eventChannelName)\(textureId)"
                let eventChannel = FlutterEventChannel(name: channelName, binaryMessenger: SwiftBetterPlayerPlugin.registrar!.messenger())
                guard let url = URL(string: url.encodeUrl) else {
                    return
                }
                let urlAsset = AVURLAsset(url: url)
                let asset = Asset(textureId: textureId, configuration: configuration, urlAsset: urlAsset)
                let downloader = HlsDownloader(textureId: textureId, asset: asset, eventChannel: eventChannel)
                self.downloaderList[textureId] = downloader
                var results = [String: Any]()
                results["textureId"] = textureId
                flutterResult!(results)
            }
            flutterResult!([String: Any]())
            return
        }
            
        case "cacheOptions": do {
            if let args = call.arguments as? [String: Any], let textureId = args["textureId"] as? Int{
                guard let downloader = getDownloader(textureId: textureId) else {
                    flutterResult!(FlutterError(code: "no_downloader",
                                                message: "Not found download",
                                                details: nil))
                    return
                }
                let results = downloader.getDownloadOptions { message in
                    flutterResult!(FlutterError(code: "Exits",
                                                message: message,
                                                details: nil))
                }
                flutterResult!(results)
            }
            return
        }
            
        case "selectCacheOptions": do {
            if let args = call.arguments as? [String: Any], let textureId = args["textureId"] as? Int, let selectedKey = args["selectedOptionsKey"] as? String{
                guard let downloader = getDownloader(textureId: textureId) else {
                    flutterResult!(FlutterError(code: "no_downloader",
                                                message: "Not found download",
                                                details: nil))
                    return
                }
                downloader.onSelectOption(selectedKey: selectedKey)
                flutterResult!(nil)
            }
            return
        }
            
        case "deleteDownload": do {
            if let args = call.arguments as? [String: Any], let url = args["url"] as? String{
                guard let downloader = getDownloaderByURL(url: url) else {
                    flutterResult!(nil)
                    return
                }
                AssetPersistenceManager.sharedManager.removeDownload(asset: downloader.asset)
                flutterResult!(nil)
            }
            return
        }
            
        case "deleteAllDownload": do {
            AssetPersistenceManager.sharedManager.removeAllDownload()
            flutterResult!(nil)
            return
        }
            
        case "resumeDownload": do {
            if let args = call.arguments as? [String: Any], let url = args["url"] as? String{
                guard let downloader = getDownloaderByURL(url: url) else {
                    flutterResult!(nil)
                    return
                }
                AssetPersistenceManager.sharedManager.resumeDownload(for: downloader.asset)
                flutterResult!(nil)
            }
            return
        }
            
        case "pauseDownload": do {
            if let args = call.arguments as? [String: Any], let url = args["url"] as? String{
                
                guard let downloader = getDownloaderByURL(url: url) else {
                    flutterResult!(nil)
                    return
                }
                AssetPersistenceManager.sharedManager.pauseDownload(for: downloader.asset)
                flutterResult!(nil)
            }
            return
        }
            
        case "getDownloadState": do {
            if let args = call.arguments as? [String: Any], let url = args["url"] as? String{
                let state = AssetPersistenceManager.sharedManager.downloadState(for: url)
                flutterResult!(state.rawValue)
            }
            return
        }
            
        case "getDownloads": do {
            AssetPersistenceManager.sharedManager.getDownloads(successCallback: { results in
                self.flutterResult!(results)
            }, errorCallback: { error in
                self.flutterResult!(FlutterError(code: "error", message: error, details: nil))
            })
            return
        }
            
        case "playIos": do {
            if let args = call.arguments as? [String: Any], let textureId = args["textureId"] as? Int{
                guard let downloader = getDownloader(textureId: textureId) else {
                    flutterResult!(FlutterError(code: "no_downloader",
                                                message: "Not found download",
                                                details: nil))
                    return
                }
                var assetUrl: AVURLAsset?
                assetUrl = self.localAssetForStream(withName: downloader.asset.configuration.url) ?? self.remoteAsset(withName: downloader.asset.configuration.url)
                if assetUrl == nil {return}
                let playerItem = AVPlayerItem(asset: assetUrl!)
                let player = AVPlayer(playerItem: playerItem)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                SwiftBetterPlayerPlugin.viewController.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
                flutterResult!(nil)
            }
            return
        }
        default: do {
            result("Not Implemented")
            return
        }
        }
    }
    
    @objc
    func handleAssetStateChanged(_ notification: Notification) {
        guard let textureId = notification.userInfo![Asset.Keys.textureId] as? Int,
              let downloadStateRawValue = notification.userInfo![Asset.Keys.downloadState] as? String,
              let downloadState = Asset.DownloadState(rawValue: downloadStateRawValue) else {
            return
        }
        guard let downloader = getDownloader(textureId: textureId) else {
            return
        }
        downloader.sinkEvent(state: downloadState, progress: 0, size: 0)
    }
    
    @objc
    func handleAssetProgressChanged(_ notification: Notification) {
        guard let textureId = notification.userInfo![Asset.Keys.textureId] as? Int,
              let downloadStateRawValue = notification.userInfo![Asset.Keys.downloadState] as? String,
              let downloadState = Asset.DownloadState(rawValue: downloadStateRawValue),
              let progress = notification.userInfo![Asset.Keys.percentDownloaded] as? Double else {return}
        let size = notification.userInfo![Asset.Keys.fileSize] as? Int
        guard let downloader = getDownloader(textureId: textureId) else {
            return
        }
        downloader.sinkEvent(state: downloadState, progress: progress, size: size)
    }
    
    func localAssetForStream(withName url: String) -> AVURLAsset? {
        let userDefaults = UserDefaults.standard
        guard let localFileLocation = userDefaults.value(forKey: url) as? Data else {
            return nil
        }
        var bookmarkDataIsStale = false
        do {
            let url = try URL(resolvingBookmarkData: localFileLocation,
                              bookmarkDataIsStale: &bookmarkDataIsStale)
            
            if bookmarkDataIsStale {
                fatalError("Bookmark data is stale!")
            }
            
            let urlAsset = AVURLAsset(url: url)
            
            return urlAsset
        } catch {
            fatalError("Failed to create URL from bookmark with error: \(error)")
        }
    }
    
    func remoteAsset(withName url: String) -> AVURLAsset?{
        var urlAssetResult: AVURLAsset?
        urlAssetObserver?.invalidate()
        guard let url = URL(string: url.encodeUrl) else {
            return nil
        }
        let urlAsset = AVURLAsset(url: url)
        urlAssetObserver = urlAsset.observe(\AVURLAsset.isPlayable, options: [.new, .initial]) { (urlAsset, _) in
            guard urlAsset.isPlayable == true else { return }
            urlAssetResult = urlAsset
        }
        return urlAssetResult
    }
    
    func getNewTextureId() -> Int{
        textureCount += 1
        return textureCount
    }
    
    private func getDownloader(textureId:Int)-> HlsDownloader? {
        return downloaderList[textureId]
    }
    
    func getDownloaderByURL(url: String)-> HlsDownloader? {
        var downloader: HlsDownloader?
        
        for (_, downloaderValue) in downloaderList where url == downloaderValue.asset.configuration.url {
            downloader = downloaderValue
            break
        }
        return downloader
    }
    
    func getDuration(duration: Double) {
        flutterResult!(Int(duration))
    }
}


extension String{
    var encodeUrl : String
    {
        return self.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    var decodeUrl : String
    {
        return self.removingPercentEncoding!
    }
}
