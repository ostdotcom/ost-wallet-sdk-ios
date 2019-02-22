//
//  OstAddSession.swift
//  OstSdk
//
//  Created by aniket ayachit on 19/02/19.
//  Copyright © 2019 aniket ayachit. All rights reserved.
//

import Foundation

class OstAddSession: OstWorkflowBase {
    let ostAddSessionThread = DispatchQueue(label: "com.ost.sdk.OstAddSession", qos: .background)
    let workflowTransactionCountForPolling = 2
    
    var spendingLimit: String
    var expirationHeight: Int
    
    var user: OstUser? = nil
    var currentDevice: OstCurrentDevice? = nil
    var walletKeys: OstWalletKeys? = nil
    var currentBlockHeight: Int = 0
    var chainInfo: [String: Any]? = nil
    
    init(userId: String, spendingLimit: String, expirationHeight: Int, delegate: OstWorkFlowCallbackProtocol) {
        self.spendingLimit = spendingLimit
        self.expirationHeight = expirationHeight
        super.init(userId: userId, delegate: delegate)
    }
    
    override func perform() {
        ostAddSessionThread.async {
            self.generateSessionKeys()
            self.getCurrentBlockHeight()
        }
    }
    
    func generateSessionKeys() {
        do {
            self.walletKeys = try OstCryptoImpls().generateCryptoKeys()
            
            if (self.walletKeys == nil || self.walletKeys!.privateKey == nil || self.walletKeys!.address == nil) {
                self.postError(OstError.actionFailed("activation of user failed."))
            }
            
            self.currentDevice = try getCurrentDevice()
            if (nil == self.currentDevice) {
                throw OstError.invalidInput("Device is not present.")
            }
            
            let sessionKeyInfo: OstSessionKeyInfo = try self.currentDevice!.encrypt(privateKey: walletKeys!.privateKey!)
            
            var ostSecureKey = OstSecureKey(address: walletKeys!.address!, privateKeyData: sessionKeyInfo.sessionKeyData, isSecureEnclaveEnrypted: sessionKeyInfo.isSecureEnclaveEncrypted)
            ostSecureKey = OstSecureKeyRepository.sharedSecureKey.insertOrUpdateEntity(ostSecureKey) as! OstSecureKey
        }catch let error {
            self.postError(error)
        }
    }
    
    func getCurrentBlockHeight() {
        do {
            let onSuccess: (([String: Any]) -> Void) = { chainInfo in
                self.chainInfo = chainInfo
                self.authorizeSession()
            }
            
            let onFailuar: ((OstError) -> Void) = { error in
                self.postError(error)
            }
            
            _ = try OstAPIChain(userId: self.userId).getChain(onSuccess: onSuccess, onFailure: onFailuar)
        }catch let error {
            self.postError(error)
        }
    }
    
    func authorizeSession() {
        
        let generateSignatureCallback: ((String) -> (String?, String?)) = { (signingHash) -> (String?, String?) in
            do {
                let keychainManager = OstKeyManager(userId: self.userId)
                if let deviceAddress = keychainManager.getDeviceAddress() {
                    let privatekey = try keychainManager.getDeviceKey()
                    let signature = try OstCryptoImpls().signTx(signingHash, withPrivatekey: privatekey!)
                    return (signature, deviceAddress)
                }
                throw OstError.actionFailed("issue while generating signature.")
            }catch {
                return (nil, nil)
            }
        }
        
        let onSuccess: ((OstSession) -> Void) = { (ostSession) in
            self.pollingForAuthorizeSession(ostSession)
        }
        
        let onFailure: ((OstError) -> Void) = { (error) in
            self.postError(error)
        }
        
        self.currentBlockHeight = OstUtils.toInt(self.chainInfo!["block_height"])!
        self.generateAndSaveSessionEntity()
     
        OstAuthorizeSession(userId: self.userId,
                            sessionAddress: self.walletKeys!.address!,
                            spendingLimit: self.spendingLimit,
                            expirationHeight: OstUtils.toString(self.currentBlockHeight + self.expirationHeight)!,
                            generateSignatureCallback: generateSignatureCallback,
                            onSuccess: onSuccess,
                            onFailure: onFailure).perform()
    }
    
    func generateAndSaveSessionEntity() {
        do {
            let params = self.getSessionEnityParams()
            _ = try OstSession.parse(params)
        }catch let error {
            self.postError(error)
        }
    }
    
    func getSessionEnityParams() -> [String: Any] {
        var params: [String: Any] = [:]
        params["user_id"] = self.userId
        params["address"] = self.walletKeys!.address!
        params["expiration_height"] = self.currentBlockHeight + self.expirationHeight
        params["spending_limit"] = self.spendingLimit
        params["nonce"] = 0
        params["status"] = OstSession.SESSION_STATUS_CREATED
        
        return params
    }
    
    func pollingForAuthorizeSession(_ ostSession: OstSession) {
        
        let successCallback: ((OstSession) -> Void) = { ostSession in
            self.postFlowComplete(entity: ostSession)
        }
        
        let failuarCallback:  ((OstError) -> Void) = { error in
            self.postError(error)
        }
        Logger.log(message: "test starting polling for userId: \(self.userId) at \(Date.timestamp())")
        
        OstSessionPollingService(userId: ostSession.userId!,
                                 sessionAddress: ostSession.address!,
                                 workflowTransactionCount: workflowTransactionCountForPolling,
                                 successCallback: successCallback, failuarCallback: failuarCallback).perform()
    }
    
    func postFlowComplete(entity: OstSession) {
        Logger.log(message: "OstAddSession flowComplete", parameterToPrint: entity.data)
        
        DispatchQueue.main.async {
            let contextEntity: OstContextEntity = OstContextEntity(type: .addSession , entity: entity)
            self.delegate.flowComplete(contextEntity);
        }
    }
}
