//
//  OstToken.swift
//  OstSdk
//
//  Created by aniket ayachit on 11/12/18.
//  Copyright © 2018 aniket ayachit. All rights reserved.
//

import Foundation

public class OstToken: OstBaseEntity {
 
    static func parse(_ entityData: [String: Any?]) throws -> OstToken? {
        return try OstTokenRepository.sharedToken.insertOrUpdate(entityData, forIdentifier: self.getEntityIdentifer()) as? OstToken ?? nil
    }
    
    static func getEntityIdentifer() -> String {
        return "id"
    }
    
    override func getId(_ params: [String: Any]) -> String {
        return OstUtils.toString(params[OstToken.getEntityIdentifer()])!
    }
}

extension OstToken {
    var symbol: String? {
        return data["symbol"] as? String
    }
    
    var name: String? {
        return data["name"] as? String
    }
    
    var total_supply: Int? {
        return OstUtils.toInt(data["total_supply"] as Any?)
    }
}
