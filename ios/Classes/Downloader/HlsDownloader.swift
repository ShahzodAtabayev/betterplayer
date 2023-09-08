//
//  HlsDownloader.swift
//  better_player
//
//  Created by Shahzod Atabayev on 15/08/23.
//

import Foundation
import Flutter
import AVKit
import AVFoundation


class HlsDownloader : NSObject, FlutterStreamHandler {
    
    let textureId: Int
    
    let asset: Asset
    
    let eventChannel: FlutterEventChannel
    
    private var eventSink: FlutterEventSink?
    
    private var downloadTask: AVAggregateAssetDownloadTask?
    
    private var mediaOptionList = [AVMutableMediaSelection]()
    
    
    init(textureId: Int, asset: Asset, eventChannel: FlutterEventChannel) {
        self.asset = asset
        self.textureId = textureId
        self.eventChannel = eventChannel
        super.init()
        self.eventChannel.setStreamHandler(self)
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    public func getDownloadOptions(error: (String)->()) -> [String: Double]{
        if UserDefaults.standard.value(forKey: asset.configuration.url) == nil {
            if let url = URL(string: asset.configuration.url) {
                let hlsAsset = AVURLAsset(url: url)
                var results = [String: Double]()
                guard hlsAsset.statusOfValue(forKey: "availableMediaCharacteristicsWithMediaSelectionOptions", error: nil)
                        == AVKeyValueStatus.loaded else {
                    let mutableMediaSelection = hlsAsset.preferredMediaSelection.mutableCopy() as! AVMutableMediaSelection
                    let seconds = asset.configuration.duration
                    let rate = mutableMediaSelection.asset?.preferredRate ?? 1
                    results["\(mediaOptionList.count)"] = calculateSize(duration: seconds, bitrate: rate)
                    mediaOptionList.append(mutableMediaSelection)
                    return results
                }
                let mediaCharacteristic = AVMediaCharacteristic.legible //AVMediaCharacteristic.audible or AVMediaCharacteristic.legible
                let mediaSelectionGroup = hlsAsset.mediaSelectionGroup(forMediaCharacteristic: mediaCharacteristic)
                if let options = mediaSelectionGroup?.options {
                    for option in options {
                        if option.isPlayable && option.mediaType == .video{
                            let mutableMediaSelection = hlsAsset.preferredMediaSelection.mutableCopy() as! AVMutableMediaSelection
                            mutableMediaSelection.select(option, in: mediaSelectionGroup!)
                            let seconds = asset.configuration.duration
                            let rate = mutableMediaSelection.asset?.preferredRate ?? 1
                            results["\(mediaOptionList.count)"] = calculateSize(duration: seconds, bitrate: rate)
                            mediaOptionList.append(mutableMediaSelection)
                        }
                    }
                }
                return results
            }
        } else {
            error("This file already exits")
        }
        return [:]
    }
    
    
    func test1(){
        
    }
    
    public func onSelectOption(selectedKey: String) {
            // Get the default media selections for the asset's media selection groups.
            let preferredMediaSelection = mediaOptionList[Int(selectedKey) ?? 0]
            // Create new AVAssetDownloadTask for the desired asset
            self.downloadTask = AssetPersistenceManager.sharedManager.downloadStream(for: asset,selec: preferredMediaSelection)
    }
    
    // duration: seconds, bitrate: Mpbs
    private func calculateSize(duration: Int, bitrate: Float) -> Double {
        return (Double((bitrate / 8)) * Double(duration)) * 1024 * 1024
    }
    
    public func sinkEvent(state: Asset.DownloadState, progress: Double, size: Int?){
        var results = [String: Any]()
        results["url"] = asset.configuration.url
        results["status"] = state.rawValue
        results["progress"] = progress
        results["size"] = size
        self.eventSink?(results)
    }
}

extension AVURLAsset {
    var fileSize: Int? {
        let keys: Set<URLResourceKey> = [.totalFileSizeKey, .fileSizeKey]
        let resourceValues = try? url.resourceValues(forKeys: keys)

        return resourceValues?.fileSize ?? resourceValues?.totalFileSize
    }
}
