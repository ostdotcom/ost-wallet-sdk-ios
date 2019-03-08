//
//  ResetPinView.swift
//  Demo-App
//
//  Created by aniket ayachit on 07/03/19.
//  Copyright © 2019 aniket ayachit. All rights reserved.
//

import Foundation
import UIKit
import OstSdk

class ResetPinView: AddSessionView {
    
    @objc override func didTapNext(sender: Any) {
//        super.didTapNext(sender: sender)
        let currentUser = CurrentUser.getInstance()
        
        OstSdk.resetPin(userId: currentUser.ostUserId!,
                        password: currentUser.userPinSalt!,
                        oldPin: spendingLimitTestField.text!,
                        newPin: expiresAfterTextField.text!,
                        delegate: self.sdkInteract)
    }
    
    override func viewDidAppearCallback() {
        spendingLimitTestFieldController?.placeholderText = "Old Pin"
        expirationHeightTextFieldController?.placeholderText = "New Pin"
        expiresAfterTextField.delegate = self
        expiresAfterTextField.text = ""
        self.nextButton.setTitle("Reset Pin", for: .normal);
    }
    
    override func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true;
    }
}