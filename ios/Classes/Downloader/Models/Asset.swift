/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A simple class that holds information about an Asset.
*/

import AVFoundation

class Asset {
    
    /// The AVURLAsset corresponding to this Asset.
    var urlAsset: AVURLAsset
    
    let textureId: Int
    
    /// The underlying `Stream` associated with the Asset based on the contents of the `Streams.plist` entry.
    let configuration: DownloadConfiguration
    
    init(textureId: Int, configuration: DownloadConfiguration, urlAsset: AVURLAsset) {
        self.urlAsset = urlAsset
        self.configuration = configuration
        self.textureId = textureId
    }
}

/// Extends `Asset` to conform to the `Equatable` protocol.
extension Asset: Equatable {
    static func ==(lhs: Asset, rhs: Asset) -> Bool {
        return ((lhs.urlAsset == rhs.urlAsset)) || (lhs.textureId == rhs.textureId)
    }
}

/**
 Extends `Asset` to add a simple download state enumeration used by the sample
 to track the download states of Assets.
 */

/**
 Extends `Asset` to define a number of values to use as keys in dictionary lookups.
 */
extension Asset {
    
    enum DownloadState: String {
      case initial, queued, stopped, downloading, completed, failed, removed, restarting
    }

    
    struct Keys {
        /**
         Key for the Asset name, used for `AssetDownloadProgressNotification` and
         `AssetDownloadStateChangedNotification` Notifications as well as
         AssetListManager.
         */
        static let name = "AssetNameKey"        /**
         Key for the Asset name, used for `AssetDownloadProgressNotification` and
         `AssetDownloadStateChangedNotification` Notifications as well as
         AssetListManager.
         */
        static let textureId = "TextureIdKey"
        
        static let url = "AssetUrlKey"   

        /**
         Key for the Asset download percentage, used for
         `AssetDownloadProgressNotification` Notification.
         */
        static let percentDownloaded = "AssetPercentDownloadedKey"

        /**
         Key for the Asset download state, used for
         `AssetDownloadStateChangedNotification` Notification.
         */
        static let downloadState = "AssetDownloadStateKey"
        /**
         Key for the Asset download state, used for
         `AssetDownloadStateChangedNotification` Notification.
         */
        static let fileSize = "AssetFileSizeKey"

        /**
         Key for the Asset download AVMediaSelection display Name, used for
         `AssetDownloadStateChangedNotification` Notification.
         */
        static let downloadSelectionDisplayName = "AssetDownloadSelectionDisplayNameKey"
    }
}
