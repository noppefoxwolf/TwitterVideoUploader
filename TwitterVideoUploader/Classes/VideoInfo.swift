//
//  VideoInfo.swift
//  Pods
//
//  Created by Tomoya Hirano on 2017/01/22.
//
//

import AVFoundation
import Foundation

struct VideoInfo {
  private var videoUrl: URL
  private let asset: AVURLAsset
  private(set) var duration: Float64 = 0
  private(set) var fileSize: UInt64 = 0
  private(set) var dimension: CGSize = CGSize.zero
  private(set) var aspectRatio: Float = 1.0
  private(set) var channelCount: Int = 0
  private(set) var fps: Float = 0.0
  private(set) var audioFormat: String = ""
  
  internal init(videoUrl: URL) {
    self.videoUrl = videoUrl
    asset = AVURLAsset(url: videoUrl)
    duration = getDuration()
    fileSize = getFileSize()
    dimension = getVideoDimensions()
    aspectRatio = Float(dimension.width / dimension.height)
    channelCount = getAudioChannelCount()
    fps = getFps()
    audioFormat = getAudioFormat()
  }
  
  private func getDuration() -> Float64 {
    let cmTime = asset.duration
    let duration = CMTimeGetSeconds(cmTime)
    return duration
  }
  
  private func getFileSize() -> UInt64 {
    do {
      let attr: [FileAttributeKey : Any] = try FileManager.default.attributesOfItem(atPath: videoUrl.path)
      return attr[FileAttributeKey.size] as! UInt64
    } catch {
      return 0
    }
  }
  
  internal func getFps() -> Float {
    return asset.videoTrack?.nominalFrameRate ?? 0.0
  }
  
  internal func getVideoDimensions() -> CGSize {
    return asset.videoTrack?.naturalSize ?? CGSize.zero
  }
  
  internal func getAudioChannelCount() -> Int {
    //TODO: しっかり検出する
    return 2
  }
  
  internal func getAudioFormat() -> String {
    //TODO: しっかり検出する
    return "AAC-LC"
  }
  
  public var description: String {
    get {
      return "---- Video Track Infomation ---\n" +
        "File Path: \(videoUrl.absoluteString)\n" +
        "Duration:  \(duration)sec\n" +
        "File Size: \(Float(fileSize) / 1024.0 / 1024.0)MB (\(fileSize)B)\n" +
        "Dimension: \(dimension.width) x \(dimension.height) [width x height]\n" +
        "Aspect Ratio: \(aspectRatio)\n" +
        "Channel Count: \(channelCount)\n" +
        "FPS: \(fps)\n" +
      "--------------------------\n"
    }
  }
}

fileprivate extension AVURLAsset {
  var videoTrack: AVAssetTrack? { get { return tracks(withMediaType: AVMediaType.video).first } }
}
