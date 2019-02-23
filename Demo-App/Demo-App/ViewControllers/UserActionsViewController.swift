//
//  UserActionsViewController.swift
//  Demo-App
//
//  Created by Rachin Kapoor on 23/02/19.
//  Copyright © 2019 aniket ayachit. All rights reserved.
//

import UIKit
import MaterialComponents

private let reuseIdentifier = "MDCCollectionViewTextCell"

class UserActionsViewController: UICollectionViewController {
  var appBar = MDCAppBar()
  
  let ACTION_TYPE = "action";
  let ACTION_TEXT = "textLabel";
  let ACTION_DETAILS = "detailTextLabel";
  
  enum ACTIONS: String {
  case activateUser = "activateUser"
  case paperWallet = "paperWallet"
    case addSession = "addSession"
    case addDeviceByQRCode = "addDeviceByQRCode"
  }
  
  var dataItems:[[String:String]]?
  func buildData() {
    let currentUser = CurrentUser.getInstance();
    let ostUser = currentUser.ostUser!;
    let userDevice = currentUser.userDevice!;
    
    var addSession: [String:String] = [:];
    var setupWallet: [String:String] = [:];
    var paperWallet: [String:String] = [:];
    var addDeviceFromQRCode: [String:String] = [:];
    
    setupWallet[ACTION_TYPE] = ACTIONS.activateUser.rawValue;
    setupWallet[ACTION_TEXT] = "Setup your wallet";
    
    paperWallet[ACTION_TYPE] = ACTIONS.paperWallet.rawValue;
    paperWallet[ACTION_TEXT] = "See your paper wallet";
    
    if ( ostUser.isActivated() ) {
      setupWallet[ACTION_DETAILS] = "You have already setup your wallet.";
      paperWallet[ACTION_DETAILS] = "See your paper wallet";
        
        addSession[ACTION_TYPE] = ACTIONS.addSession.rawValue
        addSession[ACTION_TEXT] = "Create Session"
        addSession[ACTION_DETAILS] = "Create session to do transactions."
        
        addDeviceFromQRCode[ACTION_TYPE] = ACTIONS.addSession.rawValue
        addDeviceFromQRCode[ACTION_TEXT] = "Add Device from QR-Code"
        addDeviceFromQRCode[ACTION_DETAILS] = "Add Device from QR-Code."
        
    } else if ( ostUser.isActivating()) {
      setupWallet[ACTION_DETAILS] = "Your wallet is being setup.";
      paperWallet[ACTION_DETAILS] = "You need to setup your wallet before seeing 12 words";
    } else {
      setupWallet[ACTION_DETAILS] = "You need to setup your wallet to perform other actions.";
      
      if ( userDevice.isAuthorizing() ) {
        paperWallet[ACTION_DETAILS] = "Your device is authorizing.";
      } else if ( userDevice.isAuthorized() ) {
        paperWallet[ACTION_DETAILS] = "Your device is authorized.";
      } else if ( userDevice.isDeviceRegistered() ) {
        paperWallet[ACTION_DETAILS] = "Your device needs to be authorized.";
      } else if ( userDevice.isDeviceRevoked() ) {
        paperWallet[ACTION_DETAILS] = "Your device is revoked.";
      }
    }
    
    
    
    //Final Ordering.
    dataItems = [setupWallet, paperWallet, addSession, addDeviceFromQRCode];
  }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated);
    buildData();
  }
  
    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated);
      let screenSize = UIScreen.main.bounds
      let screenWidth = screenSize.width;

      let layout: UICollectionViewFlowLayout = self.collectionViewLayout as! UICollectionViewFlowLayout;
      layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
      layout.estimatedItemSize = CGSize(width: screenWidth, height: 100);
      layout.minimumInteritemSpacing = 0
      layout.minimumLineSpacing = 0
      self.collectionView!.collectionViewLayout = layout
    }
  
    override func viewDidLoad() {
      super.viewDidLoad()
      buildData();
      
      self.title = "Wallet Actions"
      
      self.collectionView?.backgroundColor = .white
      
      // AppBar Init
      self.addChild(appBar.headerViewController)
      self.appBar.headerViewController.headerView.trackingScrollView = self.collectionView
      appBar.addSubviewsToParent()

      self.view.backgroundColor = ApplicationScheme.shared.colorScheme.surfaceColor
      self.collectionView?.backgroundColor = ApplicationScheme.shared.colorScheme.surfaceColor
      
      
      // TODO: Theme our interface with our typography
      self.view.backgroundColor = ApplicationScheme.shared.colorScheme.surfaceColor
      MDCAppBarColorThemer.applySemanticColorScheme(ApplicationScheme.shared.colorScheme, to:self.appBar)
      MDCAppBarTypographyThemer.applyTypographyScheme(ApplicationScheme.shared.typographyScheme, to: self.appBar)

      let backItemImage = UIImage(named: "Back")
      let templatedBackItemImage = backItemImage?.withRenderingMode(.alwaysTemplate)
      let backItem = UIBarButtonItem(image: templatedBackItemImage,
                                     style: .plain,
                                     target: self,
                                     action: #selector(backItemTapped(sender:)))
      
      self.navigationItem.leftBarButtonItem = backItem;

      
      // Uncomment the following line to preserve selection between presentations
      // self.clearsSelectionOnViewWillAppear = false

      // Register cell classes
      self.collectionView!.register(MDCCollectionViewTextCell.self, forCellWithReuseIdentifier: reuseIdentifier)

      // Do any additional setup after loading the view.
    }

  @objc func backItemTapped(sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

  // MARK: UICollectionViewDataSource


  override func numberOfSections(in collectionView: UICollectionView) -> Int {
      // #warning Incomplete implementation, return the number of sections
    return 1;
  }


  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      // #warning Incomplete implementation, return the number of items
    return dataItems?.count ?? 0;
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    // Configure the cell
    let cell:MDCCollectionViewTextCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                        for: indexPath) as! MDCCollectionViewTextCell
    
    let itemData = dataItems![indexPath.item];
    cell.textLabel?.text = itemData[ACTION_TEXT]!;
    cell.detailTextLabel?.text = itemData[ACTION_DETAILS];
    cell.layer.borderWidth=1.0;
    cell.layer.borderColor = UIColor.lightGray.cgColor
    return cell
  }
  
    // MARK: UICollectionViewDelegate

  
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
  

  
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
  
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      let actionItem = dataItems![indexPath.item];
      let actionType:String = actionItem[ACTION_TYPE]! as String;
      
      //Initialize User
      if ( actionType.caseInsensitiveCompare(ACTIONS.activateUser.rawValue) == .orderedSame ) {
        let walletController = WalletViewController(nibName: nil, bundle: nil)
        walletController.viewMode = WalletViewController.ViewMode.SETUP_WALLET;
        self.present(walletController, animated: true, completion: nil);
      }
      //Paper Wallet.
      else if ( actionType.caseInsensitiveCompare(ACTIONS.paperWallet.rawValue) == .orderedSame ) {
        let walletController = WalletViewController(nibName: nil, bundle: nil);
        walletController.viewMode = WalletViewController.ViewMode.PAPER_WALLET;
        self.present(walletController, animated: true, completion: nil);
      }
        
      else if ( actionType.caseInsensitiveCompare(ACTIONS.addSession.rawValue) == .orderedSame ) {
        let walletController = WalletViewController(nibName: nil, bundle: nil);
        walletController.viewMode = WalletViewController.ViewMode.NEW_SESSION;
        self.present(walletController, animated: true, completion: nil);
        }
      
      else if ( actionType.caseInsensitiveCompare(ACTIONS.addSession.rawValue) == .orderedSame ) {
        let walletController = WalletViewController(nibName: nil, bundle: nil);
        walletController.viewMode = WalletViewController.ViewMode.NEW_SESSION;
        self.present(walletController, animated: true, completion: nil);
        }
    }
    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
//MARK: - UIScrollViewDelegate

// The following four methods must be forwarded to the tracking scroll view in order to implement
// the Flexible Header's behavior.

extension UserActionsViewController {
  
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if (scrollView == self.appBar.headerViewController.headerView.trackingScrollView) {
      self.appBar.headerViewController.headerView.trackingScrollDidScroll()
    }
  }
  
  override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    if (scrollView == self.appBar.headerViewController.headerView.trackingScrollView) {
      self.appBar.headerViewController.headerView.trackingScrollDidEndDecelerating()
    }
  }
  
  override func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                         willDecelerate decelerate: Bool) {
    let headerView = self.appBar.headerViewController.headerView
    if (scrollView == headerView.trackingScrollView) {
      headerView.trackingScrollDidEndDraggingWillDecelerate(decelerate)
    }
  }
  
  override func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    let headerView = self.appBar.headerViewController.headerView
    if (scrollView == headerView.trackingScrollView) {
      headerView.trackingScrollWillEndDragging(withVelocity: velocity,
                                               targetContentOffset: targetContentOffset)
    }
  }
  
}