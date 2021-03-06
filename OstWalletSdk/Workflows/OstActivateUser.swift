/*
 Copyright © 2019 OST.com Inc
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 */

import Foundation

class OstActivateUser: OstUserAuthenticatorWorkflow {
    
    static private let ostActivateUserQueue = DispatchQueue(label: "com.ost.sdk.OstDeployTokenHolder", qos: .userInitiated)
    private let workflowTransactionCountForPolling = 2
    private let spendingLimit: String
    private var expireAfter: TimeInterval
    private var recoveryAddress: String? = nil
    private var multipleSessionData: OstSessionHelper.MultipleSessionData? = nil
    private var pinManager: OstPinManager? = nil
    
    /// Initialize.
    ///
    /// - Parameters:
    ///   - userId: User id
    ///   - userPin: User pin
    ///   - passphrasePrefix: Passphrase prefix provided by application server
    ///   - spendingLimit: Maximum spending limit of transaction
    ///   - expireAfter: Relative time
    ///   - delegate: Callback
    init(userId: String,
         userPin: String,
         passphrasePrefix: String,
         spendingLimit: String,
         expireAfter: TimeInterval,
         delegate: OstWorkflowDelegate) {
        
        self.spendingLimit = spendingLimit
        self.expireAfter = expireAfter
        
        super.init(userId: userId, delegate: delegate)
        
        self.pinManager = OstKeyManagerGateway
            .getOstPinManager(userId: self.userId,
                              passphrasePrefix: passphrasePrefix,
                              userPin: userPin)
    }
    
    /// Get workflow queue.
    ///
    /// - Returns: DispatchQueue
    override func getWorkflowQueue() -> DispatchQueue {
        return OstActivateUser.ostActivateUserQueue
    }
    
    /// Validate params for activate user
    ///
    /// - Throws: OstError
    override func validateParams() throws {
        try super.validateParams()
        
        try self.pinManager!.validatePinLength()
        try self.pinManager!.validatePassphrasePrefixLength()
        
        if  0 > self.expireAfter {
            throw OstError("w_au_vp_1", .invalidExpirationTimeStamp);
        }
        
        
        if ( !isValidNumber(input: self.spendingLimit) ) {
            throw OstError("w_au_vp_2", .invalidSpendingLimit)
        }        
    }
    
    /// Perfrom user device validation
    ///
    /// - Throws: OstError
    override func performUserDeviceValidation() throws {
        try super.performUserDeviceValidation()
        
        //Current user validation is done in super
        if self.currentUser!.isStatusActivated {
            throw OstError("w_au_pudv_1", .userAlreadyActivated)
        }
        
        if (!self.currentDevice!.isStatusRegistered
            && (self.currentDevice!.isStatusRevoking
                || self.currentDevice!.isStatusRevoked)) {
            throw OstError("w_au_pudv_3", .deviceNotSet);
        }
    }
    
    /// Should check whether current device authorized or not
    ///
    /// - Returns: `true` if check required, else `false`
    override func shouldCheckCurrentDeviceAuthorization() -> Bool {
        return false
    }
    
    override func onDeviceValidated() throws {
        let BiometricAuth: BiometricIDAuth = BiometricIDAuth(permissionText: "Would you like to use biometrics to authenticate your wallet?")
        BiometricAuth.authenticateUser { (isSuccess, message) in
            if (isSuccess) {
                let biometricManager = OstKeyManagerGateway.getOstBiometricManager(userId: self.userId)
                try? biometricManager.enableBiometric()
            }
            self.performState(OstUserAuthenticatorWorkflow.AUTHENTICATED)
        }
    }
    
    /// Activate user on device validated
    ///
    /// - Throws: OstError
    override func onUserAuthenticated() throws {
        if (self.currentUser!.isStatusActivating) {
            self.pollingForActivatingUser(self.currentUser!)
            return
        }
        
        self.recoveryAddress = try self.pinManager?.getRecoveryOwnerAddress()
        
        let noOfSessionsCount = OstConfig.noOfSessionsOnActivateUserCount()
        
        self.multipleSessionData = try OstSessionHelper(
            userId: self.userId,
            expiresAfter: self.expireAfter,
            spendingLimit: self.spendingLimit
            ).getMultipleSesssionData(sessionCount: noOfSessionsCount)
        
        try self.activateUser()
    }

    /// Activate user
    ///
    /// - Throws: OstError
    private func activateUser() throws {
        let params = self.getActivateUserParams()
        
        var ostError: OstError? = nil
        let group = DispatchGroup()
        var userEntity: OstUser? = nil
        group.enter()
        try OstAPIUser(userId: self.userId).activateUser(params: params, onSuccess: { (ostUser) in
            userEntity = ostUser
            group.leave()
        }) { (error) in
            ostError = error
            group.leave()
        }
        group.wait()
        
        if (nil == ostError) {
            self.postRequestAcknowledged(entity: userEntity!)
            self.pollingForActivatingUser(userEntity!)
        }else {
            throw ostError!
        }
    }
    
    /// Get params for activate user
    ///
    /// - Returns: Activate user params dictionary
    private func getActivateUserParams() -> [String: Any] {
        var params: [String: Any] = [:]
        params["spending_limit"] = self.spendingLimit
        params["recovery_owner_address"] = self.recoveryAddress!
        params["expiration_height"] = self.multipleSessionData!.expirationHeight
        params["session_addresses"] = self.multipleSessionData!.sessionAddresses
        params["device_address"] = self.currentDevice!.address!
        
        return params
    }
    
    /// Poll for activate user
    ///
    /// - Parameter ostUser: User entity
    private func pollingForActivatingUser(_ ostUser: OstUser) {
        
        let successCallback: ((OstUser) -> Void) = { ostUser in
            self.onPollingSuccess()
        }
        let failureCallback:  ((OstError) -> Void) = { error in
            self.postError(error)
        }
        // Logger.log(message: "test starting polling for userId: \(self.userId) at \(Date.timestamp())")
        
        OstUserPollingService(userId: ostUser.id,
                              successStatus: OstUser.Status.ACTIVATED.rawValue,
                              failureStatus: OstUser.Status.CREATED.rawValue,
                              workflowTransactionCount: workflowTransactionCountForPolling,
                              successCallback: successCallback,
                              failureCallback: failureCallback
            ).perform()
    }
    
    /// Fetch updated entities from server
    /// In that case, we are fetching session, device manager, user
    func onPollingSuccess() {
        let queue = DispatchQueue(label: "com.ost.onPollingSuccess", qos: .userInitiated)
        queue.async {
            if (nil != self.multipleSessionData?.sessionAddresses) {
                for sessionAddress in self.multipleSessionData!.sessionAddresses {
                    try? OstAPISession(userId: self.userId)
                        .getSession(
                            sessionAddress: sessionAddress,
                            onSuccess: nil,
                            onFailure: nil
                    )
                }
            }

            try? self.syncDeviceManager()
            try? self.syncCurrentDevice()
            self.postWorkflowComplete(entity: self.currentUser!)
        }
    }
    
    /// Get current workflow context
    ///
    /// - Returns: OstWorkflowContext
    override func getWorkflowContext() -> OstWorkflowContext {
        return OstWorkflowContext(workflowId: self.workflowId, workflowType: .activateUser)
    }
    
    /// Get context entity
    ///
    /// - Returns: OstContextEntity
    override func getContextEntity(for entity: Any) -> OstContextEntity {
        return OstContextEntity(entity: entity, entityType: .user)
    }
}
