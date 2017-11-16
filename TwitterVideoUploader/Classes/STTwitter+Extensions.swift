//
//  STTwitter+Extensions.swift
//  Pods
//
//  Created by Tomoya Hirano on 2017/01/22.
//
//

import STTwitter
import ObjectMapper
import RxSwift

extension STTwitterAPI {
  private static let kBaseURLStringUpload_1_1 = "https://upload.twitter.com/1.1"
  private static let STTwitterAPIMediaDataIsEmpty = 1
  
  internal func postMediaUploadAsyncINIT(with videoUrl: URL, successBlock: @escaping ((Int, Int, String) -> Void), errorBlock: @escaping ((Error) -> Void)) -> STTwitterRequestProtocol? {
    let data: Data
    do {
      data = try Data(contentsOf: videoUrl)
    } catch {
      let error = NSError(domain: NSStringFromClass(type(of: self)),
                          code: STTwitterAPI.STTwitterAPIMediaDataIsEmpty,
                          userInfo: [NSLocalizedDescriptionKey: "data is nil"])
      errorBlock(error)
      return nil
    }
    
    var md = [String: String]()
    md["command"] = "INIT"
    md["media_type"] = "video/mp4"
    md["total_bytes"] = "\(data.count)"
    md["media_category"] = "tweet_video"
    return self.postResource("media/upload.json",
                             baseURLString: STTwitterAPI.kBaseURLStringUpload_1_1,
                             parameters: md,
                             uploadProgressBlock: nil,
                             downloadProgressBlock: nil,
                             successBlock: { (rateLimit, response) in
                              guard let response = response as? [String : Any],
                                let expiresAfterSecs = response["expires_after_secs"] as? Int,
                                let mediaId = response["media_id"] as? Int,
                                let mediaIdString = response["media_id_string"] as? String else {
                                  let error = NSError(domain: NSStringFromClass(type(of: self)),
                                                      code: STTwitterAPI.STTwitterAPIMediaDataIsEmpty,
                                                      userInfo: [NSLocalizedDescriptionKey: "data is nil"])
                                  errorBlock(error)
                                  return
                              }
                              successBlock(expiresAfterSecs, mediaId, mediaIdString)
    }, errorBlock: { (error) in
      errorBlock(error!)
    })
  }
  
  internal func postMediaUploadAsyncFINALIZE(with mediaId: String, successBlock: @escaping (() -> Void), errorBlock: @escaping ((Error) -> Void)) -> STTwitterRequestProtocol {
    var md = [String: String]()
    md["command"] = "FINALIZE"
    md["media_id"] = mediaId
    
    return self.postResource("media/upload.json",
                             baseURLString: STTwitterAPI.kBaseURLStringUpload_1_1,
                             parameters: md,
                             uploadProgressBlock: nil,
                             downloadProgressBlock: nil,
                             successBlock: { (rateLimit, response) in
                              guard let response = response as? [String : Any],
                                let mediaId = response["media_id"] as? String,
                                let mediaIdString = response["media_id_string"] as? String,
                                let size = response["size"] as? Int,
                                let expiresAfterSecs = response["expires_after_secs"] as? Int else {
                                  return
                              }
                              successBlock()
    }, errorBlock: { (error) in
      errorBlock(error!)
    })
  }
  
  internal func getMediaUploadAsyncSTATUS(with mediaId: String, successBlock: @escaping (() -> Void), errorBlock: @escaping ((Error) -> Void)) -> STTwitterRequestProtocol {
    var md = [String: String]()
    md["command"] = "STATUS"
    md["media_id"] = mediaId
    return self.getResource("media/upload.json",
                            baseURLString: STTwitterAPI.kBaseURLStringUpload_1_1,
                            parameters: md,
                            downloadProgressBlock: nil,
                            successBlock: { (rateLimit, response) in
                              guard let response = response as? [String : Any] else { return }
                              guard let statusResponse = StatusResponse(JSON: response) else { return }
                              guard let processingInfo = statusResponse.processingInfo else { return }
                              switch processingInfo.state {
                              case .succeeded:
                                successBlock()
                              case .failed:
                                errorBlock(StateError.failed)
                              case .pending:
                                errorBlock(StateError.pending)
                              case .inProgress:
                                errorBlock(StateError.inProgress(processingInfo))
                              case .unknown:
                                errorBlock(StateError.unknown)
                              }
    }, errorBlock: { (error) in
      errorBlock(error!)
    })
  }
}



internal extension STTwitterAPI {
  internal func INIT(withVideoMediaURL url: URL) -> Observable<(String, Int)> {
    return Observable.create { observer in
      _ = self.postMediaUploadAsyncINIT(with: url, successBlock: { (expiresAfterSecs, mediaId, mediaIdString) in
        print(mediaId, expiresAfterSecs)
        observer.onNext((mediaIdString, expiresAfterSecs))
        observer.onCompleted()
      }) { (error) in
        print(error)
        observer.onError(error)
      }
      return Disposables.create()
    }
  }
  
  internal func APPEND(withVideoURL url: URL, mediaId: String) -> Observable<Void> {
    return Observable.create({ observer in
      
      self.postMediaUploadAPPEND(withVideoURL: url, mediaID: mediaId, uploadProgressBlock: { (bytesWritten, accumulatedBytesWritten, dataLength) in
        //observer.onNext(Float(accumulatedBytesWritten) / Float(dataLength))
      }, successBlock: { (_) in
        observer.onNext(())
        observer.onCompleted()
      }, errorBlock: { (error) in
        observer.onError(error!)
      })
      return Disposables.create()
    })
  }
  
  internal func FINALIZE(mediaId: String) -> Observable<String> {
    return Observable.create({ (observer) -> Disposable in
      self.postMediaUploadFINALIZE(withMediaID: mediaId, successBlock: { (mediaId, size, expiresAfter, videoType) in
        observer.onNext(mediaId!)
        observer.onCompleted()
      }, errorBlock: { (error) in
        observer.onError(error!)
      })
      return Disposables.create()
    })
  }
  
  internal func STATUS(mediaId: String) -> Observable<Void> {
    return Observable.create({ (observer) -> Disposable in
      _ = self.getMediaUploadAsyncSTATUS(with: mediaId, successBlock: {
        observer.onNext(())
        observer.onCompleted()
      }, errorBlock: { (error) in
        observer.onError(error)
      })
      return Disposables.create()
    }).retryWhen { (errors: Observable<Error>) -> Observable<Int> in
      return errors.flatMap { (error: Error) -> Observable<Int>  in
        if let stateError = error as? StateError {
          switch stateError {
          case .inProgress(let processingInfo):
            return Observable.timer(RxTimeInterval(processingInfo.checkAfterSecs), scheduler: MainScheduler.instance)
          default: break
          }
        }
        return Observable.error(error)
      }
    }
  }
  
  internal func postStatusUpdate(message: String, mediaId: String) -> Observable<Void> {
    return Observable.create({ (observer) -> Disposable in
      self.postStatusesUpdate(message,
                              inReplyToStatusID: nil,
                              mediaIDs: [mediaId],
                              latitude: nil,
                              longitude: nil,
                              placeID: nil,
                              displayCoordinates: nil,
                              trimUser: nil,
                              autoPopulateReplyMetadata: nil,
                              excludeReplyUserIDsStrings: nil,
                              attachmentURLString: nil,
                              useExtendedTweetMode: nil,
                              successBlock: { (_) in
                                observer.onCompleted()
      }, errorBlock: { (error) in
        observer.onError(error!)
      })
      return Disposables.create()
    })
  }
}
