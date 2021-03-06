/*
 Copyright © 2019 OST.com Inc
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 */

import Foundation

class OstAuthorizeDeviceViaQRWorkflowController: OstBaseWorkflowController {
    
    var authorizeDeviceQRScannerVC: OstAuthorizeDeviceQRScanner? = nil
    var validateDataDelegate: OstValidateDataDelegate? = nil
    var verfiyAuthDeviceVC: OstVerifyAuthorizeDevice? = nil
	
	var showFailureAlert = false;
    
	let addDevicePayload: String?
	
    @objc
    init(userId: String,
		 addDevicePayload: String? = nil,
		 passphrasePrefixDelegate: OstPassphrasePrefixDelegate?) {
		
		self.addDevicePayload = addDevicePayload;
        super.init(userId: userId,
                   passphrasePrefixDelegate: passphrasePrefixDelegate,
                   workflowType: .authorizeDeviceWithQRCode)
    }
    
    override func vcIsMovingFromParent(_ notification: Notification) {
        if nil != notification.object {
            if ((notification.object! as? OstBaseViewController) === self.authorizeDeviceQRScannerVC) {
                self.postFlowInterrupted(error: OstError("ui_i_wc_adqrwc_vimfp_1", .userCanceled))
                
            }else if (nil != self.getPinViewController && nil != self.sdkPinAcceptDelegate) {
                if (notification.object as? OstBaseViewController) === getPinViewController! {
                    self.sdkPinAcceptDelegate?.cancelFlow()
                }
            }
        }
    }
    
    override func performUIActions() {
		if (nil == addDevicePayload) {
			openScanQRForAuthorizeDeviceVC()
		}else {
			self.onScanndedDataReceived(self.addDevicePayload!)
		}
        
    }
    
    func openScanQRForAuthorizeDeviceVC() {
        DispatchQueue.main.async {
            self.authorizeDeviceQRScannerVC = OstAuthorizeDeviceQRScanner
                .newInstance(onSuccessScanning: {[weak self] (scannedData) in
                        if nil != scannedData {
                            self?.onScanndedDataReceived(scannedData!)
                        }
                    }, onErrorScanning: {[weak self] (error) in
                        let ostError = error ?? OstError("ui_i_wc_advqrwc_osqrfetvc_1", OstErrorCodes.OstErrorCode.unknown)
						self?.showFailureAlert = true
						self?.postFlowInterrupted(error: ostError);
                })
            
            self.authorizeDeviceQRScannerVC?.presentVCWithNavigation()
        }
    }
	
	override func shouldShowFailureAlert() -> Bool {
		let storedVal = self.showFailureAlert
		self.showFailureAlert = false
		return storedVal
	}
    
    func onScanndedDataReceived(_ data: String) {
        OstWalletSdk.performQRAction(userId: self.userId, payload: data, delegate: self)
        showInitialLoader(for: .authorizeDeviceWithQRCode)
    }
    
    override func getPinVCConfig() -> OstPinVCConfig {
        return OstContent.getAuthorizeDeviceViaQRPinVCConfig()
    }
    
    @objc override func showPinViewController() {
		if (nil == authorizeDeviceQRScannerVC) {
			self.getPinViewController?.presentVCWithNavigation()
		}else {
			self.getPinViewController?.pushViewControllerOn(self.authorizeDeviceQRScannerVC!)
		}
    }
    
    override func pinProvided(pin: String) {
        self.userPin = pin
        super.pinProvided(pin: pin)
    }
    
    override func onPassphrasePrefixSet(passphrase: String) {
        super.onPassphrasePrefixSet(passphrase: passphrase)
        showLoader(for: .authorizeDeviceWithQRCode)
    }

    override func verifyData(workflowContext: OstWorkflowContext,
                             ostContextEntity: OstContextEntity,
                             delegate: OstValidateDataDelegate) {
        
        validateDataDelegate = delegate
        if workflowContext.workflowType == .authorizeDeviceWithQRCode {
            openVerifyAuthDeviceVC(ostContextEntity: ostContextEntity)
        }else {
            delegate.cancelFlow()
        }
    }
    
    func openVerifyAuthDeviceVC(ostContextEntity: OstContextEntity) {
        DispatchQueue.main.async {
            self.hideLoader()
            self.verfiyAuthDeviceVC = OstVerifyAuthorizeDevice
                .newInstance(device: ostContextEntity.entity as! OstDevice,
                             authorizeCallback: {[weak self] (_) in

                                self?.showLoader(for: .authorizeDeviceWithQRCode)
                                self?.validateDataDelegate?.dataVerified()

                }) {[weak self] in
                    self?.validateDataDelegate?.cancelFlow()
            }
            
            self.verfiyAuthDeviceVC!.presentVC(animate: false)
        }
    }

    override func flowInterrupted(workflowContext: OstWorkflowContext, error: OstError) {
        if error.messageTextCode == OstErrorCodes.OstErrorCode.userCanceled
            && (nil != verfiyAuthDeviceVC || nil != getPinViewController)
			&& nil != authorizeDeviceQRScannerVC {
            
            verfiyAuthDeviceVC = nil
            getPinViewController = nil
            hideLoader()
            authorizeDeviceQRScannerVC?.scannerView?.startScanning()
        }else {
            super.flowInterrupted(workflowContext: workflowContext, error: error)
        }
    }
    
    override func cleanUp() {
        authorizeDeviceQRScannerVC?.removeViewController(flowEnded: true)
        authorizeDeviceQRScannerVC = nil
        validateDataDelegate = nil
        verfiyAuthDeviceVC?.dismissVC()
        verfiyAuthDeviceVC = nil
        super.cleanUp()
    }
}
