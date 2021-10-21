////
////  BetterPlayerView.swift
////  better_player
////
////  Created by Shahzod Atabayev on 18/10/21.
////
//
//import Foundation
//import AVKit
//import UIKit
//
//class BetterPlayerView {
//    var player: AVPlayer?
//
//    private(set) var playerLayer: AVPlayerLayer?
//
//    func getPlayer () -> AVPlayer? {
//        return playerLayer?.player
//    }
//
//    func setPlayer (_ player: AVPlayer?) {
//        playerLayer?.player = player
//    }
//
//    // Override UIView method
//    static func layerClass () -> AnyClass {
//        return AVPlayerLayer.self
//    }
//
//    func getPlayerLayer () -> AVPlayerLayer? {
//        return playerLayer
//    }
//}
