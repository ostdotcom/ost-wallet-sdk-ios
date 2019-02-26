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
    
    let ostAddDeviceThread = DispatchQueue(label: "com.ost.sdk.OstAddDevice", qos: .background)
    let workflowTransactionCountForPolling = 1
    
    let mnemonics: [String]
    
    var user: OstUser? = nil
    var currentDevice: OstCurrentDevice? = nil
    var ostWalletKeys: OstWalletKeys? = nil
    
    init(userId: String,
         mnemonics: [String],
         delegate: OstWorkFlowCallbackProtocol) {
        self.mnemonics = mnemonics
        super.init(userId: userId, delegate: delegate)
    }
    
    /*
     * To Add device using QR
     * Device B to be added
     * 1.Validations
     *  1.1 Device should be registered
     *  1.2 User should be Activated.
     * 2. Ask App for flow
     *  2.1 QR Code
     *      2.1.1 generate multi sig code
     *      2.1.2 start polling
     *  2.2 Pin(Recovery address)
     *  2.3 12 Words
     *
     *
     * Device A which will add
     * 1. Scan QR code
     * 2. Sign with wallet key
     * 3. approve
     */
    override func perform() {
        ostAddDeviceThread.async {
            do {
                try self.validateParams()
                
                self.user = try self.getUser()
                if (self.user == nil) {
                    throw OstError1("w_adwm_p_1", OstErrorText.userNotFound)
                }
                
                if (!self.user!.isStatusActivated) {
                    throw OstError1("w_adwm_p_2", OstErrorText.userNotActivated)
                }
                
                self.currentDevice = try self.getCurrentDevice()
                if (self.currentDevice == nil) {
                    throw OstError1("w_adwm_p_3",  OstErrorText.deviceNotset)
                }
                
                if (!self.currentDevice!.isDeviceRegistered()) {
                    throw OstError1("w_adwm_p_4", .deviceNotRegistered)
                }
                
                self.ostWalletKeys = try OstCryptoImpls().generateEthereumKeys(withMnemonics: self.mnemonics)
                
                if (self.ostWalletKeys!.address == nil || self.ostWalletKeys!.privateKey == nil) {
                    throw OstError1("w_adwm_p_5", .walletGenerationFailed)
                }
                try self.fetchDevice()
            }catch let error {
                self.postError(error)
            }
        }
    }
    
    func validateParams() throws {
        let filteredWordsArray = self.mnemonics.filter({ $0 != ""})
        if (filteredWordsArray.isEmpty) {
            throw OstError.invalidInput("word list is not appropriate.")
        }
    }
    
    func fetchDevice() throws {
        try OstAPIDevice(userId: userId).getDevice(deviceAddress: self.ostWalletKeys!.address!, onSuccess: { (ostDevice) in
            do {
                if (!ostDevice.isStatusAuthorized) {
                    throw OstError1("w_adwm_fd_1", OstErrorText.deviceNotAuthorized)
                }
                if (ostDevice.address!.caseInsensitiveCompare(self.currentDevice!.address!) == .orderedSame){
                    throw OstError1("w_adwm_fd_2", OstErrorText.registerSameDevice)
                }
                self.authorizeDeviceWithMnemonics()
            }catch let error {
                self.postError(error)
            }
        }) { (ostError) in
            self.postError(ostError)
        }
    }
    
    //MARK: - authorize device
    func authorizeDeviceWithMnemonics() {
        let generateSignatureCallback: ((String) -> (String?, String?)) = { (signingHash) -> (String?, String?) in
            do {
                let signature = try OstCryptoImpls().signTx(signingHash, withPrivatekey: self.ostWalletKeys!.privateKey!)
                return (signature, self.ostWalletKeys!.address!)
                //Get device for address generated from mnemonics.
            }catch let error{
                self.postError(error)
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