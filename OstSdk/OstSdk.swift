//
//  OstSdk.swift
//  OstSdk
//
//  Created by aniket ayachit on 14/12/18.
//  Copyright © 2018 aniket ayachit. All rights reserved.
//

import Foundation

public class OstSdk {

    public class func initialize() {
        let sdkRef = OstSdkDatabase.sharedInstance
        sdkRef.runMigration()
    }
    
    public class func parse(_ apiResponse: [String: Any?]) throws {
        _ = try self.parseApiResponse(apiResponse)
    }
    
    class func parseApiResponse(_ apiResponse: [String: Any?]) throws -> OstBaseEntity? {
        
        let resultType = apiResponse["result_type"] as? String ?? ""
        let entityData =  apiResponse[resultType] as? [String: Any?]
        
        if (entityData == nil) {
            throw OstError.actionFailed("parsing \(resultType) enity failed.")
        }
        switch resultType {
        case "token":
            return try OstToken.parse(entityData!)
        case "user":
            return try OstUser.parse(entityData!)
        case "device":
            return try OstDevice.parse(entityData!)
        case "device_manager":
            return try OstDeviceManager.parse(entityData!)
        case "session":
            return try OstSession.parse(entityData!)
        default:
            throw OstError.invalidInput("\(resultType) is not supported.")
        }
    }
    
    public class func getUser(_ id: String) throws -> OstUser? {
        return try OstUser.getById(id)
    }
    
    public class func initUser(forId id: String, withTokenId tokenId: String) throws -> OstUser? {
        let entityData: [String: Any] = [OstUser.getEntityIdentiferKey(): id, "token_id": tokenId, "status": OstUser.USER_STATUS_CREATED]
        return try parseUser(entityData)
    }
    
    public class func parseUser(_ entityData: [String: Any?]) throws -> OstUser? {
        return try OstUser.parse(entityData);
    }
    
    public class func initToken(_ tokenId: String) throws -> OstToken? {
        let entityData: [String: Any] = [OstToken.getEntityIdentiferKey(): tokenId]
        return try OstToken.parse(entityData)
    }
}