//
//  DownloadConfiguration.swift
//  udevs_video_player
//
//  Created by Udevs on 28/11/22.
//

struct DownloadConfiguration {
    var url: String
    var title: String
    var duration: Int
    
    init(url: String, title: String, duration:Int) {
        self.url = url
        self.title = title
        self.duration = duration
    }
    
    static func fromMap(map : [String:Any]) -> DownloadConfiguration {
        return DownloadConfiguration(url: map["url"] as! String, title: map["title"] as! String, duration: map["duration"] as! Int)
    }
}
