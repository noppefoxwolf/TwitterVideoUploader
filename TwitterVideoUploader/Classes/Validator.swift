//
//  Validator.swift
//  Pods
//
//  Created by Tomoya Hirano on 2017/01/22.
//
//

import Foundation
import RxSwift

public protocol FormatSafe {}
public class Validator {
  public enum FormatValid: FormatSafe {
    case durationValid
    case fileSizeValid
    case dimensionsValid
    case aspectRatioValid
    case frameRateValid
    case audioChannelValid
    case audioFormatValid
  }
  
  public enum FormatWarning: FormatSafe {
    case unsafeDimentions
    case unsafeAspectRatio
    case unsafeAudioChannel
  }
  
  public enum FormatError: Error {
    case invalidDuration
    case invalidFileSize
    case invalidFrameRate
    case invalidAudioFormat
  }
  
  public enum PostType {
    case sync
    case async
    
    func getDurationRange() -> (min:Float64, max:Float64) {
      switch self {
      case .sync: return (min: 0.5, max: 30.0)
      case .async: return (min: 0.5, max: 140.0)
      }
    }
    
    func getFileSizeLimit() -> UInt64 {
      switch self {
      case .sync: return 15 * 1024 * 1024
      case .async: return 512 * 1024 * 1024
      }
    }
    
    func getDimensionsLimit() -> (min:(width:Int, height:Int), max:(width:Int, height:Int)) {
      return (min: (width: 32, height: 32), max: (width: 1280, height: 1024))
    }
    
    func getAspectRatioLimit() -> (min:Float, max:Float) {
      return (min: 1.0 / 3.0, max: 3.0 / 1.0)
    }
    
    func getMaxFrameRate() -> Float {
      return 40.0
    }
    //open GOP
    //Progressive scan
    //pixel aspect ratio
    //mono stereo
    //must AAC-LC
  }
  
  enum RecommendedFormat {
    case LandscapeHd
    case Landscape
    case LandscapeSd
    case PortraitHd
    case Portrait
    case PortraitSd
    
    func getVideoBitrateK() -> Int {
      switch self {
      case .LandscapeHd: return 2048
      case .Landscape: return 768
      case .LandscapeSd: return 256
      case .PortraitHd: return 1024
      case .Portrait: return 768
      case .PortraitSd: return 256
      }
    }
    
    func getAudioBitrateK() -> Int {
      switch self {
      case .LandscapeHd: return 128
      case .Landscape: return 64
      case .LandscapeSd: return 64
      case .PortraitHd: return 96
      case .Portrait: return 64
      case .PortraitSd: return 64
      }
    }
    
    func getVideoSize() -> CGSize {
      switch self {
      case .LandscapeHd: return CGSize(width: 1280, height: 720)
      case .Landscape: return CGSize(width: 640, height: 360)
      case .LandscapeSd: return CGSize(width: 320, height: 180)
      case .PortraitHd: return CGSize(width: 640, height: 640)
      case .Portrait: return CGSize(width: 480, height: 480)
      case .PortraitSd: return CGSize(width: 240, height: 240)
      }
    }
  }
  
  private var videoInfo: VideoInfo
  private var postType: PostType
  
  public init(url: URL, postType: PostType) {
    self.videoInfo = VideoInfo(videoUrl: url)
    self.postType  = postType
    print(self.videoInfo.description)
  }
  
  
  public func validate() -> Observable<Void> {
    return durationValidate().flatMap { _ in
      return self.fileSizeValidate()
    }.flatMap{ _ in
      return self.dimensionsValidate()
    }.flatMap{ _ in
      return self.aspectRatioValidate()
    }.flatMap{ _ in
      return self.frameRateValidate()
    }.flatMap{ _ in
      return self.audioChannelValidate()
    }.flatMap{ _ in
      return self.audioFormatValidate()
    }
  }
  
  private func durationValidate() -> Observable<Void> {
    return Observable.create { (observer) -> Disposable in
      let range = self.postType.getDurationRange()
      let duration = self.videoInfo.duration
      let isValid = range.min...range.max ~= duration
      if isValid {
        observer.onCompleted()
      } else {
        observer.onError(FormatError.invalidDuration)
      }
      return Disposables.create()
    }
  }
  
  private func fileSizeValidate() -> Observable<Void> {
    return Observable.create { (observer) -> Disposable in
      let limit = self.postType.getFileSizeLimit()
      let size  = self.videoInfo.fileSize
      let isValid = size <= limit
      if isValid {
        observer.onCompleted()
      } else {
        observer.onError(FormatError.invalidFileSize)
      }
      return Disposables.create()
    }
  }
  
  private func dimensionsValidate() -> Observable<Void> {
    return Observable.create { (observer) -> Disposable in
      let limit = self.postType.getDimensionsLimit()
      let dimention = self.videoInfo.dimension
      let isValidWidth  = Int(limit.min.width)...Int(limit.max.width) ~= Int(dimention.width)
      let isValidHeight = Int(limit.min.height)...Int(limit.max.height) ~= Int(dimention.height)
      if isValidWidth && isValidHeight {
      } else {
        print(FormatWarning.unsafeDimentions)
      }
      observer.onCompleted()
      return Disposables.create()
    }
  }
  
  private func aspectRatioValidate() -> Observable<Void> {
    return Observable.create { (observer) -> Disposable in
      let limit = self.postType.getAspectRatioLimit()
      let ratio  = self.videoInfo.aspectRatio
      let isValid = limit.min...limit.max ~= ratio
      if isValid {
      } else {
        print(FormatWarning.unsafeAspectRatio)
      }
      observer.onCompleted()
      return Disposables.create()
    }
  }
  
  private func frameRateValidate() -> Observable<Void> {
    return Observable.create { (observer) -> Disposable in
      let limit = self.postType.getMaxFrameRate()
      let fps  = self.videoInfo.fps
      let isValid = fps <= limit
      if isValid {
        observer.onCompleted()
      } else {
        observer.onError(FormatError.invalidFrameRate)
      }
      return Disposables.create()
    }
  }
  
  private func audioChannelValidate() -> Observable<Void> {
    return Observable.create { (observer) -> Disposable in
      let limit = [0, 1, 2] // none mono stereo
      let channelCount  = self.videoInfo.channelCount
      let isValid = limit.contains(channelCount)
      if isValid {
      } else {
        print(FormatWarning.unsafeAudioChannel)
      }
      return Disposables.create()
    }
  }
  
  private func audioFormatValidate() -> Observable<Void> {
    return Observable.create { (observer) -> Disposable in
      let formats = ["AAC-LC"]
      let audioFormat  = self.videoInfo.getAudioFormat()
      let isValid = formats.contains(audioFormat)
      if isValid {
        observer.onCompleted()
      } else {
        observer.onError(FormatError.invalidAudioFormat)
      }
      return Disposables.create()
    }
  }
}

