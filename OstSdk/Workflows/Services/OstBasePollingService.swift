//
//  OstPollingService.swift
//  OstSdk
//
//  Created by aniket ayachit on 13/02/19.
//  Copyright © 2019 aniket ayachit. All rights reserved.
//

import Foundation

class OstBasePollingService {
    
    static let MAX_RETRY_COUNT = 20
    static let NO_OF_CONFIRMATION_BLOCKS = 6;
  
    var requestCount = 0;
    
    var onSuccess: ((OstBaseEntity) -> Void)? = nil
    var onFailure: ((OstError) -> Void)? = nil
    
    let userId: String
    let workflowTransactionCount: Int
    
    let failureCallback: ((OstError) -> Void)?
    
    init (userId: String, workflowTransactionCount: Int, failureCallback: ((OstError) -> Void)?) {
        self.userId = userId
        self.workflowTransactionCount = workflowTransactionCount
        self.failureCallback = failureCallback
    }
    
    func perform() {
        let queue: DispatchQueue = getPollingQueue()
        queue.async {
            self.setupCallbacks()
            self.getEntityAfterDelay()
        }
    }
    
    func setupCallbacks() {
        self.onSuccess = { entity in
            self.onSuccessProcess(entity: entity)
        }
        
        self.onFailure = { error in
            self.failureCallback?(error)
        }
    }
    
    
    func getEntityAfterDelay() {
      Logger.log(message: "[\(Date.timestamp())]: getEntityAfterDelay: for userId: \(userId)", parameterToPrint: "")
        if (self.requestCount < OstBasePollingService.MAX_RETRY_COUNT ) {
            let delayTime: Int;
            if (self.requestCount > 0 ) {
              delayTime = OstConstants.OST_BLOCK_GENERATION_TIME;
            } else {
              delayTime = OstConstants.OST_BLOCK_GENERATION_TIME * (OstBasePollingService.NO_OF_CONFIRMATION_BLOCKS + 1 ) * workflowTransactionCount;
            }
            
            let queue: DispatchQueue = self.getPollingQueue()
            queue.asyncAfter(deadline: .now() + .seconds(delayTime) ) {
                do {
                    self.requestCount += 1
                    Logger.log(message: "[\(Date.timestamp())]: loDispatchQueue for userId: \(self.userId) and is started at \(Date.timestamp())", parameterToPrint: "")
                    try self.fetchEntity()
                }catch let error {
                    let ostError = error as! OstError;
                    /// TODO: Check response error code.
                    /// If it was a network error (The following status code should not be treated as network-errors: 200/404/401)
                    /// We need to retry instead of calling failureCallback.
                    /// For now, we shall check on requestCount
                    if ( self.requestCount == OstBasePollingService.MAX_RETRY_COUNT ) {
                      //Sufficient retires have been made.
                      self.failureCallback?(ostError)
                      return;
                    }
                  
                    // Lets Retry.
                    self.getEntityAfterDelay()
                }
            }
        }else {
            self.failureCallback?(OstError.init("w_s_bps_gead_1", .failedWithMaxRetryCount))
        }
    }
    
    //MARK: - Methods to override
    func fetchEntity() throws {
        fatalError("fetchEntity is not override")
    }
    
    func onSuccessProcess(entity: OstBaseEntity) {
        fatalError("onSuccessPerocess is not override.")
    }
    
    func getPollingQueue() -> DispatchQueue {
        fatalError("getPollingQueue is not override.")
    }
}
