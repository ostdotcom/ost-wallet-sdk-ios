//
//  OstAPIResetPin.swift
//  OstSdk
//
//  Created by Deepesh Kumar Nath on 01/03/19.
//  Copyright © 2019 aniket ayachit. All rights reserved.
//

import Foundation

class OstAPIResetPin: OstAPIBase {
    var resetPinApiResourceBase: String
    
    /// Initializer
    ///
    /// - Parameter userId: User id to get token
    override init(userId: String) {
        self.resetPinApiResourceBase = "/users/\(userId)/recovery-owners/"
        super.init(userId: userId)
    }
    
    /// Change recoovery owner
    ///
    /// - Parameters:
    ///   - params: Reset pin params
    ///   - onSuccess: Success callback
    ///   - onFailure: Failure callback
    /// - Throws: OstError
    func changeRecoveryOwner(
        params: [String: Any],
        onSuccess:((OstRecoveryOwnerEntity) -> Void)?,
        onFailure:((OstError) -> Void)?) throws {
        
        resourceURL = resetPinApiResourceBase
        var resetPinParams = params

        // Sign API resource
        try OstAPIHelper.sign(apiResource: getResource, andParams: &resetPinParams, withUserId: self.userId)
        
        // Make an API call
        post(params: resetPinParams as [String: AnyObject],
             onSuccess: {(apiResponse) in
                let resultType = apiResponse!["result_type"] as! String
                if (resultType == "recovery_owner") {
                    do {
                        let entity = try OstRecoveryOwnerEntity.init(apiResponse![resultType] as! [String : Any])
                        onSuccess?(entity)
                    }catch let error{
                        onFailure?(error as! OstError)
                    }
                }else {
                    onFailure?(OstError.init("n_arp_cro_1", .resetPinFailed))
                }
            },
            onFailure: { (failureResponse) in
                onFailure?(OstApiError.init(fromApiResponse: failureResponse!))
            }
        )
    }    
    
    /// Get recovery owner address info
    ///
    /// - Parameters:
    ///   - recoveryOwnerAddress: Recovery owner address
    ///   - onSuccess: Success callback
    ///   - onFailure: Failure callback
    /// - Throws: OstError
    func getRecoverOwner(
        recoveryOwnerAddress: String,
        onSuccess:((OstRecoveryOwnerEntity) -> Void)?,
        onFailure:((OstError) -> Void)?) throws {
        
        resourceURL = "\(resetPinApiResourceBase)\(recoveryOwnerAddress)"
        var params: [String: Any] = [:]
        
        // Sign API resource
        try OstAPIHelper.sign(apiResource: getResource, andParams: &params, withUserId: self.userId)

        get(params: params as [String: AnyObject],
             onSuccess: {(apiResponse) in
                let resultType = apiResponse!["result_type"] as! String
                if (resultType == "recovery_owner") {
                    do {
                        let entity = try OstRecoveryOwnerEntity.init(apiResponse![resultType] as! [String : Any])
                        onSuccess?(entity)
                    }catch let error{
                        onFailure?(error as! OstError)
                    }
                }else {
                    onFailure?(OstError.init("n_arp_grw_1", .failedFetchRecoveryOwnerAddress))
                }
            },
             onFailure: { (failureResponse) in
                onFailure?(OstApiError.init(fromApiResponse: failureResponse!))
            }
        )
    }
}
