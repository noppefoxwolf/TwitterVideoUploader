//
//  StatusResponse.swift
//  Pods
//
//  Created by Tomoya Hirano on 2017/01/22.
//
//

import ObjectMapper

struct StatusResponse: Mappable {
  private(set) var mediaId = 0
  private(set) var mediaIdString = ""
  private(set) var processingInfo: ProcessingInfo? = nil
  
  init?(map: Map) {
    mapping(map: map)
  }
  
  mutating func mapping(map: Map) {
    mediaId <- map["media_id"]
    mediaIdString <- map["media_id_string"]
    processingInfo <- map["processing_info"]
  }
}
