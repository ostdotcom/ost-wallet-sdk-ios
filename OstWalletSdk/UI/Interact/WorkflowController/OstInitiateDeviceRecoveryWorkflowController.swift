/*
 Copyright © 2019 OST.com Inc
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 */

import UIKit


@objc class OstInitiateDeviceRecoveryWorkflowController: OstBaseWorkflowController {
    
    var recoverDeviceAddress: String?
    var deviceListController: OstInitiateRecoveryDLViewController? = nil
    
    /// Initialize
    ///
    /// - Parameters:
    ///   - userId: Ost user id
    ///   - recoverDeviceAddress: Device address to recover
    ///   - passphrasePrefixDelegate: Callback to get passphrase prefix from application
    @objc
    init(userId: String,
         recoverDeviceAddress: String?,
         passphrasePrefixDelegate: OstPassphrasePrefixDelegate) {
        
        self.recoverDeviceAddress = recoverDeviceAddress
        super.init(userId: userId,
                   passphrasePrefixDelegate: passphrasePrefixDelegate,
                   workflowType: .initiateDeviceRecovery);
    }
    
    override func performUIActions() {
        if nil == recoverDeviceAddress {
            self.openAuthorizedDeviceListController()
        } else {
            self.openGetPinViewController()
        }
    }
    
    override func performUserDeviceValidation() throws {
        try super.performUserDeviceValidation()
        
        if (!self.currentDevice!.isStatusRegistered) {
            throw OstError("ui_i_wc_idrwc_pudv_2", .deviceCanNotBeAuthorized);
        }
    }
    
    override func shouldCheckCurrentDeviceAuthorization() -> Bool {
        return false
    }
    
    @objc override func vcIsMovingFromParent(_ notification: Notification) {
        
        var isFlowCancelled: Bool = false
        if (nil == self.deviceListController && notification.object is OstPinViewController)
            || (nil != self.deviceListController && notification.object is OstInitiateRecoveryDLViewController) {
            
            isFlowCancelled = true
        }
        
        if ( isFlowCancelled ) {
            self.postFlowInterrupted(error: OstError("ui_i_wc_auwc_vmfp_1", .userCanceled))
        }
    }
    
    override func getPinVCConfig() -> OstPinVCConfig {
        return OstContent.getRecoveryAccessPinVCConfig()
    }
    
    override func showPinViewController() {
        if nil == self.deviceListController {
            self.getPinViewController!.presentVCWithNavigation()
        }else {
            self.getPinViewController!.pushViewControllerOn(self.deviceListController!)
        }
    }
    
    func openAuthorizedDeviceListController() {
        DispatchQueue.main.async {
            self.deviceListController = OstInitiateRecoveryDLViewController
                .newInstance(userId: self.userId,
                             workflowRef: self,
                             callBack: {[weak self] (device) in
                                self?.recoverDeviceAddress = (device?["address"] as? String) ?? ""
                                self?.openGetPinViewController()
                })
            self.deviceListController!.presentVCWithNavigation()
        }
    }
    
    override func pinProvided(pin: String) {
        self.userPin = pin
        super.pinProvided(pin: pin)
    }
    
    override func onPassphrasePrefixSet(passphrase: String) {
        OstWalletSdk.initiateDeviceRecovery(userId: self.userId,
                                            recoverDeviceAddress: self.recoverDeviceAddress!,
                                            userPin: self.userPin!,
                                            passphrasePrefix: passphrase,
                                            delegate: self)
        showLoader(for: .initiateDeviceRecovery)
    }
    
    override func cleanUp() {
        if ( nil != self.deviceListController ) {
            self.deviceListController?.removeViewController(flowEnded: true)
        }else if ( nil != self.getPinViewController )  {
            self.getPinViewController?.removeViewController(flowEnded: true)
        }
        self.deviceListController = nil
        super.cleanUp();
    }
}
