//
//  ProcessingInfo.swift
//  Pods
//
//  Created by Tomoya Hirano on 2017/01/22.
//
//

import ObjectMapper

struct ProcessingInfo: Mappable {
  enum State: String {
    case pending = "pending"
    case inProgress = "in_progress"
    case failed = "failed"
    case succeeded = "succeeded"
    case unknown
  }
  private(set) var checkAfterSecs = 0
  private(set) var progressPercent = 0
  private(set) var state = ProcessingInfo.State.unknown
  
  init?(map: Map) {
    mapping(map: map)
  }
  
  mutating func mapping(map: Map) {
    checkAfterSecs <- map["check_after_secs"]
    progressPercent <- map["progress_percent"]
    state <- map["state"]
  }
}
