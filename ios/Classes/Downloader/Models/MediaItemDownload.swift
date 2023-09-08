//
//  MediaItemDownload.swift
//  better_player
//
//  Created by Shahzod Atabayev on 15/08/23.
//

import Foundation


struct MediaItemDownload {
    var url: String
    var percent: Int
    var state: Asset.DownloadState?
    var downloadedBytes: Int
    
    init(url: String, percent: Int, state: Asset.DownloadState?, downloadedBytes: Int) {
        self.url = url
        self.percent = percent
        self.state = state
        self.downloadedBytes = downloadedBytes
    }
    
    
    static func fromMap(map : [String:Any]) -> MediaItemDownload {
        return MediaItemDownload(url: map["url"] as! String, percent: map["percent"] as! Int, state: Asset.DownloadState.downloading, downloadedBytes: 0)
    }
    
}
