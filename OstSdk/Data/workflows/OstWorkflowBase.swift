//
//  OstBase.swift
//  OstSdk
//
//  Created by aniket ayachit on 09/01/19.
//  Copyright © 2019 aniket ayachit. All rights reserved.
//

import Foundation

class OstWorkflowBase {
    var userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    func perform() {
        fatalError("************* perform didnot override ******************")
    }
    
    func getUser() throws -> OstUser? {
        return try OstUserModelRepository.sharedUser.getById(self.userId) as? OstUser
    }
    
    func getCurrentDevice(user: OstUser) -> OstCurrentDevice? {
        return user.getCurrentDevice()
    }
}
