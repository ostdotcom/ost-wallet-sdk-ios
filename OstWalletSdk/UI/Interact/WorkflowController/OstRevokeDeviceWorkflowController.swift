/*
 Copyright © 2019 OST.com Inc
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 */

import Foundation

class OstRevokeDeviceWorkflowController: OstBaseWorkflowController {
    var revokeDeviceAddress: String?
    var deviceListController: OstRevokeDLViewController? = nil
    
    /// Initialize
    ///
    /// - Parameters:
    ///   - userId: Ost user id
    ///   - recoverDeviceAddress: Device address to recover
    ///   - passphrasePrefixDelegate: Callback to get passphrase prefix from application
    @objc
    init(userId: String,
         revokeDeviceAddress: String?,
         passphrasePrefixDelegate: OstPassphrasePrefixDelegate) {
        
        self.revokeDeviceAddress = revokeDeviceAddress
        super.init(userId: userId,
                   passphrasePrefixDelegate: passphrasePrefixDelegate,
                   workflowType: .revokeDevice);
    }
    
    override func vcIsMovingFromParent(_ notification: Notification) {
        if (nil != self.deviceListController && notification.object is OstRevokeDLViewController) {
            
            self.getPinViewController = nil
            
            self.postFlowInterrupted(error: OstError("ui_i_wc_rdwc_vmfp_1", .userCanceled))
        }
    }
    
    override func performUIActions() {
        if nil == revokeDeviceAddress {
            self.openAuthorizedDeviceListController()
        }else {
            showInitialLoader(for: .revokeDevice)
            onDeviceAddressSet()
        }
    }
    
    override func getPinVCConfig() -> OstPinVCConfig {
        return OstContent.getRevokeDevicePinVCConfig()
    }
    
    func openAuthorizedDeviceListController() {
        DispatchQueue.main.async {
            self.deviceListController = OstRevokeDLViewController
                .newInstance(userId: self.userId,
                             callBack: {[weak self] (device) in
                                self?.revokeDeviceAddress = (device?["address"] as? String) ?? ""
                                self?.showLoader(for: .revokeDevice)
                                self?.onDeviceAddressSet()
                })
            
            self.deviceListController!.presentVCWithNavigation()
        }
    }
    
    @objc override func showPinViewController() {
        if nil == self.deviceListController {
            self.getPinViewController?.presentVCWithNavigation()
        }else {
            self.getPinViewController?.pushViewControllerOn(self.deviceListController!)
        }
    }
    
    override func pinProvided(pin: String) {
        self.userPin = pin
        super.pinProvided(pin: pin)
    }
    
    override func onPassphrasePrefixSet(passphrase: String) {
        super.onPassphrasePrefixSet(passphrase: passphrase)
        showLoader(for: .revokeDevice)
    }
    
    func onDeviceAddressSet() {
        OstWalletSdk.revokeDevice(userId: self.userId,
                                  deviceAddressToRevoke: revokeDeviceAddress!,
                                  delegate: self)
    }
    
    override func cleanUp() {
        if ( nil != self.deviceListController ) {
            self.deviceListController?.removeViewController(flowEnded: true)
        }
        self.deviceListController = nil
        super.cleanUp()
    }
}
