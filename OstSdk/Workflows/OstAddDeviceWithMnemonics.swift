//
//  OstAddDevice.swift
//  OstSdk
//
//  Created by aniket ayachit on 16/02/19.
//  Copyright © 2019 aniket ayachit. All rights reserved.
//

import Foundation
import UIKit

class OstAddDeviceWithMnemonics: OstWorkflowBase {
    static private let ostAddDeviceWithMnemonicsQueue = DispatchQueue(label: "com.ost.sdk.OstAddDeviceWithMnemonics", qos: .background)
    private let workflowTransactionCountForPolling = 1
    private let mnemonicsManager: OstMnemonicsKeyManager
    
    /// Initialize.
    ///
    /// - Parameters:
    ///   - userId: Kit user id.
    ///   - mnemonics: Mnemonics provided by user.
    ///   - delegate: Callback.
    init(userId: String,
         mnemonics: [String],
         delegate: OstWorkFlowCallbackDelegate) {
        
        self.mnemonicsManager = OstMnemonicsKeyManager(withMnemonics: mnemonics, andUserId: userId)
        super.init(userId: userId, delegate: delegate)
    }

    /// Get workflow Queue
    ///
    /// - Returns: DispatchQueue
    override func getWorkflowQueue() -> DispatchQueue {
        return OstAddDeviceWithMnemonics.ostAddDeviceWithMnemonicsQueue
    }
    
    /// Validiate basic parameters for workflow
    ///
    /// - Throws: OstError
    override func validateParams() throws {
        try super.validateParams()
        
        if (self.mnemonicsManager.isMnemonicsValid() == false) {
            throw OstError("w_adwm_p_1", .invalidMnemonics)
        }
        
        if (self.currentDevice!.isStatusAuthorized) {
            throw OstError("w_adwm_p_2", .deviceAuthorized)
        }
        try self.workFlowValidator!.isUserActivated()
        try self.workFlowValidator!.isDeviceRegistered()
    }
    
    /// process workflow.
    ///
    /// - Throws: OstError
    override func process() throws {
        try fetchDevice()
        self.authenticateUser()
    }
    
    /// Fetch device to validate mnemonics
    ///
    /// - Throws: OstError
    private func fetchDevice() throws {
        var error: OstError? = nil
        var deviceFromMnemonics: OstDevice? = nil
        let group = DispatchGroup()
        group.enter()
        try OstAPIDevice(userId: userId)
            .getDevice(
                deviceAddress: self.mnemonicsManager.address!,
                onSuccess: { (ostDevice) in
                    deviceFromMnemonics = ostDevice
                    group.leave()
        }) { (ostError) in
            error = ostError
            group.leave()
        }
        group.wait()
        
        if (nil != error) {
             throw error!
        }
        if (!deviceFromMnemonics!.isStatusAuthorized) {
            throw OstError("w_adwm_fd_1", OstErrorText.deviceNotAuthorized)
        }
        if (deviceFromMnemonics!.userId!.caseInsensitiveCompare(self.currentDevice!.userId!) != .orderedSame){
            throw OstError("w_adwm_fd_2", OstErrorText.differentOwnerDevice)
        }
    }

    /// Proceed with workflow after user is authenticated.
    override func proceedWorkflowAfterAuthenticateUser() {
        let queue: DispatchQueue = getWorkflowQueue()
        queue.async {
            let generateSignatureCallback: ((String) -> (String?, String?)) = { (signingHash) -> (String?, String?) in
                do {
                    let signature = try self.mnemonicsManager.sign(signingHash)
                    return (signature, self.mnemonicsManager.address)
                }catch {
                    return (nil, nil)
                }
            }
            
            let onSuccess: ((OstDevice) -> Void) = { (ostDevice) in
                self.postWorkflowComplete(entity: ostDevice)
            }
            
            let onFailure: ((OstError) -> Void) = { (error) in
                self.postError(error)
            }
            
            let onRequestAcknowledged: ((OstDevice) -> Void) = { (ostDevice) in
                self.postRequestAcknowledged(entity: ostDevice)
            }
            
            //Get device for address generated from mnemonics.
            OstAuthorizeDevice(userId: self.userId,
                               deviceAddressToAdd: self.currentDevice!.address!,
                               generateSignatureCallback: generateSignatureCallback,
                               onRequestAcknowledged: onRequestAcknowledged,
                               onSuccess: onSuccess,
                               onFailure: onFailure).perform()
        }
    }
    
    /// Get current workflow context
    ///
    /// - Returns: OstWorkflowContext
    override func getWorkflowContext() -> OstWorkflowContext {
        return OstWorkflowContext(workflowType: .addDevice)
    }
    
    /// Get context entity
    ///
    /// - Returns: OstContextEntity
    override func getContextEntity(for entity: Any) -> OstContextEntity {
        return OstContextEntity(entity: entity, entityType: .device)
    }
}
