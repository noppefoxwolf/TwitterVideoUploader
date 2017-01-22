//
//  ViewController.swift
//  TwitterVideoUploader
//
//  Created by Tomoya Hirano on 01/22/2017.
//  Copyright (c) 2017 Tomoya Hirano. All rights reserved.
//

import UIKit
import TwitterVideoUploader
import STTwitter
import RxSwift

final class ViewController: UIViewController {
  let 👝 = DisposeBag()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //validation
    let videoUrl = Bundle.main.url(forResource: "sample", withExtension: "mp4")!
    Validator(url: videoUrl, postType: .async).validate().subscribe(onError: { (error) in
      print(error)
    }, onCompleted: {
      print("valid!")
    }).addDisposableTo(👝)
    
    //post
    let api = STTwitterAPI(oAuthConsumerKey: "",
                           consumerSecret: "",
                           oauthToken: "",
                           oauthTokenSecret: "")
    api?.postMediaAsyncUploadThreeSteps(withVideoURL: videoUrl).subscribe(onNext: { (_) in
      print("next")
    }, onError: { (error) in
      print("error", error)
    }, onCompleted: { 
      print("complete")
    }, onDisposed: { 
      print("dispose")
    }).addDisposableTo(👝)
  }

}


