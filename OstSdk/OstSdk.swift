//
//  OstSdk.swift
//  OstSdk
//
//  Created by aniket ayachit on 14/12/18.
//  Copyright © 2018 aniket ayachit. All rights reserved.
//

import Foundation

public class OstSdk {

    public class func initialize(apiEndPoint:String) throws {
        
        let sdkRef = OstSdkDatabase.sharedInstance
        sdkRef.runMigration()
        try setApiEndPoint(apiEndPoint:apiEndPoint);
    }
    
    public class func parse(_ apiResponse: [String: Any?]) throws {
        try OstAPIHelper.storeApiResponse(apiResponse)
    }

    public class func getUser(_ id: String) throws -> OstUser? {
        return try OstUser.getById(id)
    }
    
    // TODO: Remove Parse user in future.
    public class func parseUser(_ entityData: [String: Any?]) throws -> OstUser? {
        try OstUser.storeEntity(entityData)
        let id = OstBaseEntity.getItem(fromEntity: entityData, forKey: OstUser.ENTITY_IDENTIFIER) as! String
        return try OstUser.getById(id)!
    }
    
//    public class func initToken(_ tokenId: String) throws -> OstToken? {
//        let entityData: [String: Any] = [OstToken.getEntityIdentiferKey(): tokenId]
//        return try OstToken.parse(entityData)
//    }
    
    class func setApiEndPoint(apiEndPoint:String) throws {
        let endPointSplits = apiEndPoint.split(separator: "/");
        if ( endPointSplits.count < 4 ) {
            throw OstError("ost_sdk_vpep_1", .invalidApiEndPoint);
        }
        //Unlike javascript, where we read index 4 for version, we have to read index 3 in swift.
        //Reason: the splits do not contain empty string. http://axy produces 2 splits instead of 3.
        let providedApiVersion = endPointSplits[3].lowercased();
        let expectedApiVersion = ("v" + OstConstants.OST_API_VERSION).lowercased();
        if ( providedApiVersion.compare(expectedApiVersion) != .orderedSame ) {
            throw OstError("ost_sdk_vpep_2", .invalidApiEndPoint);
        }
        
        var finalApiEndpoint = apiEndPoint.lowercased();
        
        //Let's be tolerant for the extra '/' 
        if ( finalApiEndpoint.hasSuffix("/") ) {
            finalApiEndpoint = String(finalApiEndpoint.dropLast());
        }
        
        Logger.log(message: "finalApiEndpoint", parameterToPrint: finalApiEndpoint);
        OstAPIBase.setAPIEndpoint(finalApiEndpoint);
    }
}
