/*
 Copyright 2018-present the Material Components for iOS authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit
import OstSdk
import MaterialComponents

class WalletViewController: UIViewController {
  var appBar = MDCAppBar()
  public var showHeaderBackItem = true;
  
  
  public enum ViewMode {
    case SETUP_WALLET
    case ADD_DEVICE
    case NEW_SESSION
    case QR_CODE
    case PAPER_WALLET
  }
  
  var isLoginMode:Bool = true;
  //Default View Mode.
  public var viewMode = ViewMode.SETUP_WALLET;


  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    //Setup text field controllers
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // choose view based on mode.
    let choosenView = chooseSubView();
    view.addSubview(choosenView)
    
    // AppBar Init
    self.addChild(appBar.headerViewController)
    appBar.addSubviewsToParent()
    self.view.backgroundColor = ApplicationScheme.shared.colorScheme.surfaceColor
    MDCAppBarColorThemer.applySemanticColorScheme(ApplicationScheme.shared.colorScheme, to:self.appBar)
    MDCAppBarTypographyThemer.applyTypographyScheme(ApplicationScheme.shared.typographyScheme, to: self.appBar)
    choosenView.backgroundColor = ApplicationScheme.shared.colorScheme.surfaceColor;

    // Setup Navigation Items
    if ( showHeaderBackItem ) {
      let backItemImage = UIImage(named: "Back")
      let templatedBackItemImage = backItemImage?.withRenderingMode(.alwaysTemplate)
      let backItem = UIBarButtonItem(image: templatedBackItemImage,
                                     style: .plain,
                                     target: self,
                                     action: #selector(backItemTapped(sender:)))
      
      self.navigationItem.leftBarButtonItem = backItem;
    }

    
    
    choosenView.translatesAutoresizingMaskIntoConstraints = false;
    choosenView.backgroundColor = .white
    choosenView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    

    view.tintColor = .black
    choosenView.backgroundColor = .white

    

    NSLayoutConstraint.activate(
      NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]|",
                                     options: [],
                                     metrics: nil,
                                     views: ["scrollView" : choosenView])
    )
    NSLayoutConstraint.activate(
      NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|",
                                     options: [],
                                     metrics: nil,
                                     views: ["scrollView" : choosenView])
    )
    
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapTouch))
    choosenView.addGestureRecognizer(tapGestureRecognizer)
    choosenView.walletViewController = self;
  }
  
  func chooseSubView() -> BaseWalletView {
    switch viewMode {
    case ViewMode.PAPER_WALLET:
      self.title = "Paper Wallet";
      return PaperWalletView();
    case ViewMode.SETUP_WALLET:
      self.title = "Setup Your Wallet";
      return SetupWalletView()
    case ViewMode.NEW_SESSION:
        self.title = "Create Sesssion";
        return AddSessionView()
    default:
      self.title = "Setup Your Wallet";
      return SetupWalletView()
    }
  }
  
  // MARK: - Gesture Handling
  
  @objc func didTapTouch(sender: UIGestureRecognizer) {
    view.endEditing(true)
  }

  @objc func backItemTapped(sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
    
}