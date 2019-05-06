//
//  DAWalletViewController.swift
//  DemoApp
//
//  Created by aniket ayachit on 20/04/19.
//  Copyright © 2019 aniket ayachit. All rights reserved.
//

import UIKit

class OstWalletViewController: OstBaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - Components
    var walletTableView: UITableView = {
        let tableView: UITableView = UITableView(frame: .zero, style: .plain)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        return tableView
    }()
    var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Transactions...")
        refreshControl.tintColor = UIColor.color(22, 141, 193)
        
        return refreshControl
    }()
    var paginatingCell: PaginationLoaderTableViewCell?
    
    //MARK: - Variables
    var isNewDataAvailable: Bool = false
    var isViewUpdateInProgress: Bool = false
    var shouldReloadData: Bool = false
    var shouldLoadNextPage: Bool = true
    var isApiCallInProgress: Bool = false
    
    var tableDataArray: [[String: Any]] = [[String: Any]]()
    var meta: [String: Any]? = nil
    
    var paginationTriggerPageNumber = 1
    
    var paginatingViewCount = 1
    
    //MARK: - View LC
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: - Views
    override func getNavBarTitle() -> String {
        return "Wallet"
    }
    
    override func addSubviews() {
        super.addSubviews()
        setupUsersTableView()
        setupRefreshControl()
    }
    
    func setupUsersTableView() {
        self.view.addSubview(walletTableView)
        walletTableView.delegate = self
        walletTableView.dataSource = self
        registerTableViewCells()
    }
    
    func registerTableViewCells() {
        self.walletTableView.register(TransactionTableViewCell.self,
                                      forCellReuseIdentifier: TransactionTableViewCell.transactionCellIdentifier)
        self.walletTableView.register(WalletValueTableViewCell.self,
                                      forCellReuseIdentifier: WalletValueTableViewCell.cellIdentifier)
        self.walletTableView.register(PaginationLoaderTableViewCell.self,
                                      forCellReuseIdentifier: PaginationLoaderTableViewCell.cellIdentifier)
    }
    
    func setupRefreshControl() {
        
        if #available(iOS 10.0, *) {
            self.walletTableView.refreshControl = self.refreshControl
        } else {
            self.walletTableView.addSubview(self.refreshControl)
        }
    }
    
    //MARK: - Constraints
    
    override func addLayoutConstraints() {
        super.addLayoutConstraints()
        applyCollectionViewConstraints()
    }
    
    func applyCollectionViewConstraints() {
        
        walletTableView.topAlignWithParent()
        walletTableView.applyBlockElementConstraints(horizontalMargin: 0)
        walletTableView.bottomAlignWithParent()
    }
    
    //MARK: - Table View Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return tableDataArray.count
        case 2:
            return paginatingViewCount
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: BaseTableViewCell
        switch indexPath.section {
        case 0:
            let valueCell = tableView.dequeueReusableCell(withIdentifier: WalletValueTableViewCell.cellIdentifier, for: indexPath) as! WalletValueTableViewCell
            cell = valueCell as BaseTableViewCell
            cell.endDisplay()
            
        case 1:
            let tansactionCell: TransactionTableViewCell = tableView.dequeueReusableCell(withIdentifier: TransactionTableViewCell.transactionCellIdentifier, for: indexPath) as! TransactionTableViewCell
            
            if self.tableDataArray.count > indexPath.row {
                //                let transactionDetails = self.tableDataArray[indexPath.row]
                //                tansactionCell.userData = transactionDetails
                //                if let appUserId = ConversionHelper.toString(transactionDetails["app_user_id"]) {
                ////                    tansactionCell.userBalance = self.userBalances[appUserId] as? [String: Any] ?? [:]
                //                }else {
                ////                    tansactionCell = [:]
                //                }
                
                //                tansactionCell.sendButtonAction = {[weak self] (userDetails) in
                //                    if let strongSelf = self {
                //                        strongSelf.sendButtonTapped(userDetails)
                //                    }
                //                }
                
            }else {
                
            }
            
            cell = tansactionCell
        case 2:
            let pCell: PaginationLoaderTableViewCell
            if nil == self.paginatingCell {
                pCell = tableView.dequeueReusableCell(withIdentifier: PaginationLoaderTableViewCell.cellIdentifier, for: indexPath) as! PaginationLoaderTableViewCell
                self.paginatingCell = pCell
            }else {
                pCell = self.paginatingCell!
            }
            
            if self.isNewDataAvailable || self.shouldReloadData || !self.shouldLoadNextPage {
                pCell.startAnimating()
            }else {
                pCell.stopAnimating()
            }
            
            cell = pCell as BaseTableViewCell
            
        default:
            cell = BaseTableViewCell()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return self.view.frame.width * 0.5
        case 1:
            return 75.0
        case 2:
            if self.isNewDataAvailable || self.shouldReloadData || !self.shouldLoadNextPage {
                return 44.0
            }else {
                self.paginatingCell?.stopAnimating()
                return 0.0
            }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let container = UIView()
        container.backgroundColor = .white
        
        if 1 == section {
            let sectionTitle = UILabel()
            sectionTitle.numberOfLines = 1
            sectionTitle.textColor = UIColor.gray
            sectionTitle.translatesAutoresizingMaskIntoConstraints = false
            sectionTitle.font = UIFont(name: "Lato", size: 13)?.bold()
            sectionTitle.text = "TRANSACTION HISTORY"
            
            container.addSubview(sectionTitle)
            
            sectionTitle.topAlignWithParent(multiplier: 1, constant: 20)
            sectionTitle.leftAlignWithParent(multiplier: 1, constant: 20)
            sectionTitle.rightAlignWithParent(multiplier: 1, constant: 20)
            sectionTitle.bottomAlignWithParent()
        }
        return container
    }
    
    //MARK: - Pull to Refresh
    @objc func pullToRefresh(_ sender: Any? = nil) {
        self.fetchUsers(hardRefresh: true)
    }
    
    func reloadDataIfNeeded() {
        
        let isScrolling: Bool = (self.walletTableView.isDragging) || (self.walletTableView.isDecelerating)
        
        if !isScrolling && self.isNewDataAvailable {
            self.walletTableView.reloadData()
            self.isNewDataAvailable = false
            self.shouldLoadNextPage = true
        }
        
        if !isApiCallInProgress {
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            self.walletTableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        }
    }
    
    func fetchUsers(hardRefresh: Bool = false) {
        if isApiCallInProgress {
            reloadDataIfNeeded()
            return
        }
        if hardRefresh {
            meta = nil
            tableDataArray = []
        }else if nil != meta && meta!.isEmpty {
            reloadDataIfNeeded()
            return
        }
        isApiCallInProgress = true
        //        UserAPI.getUsers(meta: meta, onSuccess: {[weak self] (apiResponse) in
        //            if let strongSelf = self {
        //                strongSelf.onFetchUserSuccess(apiResponse)
        //            }
        //            }, onFailure: {[weak self] (apiResponse) in
        //                if let strongSelf = self {
        //                    strongSelf.isApiCallInProgress = false
        //                }
        //        })
    }
    
}