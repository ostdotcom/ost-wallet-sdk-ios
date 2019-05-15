/*
 Copyright © 2019 OST.com Inc
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 */

import Foundation
import OstWalletSdk


struct OstNotificationModel {
    let workflowContext: OstWorkflowContext
    var contextEntity: OstContextEntity? = nil
    var error: OstError? = nil
}

class OstNotificationManager {
    static let getInstance = OstNotificationManager()
    private init () { }
    
    func getAppWindow() -> UIWindow? {
        return UIApplication.shared.keyWindow
    }
    
    var notificationView: OstNotification? = nil
    
    var notifications: [OstNotificationModel] = [OstNotificationModel]()
    
    //MARK: - Functions
    func show(withWorkflowContext workflowContext : OstWorkflowContext,
              contextEntity: OstContextEntity? = nil,
              error: OstError? = nil) {
        
        let model = OstNotificationModel(workflowContext: workflowContext,
                                         contextEntity: contextEntity,
                                         error: error)
        self.show(withNotificaion: model)
    }
    
    
    func show(withNotificaion notificationModel: OstNotificationModel) {
        if canShowNotification(notificationModel: notificationModel) {
            notifications.append(notificationModel)
        }
        showNext()
    }
    
   
    func canShowNotification(notificationModel: OstNotificationModel) -> Bool {
         return true
        let workflowContext = notificationModel.workflowContext
        
        if nil == notificationModel.contextEntity && nil == notificationModel.error {
            return false
        }
        
        if workflowContext.workflowType == .setupDevice && nil != notificationModel.contextEntity {
            return false
        }
        
        return true
    }
    
    func showNext() {
        if nil == notificationView,
            let notificationModel: OstNotificationModel = notifications.first {
            
            if nil != notificationModel.contextEntity {
                notificationView = OstSuccessNotification()
                notificationView?.notificationModel = notificationModel
            }else if nil != notificationModel.error {
                notificationView = OstErroNotification()
                notificationView?.notificationModel = notificationModel
            }
            
            if nil != notificationView {
                removeFirst()
                showNotificaiton()
            }else {
                showNext()
            }
        }
    }
    
    private func showNotificaiton() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {[weak self] in
            if let strongSelf = self,
                let window = strongSelf.getAppWindow(),
                let notificaitonV = strongSelf.notificationView {
                    
                    window.addSubview(notificaitonV)
                    notificaitonV.show(onCompletion: {[weak self] (isCompleted) in
                        self?.remove()
                    })
            }else {
                self?.remove()
            }
        }
    }
    
    func remove() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {[weak self] in
            if let strongSelf = self,
                nil != strongSelf.notificationView {
                
                strongSelf.notificationView!.hide(onCompletion: {[weak self] (isComplete) in
                    self?.notificationView = nil
                    self?.showNext()
                })
            }else {
                self?.notificationView = nil
                self?.showNext()
            }
        })
    }
    
    func removeFirst() {
        if notifications.count > 0 {
            notifications.remove(at: 0)
        }
    }
    
    func removeAll() {
        notifications.removeAll()
    }
}
