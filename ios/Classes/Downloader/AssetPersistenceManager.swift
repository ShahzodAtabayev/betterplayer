/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 `AssetPersistenceManager` is the main class in this sample that demonstrates how to
 manage downloading HLS streams.  It includes APIs for starting and canceling downloads,
 deleting existing assets off the users device, and monitoring the download progress.
 */

import Foundation
import AVFoundation

/// - Tag: AssetPersistenceManager
class AssetPersistenceManager: NSObject {
    // MARK: Properties
    
    /// Singleton for AssetPersistenceManager.
    static let sharedManager = AssetPersistenceManager()
    
    /// Internal Bool used to track if the AssetPersistenceManager finished restoring its state.
    private var didRestorePersistenceManager = false
    
    /// The AVAssetDownloadURLSession to use for managing AVAssetDownloadTasks.
    fileprivate var assetDownloadURLSession: AVAssetDownloadURLSession!
    
    /// Internal map of AVAggregateAssetDownloadTask to its corresponding Asset.
    fileprivate var activeDownloadsMap = [AVAggregateAssetDownloadTask: Asset]()
    
    /// Internal map of AVAggregateAssetDownloadTask to download URL.
    fileprivate var willDownloadToUrlMap = [AVAggregateAssetDownloadTask: URL]()
    
    fileprivate let downloadIdentifier = "\(Bundle.main.bundleIdentifier!).background"
    
    // MARK: Intialization
    
    override private init() {
        
        super.init()
        
        // Create the configuration for the AVAssetDownloadURLSession.
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: downloadIdentifier)
        
        // Create the AVAssetDownloadURLSession using the configuration.
        assetDownloadURLSession =
        AVAssetDownloadURLSession(configuration: backgroundConfiguration,
                                  assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
    }
    
    /// Restores the Application state by getting all the AVAssetDownloadTasks and restoring their Asset structs.
    func restorePersistenceManager() {
        guard !didRestorePersistenceManager else { return }
        
        didRestorePersistenceManager = true
        
        // Grab all the tasks associated with the assetDownloadURLSession
        assetDownloadURLSession.getAllTasks { tasksArray in
            // For each task, restore the state in the app by recreating Asset structs and reusing existing AVURLAsset objects.
            for task in tasksArray {
                guard let assetDownloadTask = task as? AVAggregateAssetDownloadTask else { break }
                
                let urlAsset = assetDownloadTask.urlAsset
                
                let configuration = DownloadConfiguration(url: urlAsset.url.absoluteString, title: urlAsset.url.absoluteString, duration: 0)
                
                let asset = Asset(textureId: -1, configuration: configuration, urlAsset: urlAsset)
                
                self.activeDownloadsMap[assetDownloadTask] = asset
            }
            
            NotificationCenter.default.post(name: .AssetPersistenceManagerDidRestoreState, object: nil)
        }
    }
    
    func getDownloads(successCallback:@escaping ([[String:Any]]) -> Void, errorCallback: (String) -> ())  {
        
        var downloads = [[String:Any]]()
        // Grab all the tasks associated with the assetDownloadURLSession
        assetDownloadURLSession.getAllTasks { tasksArray in
            // For each task, restore the state in the app by recreating Asset structs and reusing existing AVURLAsset objects.
            for task in tasksArray {
                guard let assetDownloadTask = task as? AVAggregateAssetDownloadTask else { break }
                let urlAsset = assetDownloadTask.urlAsset
                let configuration = DownloadConfiguration(url: urlAsset.url.absoluteString, title: urlAsset.url.absoluteString, duration: 0)
                let asset = Asset(textureId: -1, configuration: configuration, urlAsset: urlAsset)
                var download = [String: Any]()
                download["url"] = urlAsset.url.absoluteString
                download["state"] = self.downloadState(for: urlAsset.url.absoluteString).rawValue
                download["percent_downloaded"] = Double((assetDownloadTask.progress.completedUnitCount / assetDownloadTask.progress.totalUnitCount) * 100)
                downloads.append(download)
                self.activeDownloadsMap[assetDownloadTask] = asset
            }
            successCallback(downloads)
            NotificationCenter.default.post(name: .AssetPersistenceManagerDidRestoreState, object: nil)
        }
    }
    
    /// Triggers the initial AVAssetDownloadTask for a given Asset.
    /// - Tag: DownloadStream
    func downloadStream(for asset: Asset, selec selection: AVMediaSelection?) -> AVAggregateAssetDownloadTask? {
        
        // Get the default media selections for the asset's media selection groups.
        let preferredMediaSelection = selection ?? asset.urlAsset.preferredMediaSelection
        
        /*
         Creates and initializes an AVAggregateAssetDownloadTask to download multiple AVMediaSelections
         on an AVURLAsset.
         
         For the initial download, we ask the URLSession for an AVAssetDownloadTask with a minimum bitrate
         corresponding with one of the lower bitrate variants in the asset.
         */
        guard let task =
                assetDownloadURLSession.aggregateAssetDownloadTask(with: asset.urlAsset,
                                                                   mediaSelections: [preferredMediaSelection],
                                                                   assetTitle: asset.configuration.title,
                                                                   assetArtworkData: nil,
                                                                   options:
                                                                    [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 150000]) else { return nil }
        
        // To better track the AVAssetDownloadTask, set the taskDescription to something unique for the sample.
        task.taskDescription = asset.configuration.url
        
        activeDownloadsMap[task] = asset
        
        task.resume()
        
        var userInfo = [String: Any]()
        userInfo[Asset.Keys.textureId] = asset.textureId
        userInfo[Asset.Keys.name] = asset.configuration.title
        userInfo[Asset.Keys.downloadState] = Asset.DownloadState.downloading.rawValue
        userInfo[Asset.Keys.fileSize] = task.countOfBytesExpectedToSend
        userInfo[Asset.Keys.downloadSelectionDisplayName] = displayNamesForSelectedMediaOptions(preferredMediaSelection)
        NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
        
        return task
    }
    
    
    /// Returns an Asset given a specific name if that Asset is associated with an active download.
    func assetForStream(withName name: String) -> Asset? {
        var asset: Asset?
        
        for (_, assetValue) in activeDownloadsMap where name == assetValue.configuration.title {
            asset = assetValue
            break
        }
        
        return asset
    }
    
    /// Returns an Asset pointing to a file on disk if it exists.
    func localAssetForStream(withUrl urlString: String) -> AVURLAsset? {
        let userDefaults = UserDefaults.standard
        guard let localFileLocation = userDefaults.value(forKey: urlString) as? Data else { return nil }
        var bookmarkDataIsStale = false
        do {
            let url = try URL(resolvingBookmarkData: localFileLocation,
                              bookmarkDataIsStale: &bookmarkDataIsStale)
            if bookmarkDataIsStale {
                print("Bookmark data is stale!")
            }
            let urlAsset = AVURLAsset(url: url)
            return urlAsset
        } catch {
            print("Failed to create URL from bookmark with error: \(error)")
        }
        return nil
    }
    
    /// Returns the current download state for a given Asset.
    func downloadState(for url: String) -> Asset.DownloadState {
        // Check if there is a file URL stored for this asset.
        if let localFileLocation = localAssetForStream(withUrl: url)?.url {
            // Check if the file exists on disk
            if FileManager.default.fileExists(atPath: localFileLocation.path) {
                return .completed
            }
        }
        
        // Check if there are any active downloads in flight.
        for (task, assetValue) in activeDownloadsMap where url == assetValue.configuration.url {
            return getState(state: task.state.rawValue)
        }
        return .initial
    }
    
    func removeDownload(asset: Asset){
        let userDefaults = UserDefaults.standard
        do {
            if let localFileLocation = localAssetForStream(withUrl: asset.configuration.url)?.url {
                try FileManager.default.removeItem(at: localFileLocation)
                userDefaults.removeObject(forKey: asset.configuration.url)
                var task: AVAggregateAssetDownloadTask?
                for (taskKey, assetVal) in activeDownloadsMap where asset == assetVal {
                    task = taskKey
                    break
                }
                task?.cancel()
                var userInfo = [String: Any]()
                userInfo[Asset.Keys.textureId] = asset.textureId
                userInfo[Asset.Keys.name] = asset.configuration.title
                userInfo[Asset.Keys.url] = asset.configuration.url
                userInfo[Asset.Keys.downloadState] = Asset.DownloadState.initial.rawValue
                NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil,
                                                userInfo: userInfo)
            }
        } catch {
            //            errorCallback("An error occured deleting the file: \(error)")
            print("An error occured deleting the file: \(error)")
        }
    }
    
    /// Cancels an AVAssetDownloadTask given an Asset.
    /// - Tag: CancelDownload
    func cancelDownload(for asset: Asset) {
        var task: AVAggregateAssetDownloadTask?
        
        for (taskKey, assetVal) in activeDownloadsMap where asset == assetVal {
            task = taskKey
            break
        }
        guard let task = task else { return }
        task.cancel()
        var userInfo = [String: Any]()
        userInfo[Asset.Keys.textureId] = asset.textureId
        userInfo[Asset.Keys.name] = asset.configuration.title
        userInfo[Asset.Keys.downloadState] = Asset.DownloadState.initial.rawValue
        NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
    }
    
    func pauseDownload(for asset: Asset)  {
        var task: AVAggregateAssetDownloadTask?
        for (taskKey, assetVal) in activeDownloadsMap where asset == assetVal {
            task = taskKey
            break
        }
        guard let task = task else { return }
        task.suspend()
        var userInfo = [String: Any]()
        userInfo[Asset.Keys.textureId] = asset.textureId
        userInfo[Asset.Keys.name] = asset.configuration.title
        userInfo[Asset.Keys.downloadState] = Asset.DownloadState.stopped.rawValue
        NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
    }
    
    func resumeDownload(for asset: Asset)  {
        var task: AVAggregateAssetDownloadTask?
        for (taskKey, assetVal) in activeDownloadsMap where asset == assetVal {
            task = taskKey
            break
        }
        guard let task = task else { return }
        task.resume()
        var userInfo = [String: Any]()
        userInfo[Asset.Keys.textureId] = asset.textureId
        userInfo[Asset.Keys.name] = asset.configuration.title
        userInfo[Asset.Keys.downloadState] = Asset.DownloadState.downloading.rawValue
        NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
    }
    
    func removeAllDownload()  {
        for (_, assetVal) in activeDownloadsMap {
            self.removeDownload(asset: assetVal)
        }
    }
}

/// Return the display names for the media selection options that are currently selected in the specified group
func displayNamesForSelectedMediaOptions(_ mediaSelection: AVMediaSelection) -> String {
    
    var displayNames = ""
    
    guard let asset = mediaSelection.asset else {
        return displayNames
    }
    
    // Iterate over every media characteristic in the asset in which a media selection option is available.
    for mediaCharacteristic in asset.availableMediaCharacteristicsWithMediaSelectionOptions {
        /*
         Obtain the AVMediaSelectionGroup object that contains one or more options with the
         specified media characteristic, then get the media selection option that's currently
         selected in the specified group.
         */
        guard let mediaSelectionGroup =
                asset.mediaSelectionGroup(forMediaCharacteristic: mediaCharacteristic),
              let option = mediaSelection.selectedMediaOption(in: mediaSelectionGroup) else { continue }
        
        // Obtain the display string for the media selection option.
        if displayNames.isEmpty {
            displayNames += " " + option.displayName
        } else {
            displayNames += ", " + option.displayName
        }
    }
    
    return displayNames
}

/**
 Extend `AssetPersistenceManager` to conform to the `AVAssetDownloadDelegate` protocol.
 */
extension AssetPersistenceManager: AVAssetDownloadDelegate {
    
    /// Tells the delegate that the task finished transferring data.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let userDefaults = UserDefaults.standard
        
        /*
         This is the ideal place to begin downloading additional media selections
         once the asset itself has finished downloading.
         */
        guard let task = task as? AVAggregateAssetDownloadTask,
              let asset = activeDownloadsMap.removeValue(forKey: task) else { return }
        
        guard let downloadURL = willDownloadToUrlMap.removeValue(forKey: task) else { return }
        
        // Prepare the basic userInfo dictionary that will be posted as part of our notification.
        var userInfo = [String: Any]()
        userInfo[Asset.Keys.textureId] = asset.textureId
        userInfo[Asset.Keys.name] = asset.configuration.title
        if let error = error as NSError? {
            switch (error.domain, error.code) {
            case (NSURLErrorDomain, NSURLErrorCancelled):
                /*
                 This task was canceled, you should perform cleanup using the
                 URL saved from AVAssetDownloadDelegate.urlSession(_:assetDownloadTask:didFinishDownloadingTo:).
                 */
                guard let localFileLocation = localAssetForStream(withUrl: asset.configuration.url)?.url else {
                    userInfo[Asset.Keys.downloadState] = Asset.DownloadState.failed.rawValue
                    return }
                
                do {
                    try FileManager.default.removeItem(at: localFileLocation)
                    userDefaults.removeObject(forKey: asset.configuration.url)
                    userInfo[Asset.Keys.downloadState] = Asset.DownloadState.initial.rawValue
                } catch {
                    print("An error occured trying to delete the contents on disk for \(asset.configuration.url): \(error)")
                    userInfo[Asset.Keys.downloadState] = Asset.DownloadState.failed.rawValue
                }
                
            case (NSURLErrorDomain, NSURLErrorUnknown):
                userInfo[Asset.Keys.downloadState] = Asset.DownloadState.failed.rawValue
//                fatalError("Downloading HLS streams is not supported in the simulator.")
            default:
                userInfo[Asset.Keys.downloadState] = Asset.DownloadState.failed.rawValue
//                fatalError("An unexpected error occured \(error.domain)")
            }
        } else {
            do {
                let bookmark = try downloadURL.bookmarkData()
                userDefaults.set(bookmark, forKey: asset.configuration.url)
                userInfo[Asset.Keys.downloadSelectionDisplayName] = ""
                userInfo[Asset.Keys.downloadState] = getState(state: task.state.rawValue).rawValue
                userInfo[Asset.Keys.fileSize] = task.countOfBytesReceived
            } catch {
                print("Failed to create bookmarkData for download URL.")
            }
        }
      
        NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
    }
    
    /// Method called when the an aggregate download task determines the location this asset will be downloaded to.
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    willDownloadTo location: URL) {
        
        /*
         This delegate callback should only be used to save the location URL
         somewhere in your application. Any additional work should be done in
         `URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)`.
         */
        
        willDownloadToUrlMap[aggregateAssetDownloadTask] = location
    }
    
    /// Method called when a child AVAssetDownloadTask completes.
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    didCompleteFor mediaSelection: AVMediaSelection) {
        /*
         This delegate callback provides an AVMediaSelection object which is now fully available for
         offline use. You can perform any additional processing with the object here.
         */
        
        guard let asset = activeDownloadsMap[aggregateAssetDownloadTask] else { return }
        
        // Prepare the basic userInfo dictionary that will be posted as part of our notification.
        var userInfo = [String: Any]()
        userInfo[Asset.Keys.textureId] = asset.textureId
        userInfo[Asset.Keys.name] = asset.configuration.title
        
        aggregateAssetDownloadTask.taskDescription = asset.configuration.url
        
        userInfo[Asset.Keys.downloadState] = getState(state: aggregateAssetDownloadTask.state.rawValue).rawValue
        userInfo[Asset.Keys.downloadSelectionDisplayName] = displayNamesForSelectedMediaOptions(mediaSelection)
        userInfo[Asset.Keys.fileSize] = aggregateAssetDownloadTask.countOfBytesReceived
        
        
        NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
    }
    
    /// Method to adopt to subscribe to progress updates of an AVAggregateAssetDownloadTask.
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                    timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection) {
        
        // This delegate callback should be used to provide download progress for your AVAssetDownloadTask.
        guard let asset = activeDownloadsMap[aggregateAssetDownloadTask] else { return }
        
        var percentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            percentComplete +=
            loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        percentComplete *= 100
        var userInfo = [String: Any]()
        userInfo[Asset.Keys.textureId] = asset.textureId
        userInfo[Asset.Keys.name] = asset.configuration.title
        userInfo[Asset.Keys.percentDownloaded] = percentComplete
        userInfo[Asset.Keys.fileSize] = Int(aggregateAssetDownloadTask.countOfBytesReceived)
        userInfo[Asset.Keys.downloadState] = getState(state: aggregateAssetDownloadTask.state.rawValue).rawValue
        NotificationCenter.default.post(name: .AssetDownloadProgress, object: nil, userInfo: userInfo)
    }
    
    private func getState(state: Int) -> Asset.DownloadState {
        switch state {
        case 0:
            return Asset.DownloadState.downloading
        case 1:
            return Asset.DownloadState.stopped
        case 2:
            return Asset.DownloadState.failed
        case 3:
            return Asset.DownloadState.completed
        default:
            return Asset.DownloadState.downloading
        }
    }
}

extension Notification.Name {
    /// Notification for when download progress has changed.
    static let AssetDownloadProgress = Notification.Name(rawValue: "AssetDownloadProgressNotification")
    
    /// Notification for when the download state of an Asset has changed.
    static let AssetDownloadStateChanged = Notification.Name(rawValue: "AssetDownloadStateChangedNotification")
    
    /// Notification for when AssetPersistenceManager has completely restored its state.
    static let AssetPersistenceManagerDidRestoreState = Notification.Name(rawValue: "AssetPersistenceManagerDidRestoreStateNotification")
}
