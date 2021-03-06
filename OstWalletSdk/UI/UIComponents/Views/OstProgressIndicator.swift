//
//  OstProgressIndicator.swift
//  TestDemoApp
//
//  Created by aniket ayachit on 02/05/19.
//  Copyright © 2019 aniket ayachit. All rights reserved.
//

import UIKit


class OstProgressIndicator: OstBaseView {
    
    //MARK: - Variables
    var progressText: String = ""
    {
        didSet {
            alert?.title = "\n\(progressText)"
        }
    }
    
    var progressMessage: String = ""
    {
        didSet {
            alert?.message = progressMessage
        }
    }
    
    var textCode: OstProgressIndicatorTextCode! {
        didSet {
            progressText = textCode.rawValue
        }
    }
    
    var alert: OstUIAlertController? = nil
    
    //MARK: - Initializier
    init(progressText: String = "") {
        self.progressText = progressText
        super.init(frame: .zero)
    }
    
    init(textCode: OstProgressIndicatorTextCode) {
        self.progressText = textCode.rawValue
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        progressText = ""
        super.init(coder: aDecoder)
    }
    
    //MARK: - Inporgress Alert
    func show() {
        
        let title = "\n\(progressText)"
        alert = OstUIAlertController(title: title,
                                  message: "",
                                  preferredStyle: .alert)
        
        let activ = UIActivityIndicatorView(style: .gray)
        activ.color = UIColor.color(22, 141, 193)
        activ.startAnimating()
        activ.translatesAutoresizingMaskIntoConstraints = false
        alert!.view.addSubview(activ)
        activ.centerXAnchor.constraint(equalTo: alert!.view.centerXAnchor).isActive = true
        activ.topAnchor.constraint(equalTo: alert!.view.topAnchor, constant: 15).isActive = true
        
        alert?.show();
    }
    
    @objc func hide(onCompletion: ((Bool) -> Void)? = nil) {
        
        if nil == alert {
            onCompletion?(true)
        }else {
            alert!.dismiss(animated: true, completion: {
                onCompletion?(true)
            })
        }
    }
    
    //MAKR: - Acknowledgement
    func showAcknowledgementAlert(forWorkflowType type: OstWorkflowType) {
        let title = getAcknowledgementText(workflowType: type)
        if !title.isEmpty {
            progressText = title
        }
    }
    
    //MARK: - Success Alert
    func showSuccessAlert(forWorkflowType type: OstWorkflowType,
                          duration: Double = 3,
                          actionButtonTitle btnTitle: String? = nil,
                          actionButtonTapped: ((UIAlertAction?) -> Void)? = nil,
                          onCompletion:((Bool) -> Void)? = nil) {
        
        let title = getWorkflowCompleteText(workflowType: type)
        let message = getWorkflowCompleteMessage(workflowType: type)
        showSuccessAlert(withTitle: title,
                         message: message,
                         duration: duration,
                         actionButtonTitle: btnTitle,
                         actionButtonTapped: actionButtonTapped,
                         onCompletion: onCompletion)
    }
    
    func showSuccessAlert(withTitle title: String = "",
                          message msg: String = "",
                          duration: Double = 3,
                          actionButtonTitle btnTitle: String? = nil,
                          actionButtonTapped: ((UIAlertAction?) -> Void)? = nil,
                          onCompletion:((Bool) -> Void)? = nil) {
        
        self.hide {[weak self] _ in
            
            guard let strongSelf = self else {
                onCompletion?(true)
                return
            }
            
            strongSelf.alert = OstUIAlertController(title: title,
                                                 message: msg,
                                                 preferredStyle: .alert)
            
            if nil != btnTitle {
                strongSelf.alert?.addAction(UIAlertAction(title: btnTitle, style: .default, handler: {[weak self] (actionButton) in
                    actionButtonTapped?(nil)
                    self?.hide()
                }))
            }
            
            strongSelf.alert?.show()
            if duration > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration , execute: {
                    self?.hide(onCompletion: onCompletion)
                })
            }
        }
    }
    
    //MARK: - Failure Alert
    func showFailureAlert(forWorkflowType type: OstWorkflowType,
                          error: OstError? = nil,
                          onCompletion:((Bool) -> Void)? = nil) {
        
        let title = getWorkflowInterruptedText(workflowType: type)
        showFailureAlert(withTitle: title, onCompletion: onCompletion)
    }
    
    func showFailureAlert(withTitle title: String = "",
                          message msg: String = "",
                          duration: Double = 3,
                          actionButtonTitle btnTitle: String? = nil,
                          actionButtonTapped: ((UIAlertAction?) -> Void)? = nil,
                          onCompletion:((Bool) -> Void)? = nil) {
        
        self.hide {[weak self] _ in
            
            guard let strongSelf = self else {
                onCompletion?(true)
                return
            }
            
            strongSelf.alert = OstUIAlertController(title: title,
                                                 message: msg,
                                                 preferredStyle: .alert)
            
            if nil != btnTitle {
                strongSelf.alert?.addAction(UIAlertAction(title: btnTitle, style: .default, handler: {[weak self] (actionButton) in
                    actionButtonTapped?(nil)
                    self?.hide()
                }))
            }
            
            strongSelf.alert?.show()
            if duration > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration , execute: {
                    self?.hide(onCompletion: onCompletion)
                })
            }
        }
    }
    
    
    func showAlert(withTitle title: String = "",
                   message msg: String = "",
                   duration: Double = 3,
                   actionButtonTitle btnTitle: String? = nil,
                   actionButtonTapped: ((UIAlertAction?) -> Void)? = nil,
                   cancelButtonTitle cancelTitle: String? = nil,
                   cancelButtonTapped: ((UIAlertAction?) -> Void)? = nil,
                   onHideAnimationCompletion: ((Bool) -> Void)? = nil) {
        
        self.hide {[weak self] _ in
            
            guard let strongSelf = self else {
                onHideAnimationCompletion?(false)
                return
            }
            
            strongSelf.alert = OstUIAlertController(title: title,
                                                 message: msg,
                                                 preferredStyle: .alert)
            
            if nil != btnTitle {
                strongSelf.alert?.addAction(UIAlertAction(title: btnTitle, style: .default, handler: {[weak self] (actionButton) in
                    actionButtonTapped?(actionButton)
                    self?.hide(onCompletion: onHideAnimationCompletion)
                }))
            }
            
            if nil != cancelTitle {
                strongSelf.alert?.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: {[weak self] (cancelButton) in
                    cancelButtonTapped?(cancelButton)
                    self?.hide(onCompletion: onHideAnimationCompletion)
                }))
            }
            
            strongSelf.alert?.show()
            if duration > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration , execute: {
                    self?.hide(onCompletion: onHideAnimationCompletion)
                })
            }
        }
    }
    
    //MARK: - Alert Text
    func getAcknowledgementText(workflowType: OstWorkflowType) -> String {
        switch workflowType {
        case .setupDevice:
            return ""
            
        case .activateUser:
            return ""
            
        case .addSession:
            return "Session authorization request received"
            
        case .getDeviceMnemonics:
            return ""
            
        case .performQRAction:
            return ""
            
        case .executeTransaction:
            return ""
            
        case .authorizeDeviceWithQRCode:
            return "Authorization request received"
            
        case .authorizeDeviceWithMnemonics:
            return "Authorization request received"
            
        case .initiateDeviceRecovery:
            return "Recovery request received "
            
        case .abortDeviceRecovery:
            return "Request to abort recovery received"
            
        case .revokeDevice:
            return "Revocation request received"
            
        case .resetPin:
            return "Reset request received. This request may take up to 60 seconds to process"
            
        case .logoutAllSessions:
            return "Revoking all session request received"
            
        case .updateBiometricPreference:
            return ""
            
        default:
            return ""
        }
    }
    
    func getWorkflowCompleteText(workflowType: OstWorkflowType) -> String {
        
        switch workflowType {
        case .setupDevice:
            return "Action completed!"
            
        case .activateUser:
            return "Action completed!"
            
        case .addSession:
            return "A session has been authorized. You can now make in-app transactions seamlessly"
            
        case .getDeviceMnemonics:
            return "Action completed!"
            
        case .performQRAction:
            return "Action completed!"
            
        case .executeTransaction:
            return "Transaction Submitted!"
            
        case .authorizeDeviceWithQRCode:
            return "This device is now authorized to access your Wallet "
            
        case .authorizeDeviceWithMnemonics:
            return "This device is now authorized to access your Wallet "
            
        case .initiateDeviceRecovery:
            return "Recovery Request Placed Successfully"
            
        case .abortDeviceRecovery:
            return "Recovery has been successfully aborted. Existing authorized devices may be used."
            
        case .revokeDevice:
            return "The chosen device has been revoked. It can no longer access your Wallet"
            
        case .resetPin:
            return "Your PIN has been reset. Please remember this new PIN. "
            
        case .logoutAllSessions:
            return "All sessions are revoked. Please create new session to send tokens."
            
        case .updateBiometricPreference:
            return "Biometric preference updated"
            
        default:
            return ""
        }
    }
    
    func getWorkflowCompleteMessage(workflowType: OstWorkflowType) -> String {
        switch workflowType {
        case .initiateDeviceRecovery:
            return "Your Wallet recovery has commenced. This process usually takes about 12 hours. You'll be notified when the wallet recovery is ready."
        default:
            return ""
        }
    }
    
    func getWorkflowInterruptedText(workflowType: OstWorkflowType) -> String {
        
        switch workflowType {
        case .setupDevice:
            return "Something went wrong"
            
        case .activateUser:
            return "Something went wrong"
            
        case .addSession:
            return "Session could not be authorized. Please re-enter confirmation"
            
        case .getDeviceMnemonics:
            return "Getting device mnemonics failed."
            
        case .performQRAction:
            return "Invalid QR-Code passsed. Please Scan correct QR-Code to perform action."
            
        case .executeTransaction:
            return "You have no authorized sessions to sign a trasnaction, please authorize a session "
            
        case .authorizeDeviceWithQRCode:
            return "Authorization failed. Please verify the QR code "
            
        case .authorizeDeviceWithMnemonics:
            return "Authorization failed. Please verify that the mnemonics are correct"
            
        case .initiateDeviceRecovery:
            return "Recovery could not be initiated. Please verify PIN "
            
        case .abortDeviceRecovery:
            return "Abort recovery failed. Unauthorized attempt "
            
        case .revokeDevice:
            return "Revokation failed. A device cannot revoke itself "
            
        case .resetPin:
            return "Reset PIN failed. Please verify that you entered the correct PIN "
            
        case .logoutAllSessions:
            return "Revoking all sessions failed. Please re-enter confirmation"
            
        case .updateBiometricPreference:
            return "Biometric preference update failed. Please re-enter confirmation"
            
        default:
            return ""
        }
    }
}

enum OstProgressIndicatorTextCode: String {
    case
    unknown = "Processing...",
    activingUser = "Activating user...",
    executingTransaction = "Transaction processing...",
    fetchingUser = "Loading...",
    stopDeviceRecovery = "Aborting recovery...",
    initiateDeviceRecovery = "Initiating recovery... ",
    logoutUser = "Logging out...",
    signup = "Signing up...",
    login = "Logging in...",
    resetPin = "Resetting PIN...",
    checkDeviceStatus = "Checking device status…",
    fetchingUserBalance = "Fetching user balance...",
    creatingSession = "Authorizing a session... ",
    authorizingDevice = "Authorizing Device....",
    revokingDevice = "Revoking Device...",
    revokingAllSessions = "Revoking all sessions...",
    fetchingDeviceList = "Fetching device list...",
    fetchingDeviceMnemonics = "Fetching device mnemonics...",
    updatingBiometricPreference = "Updating biometric preference..."
}
