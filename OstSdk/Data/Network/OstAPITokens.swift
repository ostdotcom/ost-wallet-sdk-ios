//
//  OstTokensAPI.swift
//  OstSdk
//
//  Created by aniket ayachit on 05/02/19.
//  Copyright © 2019 aniket ayachit. All rights reserved.
//

import Foundation
import Alamofire

class OstAPITokens: OstAPIBase {
    let tokenApiResourceBase = "/tokens"
    
    override init(userId: String) {
        super.init(userId: userId)
    }
    
    public func getToken(success:((OstToken) -> Void)?, failuar:((OstError) -> Void)?) throws {
    
        resourceURL = tokenApiResourceBase + "/"
        
        var params: [String: Any] = [:]
        insetAdditionalParamsIfRequired(&params)
        try sign(&params)
        
        get(params: params as [String : AnyObject], success: { (apiResponse) in
            do {
                let entity = try self.parseEntity(apiResponse: apiResponse)
                success?(entity as! OstToken)
            }catch let error{
                failuar?(error as! OstError)
            }
        }) { (failuarObj) in
            failuar?(OstError.actionFailed("Token Sync failed"))
        }
    }
}