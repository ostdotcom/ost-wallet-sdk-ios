//
//  AuthorizeDeviceConfirmViewController.swift
//  TestDemoApp
//
//  Created by aniket ayachit on 01/05/19.
//  Copyright © 2019 aniket ayachit. All rights reserved.
//

import UIKit
import OstWalletSdk

class VerifyAuthDeviceViewController: OstBaseScrollViewController {
    
    //MARK: - Variables
    var workflowContext: OstWorkflowContext? = nil
    var contextEntity: OstContextEntity? = nil
    var delegate: OstBaseDelegate?

    //MAKR: - Themers
    var leadLableThemer = OstTheme.leadLabel
    var deviceInfoThemer = OstTheme.leadLabel
    
    var primaryButtonThemer = OstTheme.primaryButton
    var secondaryButtonThemer = OstTheme.secondaryButton

    //MAKR: - Components
    var leadLabel: UILabel? = nil
    var addressTextLabel: UILabel? = nil
    var addressLabel: UILabel? = nil
    var authorizeButton: UIButton? = nil
    var cancelButton: UIButton? = nil
    
    let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.color(67, 139, 173, 0.1)
        view.layer.cornerRadius = 5
        
        return view
    }()
    
    deinit {
        print("deinit \(String(describing: self))")
    }
    
    override func getNavBarTitle() -> String {
        return "Authorize New Device"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let entity =  contextEntity?.entity as? OstDevice,
            let addrss = entity.address {
            self.addressLabel?.text = addrss
        }
    }
    
    override func addSubviews() {
        super.addSubviews()
        
        createLeadLabel()
        createAddressTextLabel()
        createAddressLabel()
        createAuthorizeButton()
        createCancelButton()
        
        addSubview(containerView)
    }
    
    func createLeadLabel() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "You’ve a new device authorization request from the following device"
        leadLableThemer.apply(label)
        leadLabel = label
        addSubview(label)
    }
    
    func createAddressTextLabel() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Device Address"
        deviceInfoThemer.apply(label)

        label.font = deviceInfoThemer.getFontProvider().get(size: 12)
        addressTextLabel = label
        containerView.addSubview(label)
    }
    
    func createAddressLabel() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "0x123"
        deviceInfoThemer.apply(label)
        label.font = deviceInfoThemer.getFontProvider().get(size: 12).bold()
        
        addressLabel = label
        containerView.addSubview(label)
    }
    
    func createAuthorizeButton() {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Authorize Device", for: .normal);
        primaryButtonThemer.apply(button)
        weak var weakSelf = self
        button.addTarget(weakSelf!, action: #selector(weakSelf!.authorizeDeviceTapped(_:)), for: .touchUpInside)
        authorizeButton = button
        addSubview(button)
    }
    
    func createCancelButton() {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Deny Request", for: .normal);
        
        secondaryButtonThemer.apply(button)
        weak var weakSelf = self
        button.addTarget(weakSelf!, action: #selector(weakSelf!.cancelDeviceTapped(_:)), for: .touchUpInside)
        cancelButton = button
        addSubview(button)
    }
    
    //MARK: - Apply Constraints
    
    override func addLayoutConstraints() {
        super.addLayoutConstraints()
        addLeadLabelConstraints()
        addAddressTextConstraints()
        addAddressConstraints()
        addContainerViewConstraints()
        addAuthorizeDeviceButtonConstraints()
        addCancelDeviceButtonConstraints()

        let lastView = cancelButton;
        lastView!.bottomAlignWithParent(constant: -20);
    }
    
    func addLeadLabelConstraints() {
        leadLabel?.topAlignWithParent()
        leadLabel?.applyBlockElementConstraints(horizontalMargin: 25)
    }
    
    func addAddressTextConstraints() {
        addressTextLabel?.topAlignWithParent(multiplier: 1, constant: 10)
        addressTextLabel?.applyBlockElementConstraints(horizontalMargin: 25)
    }
    
    func addAddressConstraints() {
        addressLabel?.placeBelow(toItem: addressTextLabel!, multiplier: 1, constant: 4)
        addressLabel?.applyBlockElementConstraints(horizontalMargin: 20)
    }
    
    func addContainerViewConstraints() {
        containerView.placeBelow(toItem: leadLabel!, multiplier: 1, constant: 25)
        containerView.applyBlockElementConstraints(horizontalMargin: 25)
        containerView.bottomAlign(toItem: addressLabel!, multiplier: 1, constant: 8)
    }
    
    func addAuthorizeDeviceButtonConstraints() {
        authorizeButton?.placeBelow(toItem: containerView, multiplier: 1, constant: 20)
        authorizeButton?.applyBlockElementConstraints(horizontalMargin: 50)
    }
    
    func addCancelDeviceButtonConstraints() {
        cancelButton?.placeBelow(toItem: authorizeButton!, multiplier: 1, constant: 20)
        cancelButton?.applyBlockElementConstraints(horizontalMargin: 50)
    }

    
    //MARK: - Actions
    
    @objc func authorizeDeviceTapped(_ sender: Any) {
        (self.delegate as? OstValidateDataDelegate)?.dataVerified()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelDeviceTapped(_ sender: Any) {
        (self.delegate as? OstValidateDataDelegate)?.cancelFlow()
        self.dismiss(animated: true, completion: nil)
    }
    
    override func tappedBackButton() {
        (self.delegate as? OstValidateDataDelegate)?.cancelFlow()
        self.dismiss(animated: true, completion: nil)
    }
}