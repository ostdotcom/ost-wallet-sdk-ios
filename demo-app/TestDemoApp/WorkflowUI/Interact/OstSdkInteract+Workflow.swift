/*
 Copyright © 2019 OST.com Inc
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
*/

import Foundation
import UIKit
import OstWalletSdk;
extension OstSdkInteract {
    
    
    public func activateUser(userId: String,
                             passphrasePrefixDelegate:OstPassphrasePrefixDelegate,
                             presenter:UIViewController,
                             spendingLimit: String = OstUtils.toAtto("15"),
                             expireAfterInSec: TimeInterval = TimeInterval(Double(14*24*60*60))
        ) -> OstWorkflowDelegate {
        let callback = OstActivateUserWorkflowController(userId: userId,
                                                 passphrasePrefixDelegate: passphrasePrefixDelegate,
                                                 presenter: presenter,
                                                 spendingLimit: spendingLimit,
                                                 expireAfterInSec: expireAfterInSec);
        OstSdkInteract.getInstance.retainWorkflowCallback(callback: callback);
        return callback;
    }
}
