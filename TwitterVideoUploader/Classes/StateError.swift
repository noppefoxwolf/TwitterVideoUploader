//
//  StateError.swift
//  Pods
//
//  Created by Tomoya Hirano on 2017/01/22.
//
//

import UIKit

internal enum StateError: Error {
  case pending
  case inProgress(ProcessingInfo)
  case failed
  case unknown
}
