//
//  TwitterVideoUploader.swift
//  Pods
//
//  Created by Tomoya Hirano on 2017/01/22.
//
//

import Foundation
import STTwitter
import RxSwift
import STTwitter

public extension STTwitterAPI {
  public func postMediaAsyncUploadThreeSteps(withVideoURL videoURL: URL) -> Observable<String> {
    return INIT(withVideoMediaURL: videoURL).flatMap { (mediaId, expiresAfterSecs) in
        return self.APPEND(withVideoURL: videoURL, mediaId: mediaId).map({ _ in mediaId })
      }.flatMap { (mediaId) in
        return self.FINALIZE(mediaId: mediaId).map({ _ in mediaId })
      }.flatMap { (mediaId) in
        return self.STATUS(mediaId: mediaId).map({ _ in mediaId })
      }
  }
  
  public func postStatusesUpdate(with videoURL: URL, message: String) -> Observable<Void> {
    return postMediaAsyncUploadThreeSteps(withVideoURL: videoURL).flatMap { (mediaId) in
      return self.postStatusUpdate(message: message, mediaId: mediaId)
    }
  }
}
