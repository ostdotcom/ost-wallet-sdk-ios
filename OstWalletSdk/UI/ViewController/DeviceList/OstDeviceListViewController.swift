//
/*
 Copyright © 2019 OST.com Inc
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 */

import Foundation


@objc class OstDeviceListViewController: OstBaseViewController, UITableViewDelegate, UITableViewDataSource, OstJsonApiDelegate  {
    var onCellSelected: (([String: Any]?) ->Void)? = nil
    
    enum DeviceStatus: String {
        case authorized
    }
    
    //MAKR: - Components
    var deviceTableView: UITableView = {
        let tableView: UITableView = UITableView(frame: .zero, style: .plain)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        return tableView
    }()
    
    var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = .white
        refreshControl.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        //        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Users...")
        refreshControl.tintColor = UIColor.color(22, 141, 193)
        
        return refreshControl
    }()
    
    let titleLabel: OstH1Label = {
        return OstH1Label(text: "")
    }()
    
    let leadLabel: OstH3Label = {
        return OstH3Label(text: "")
    }()
    
    var paginatingCell: OstPaginationLoaderTableViewCell? = nil
    
    //MARK: - Variables
    var isNewDataAvailable: Bool = false
    var isViewUpdateInProgress: Bool = false
    var shouldReloadData: Bool = false
    var shouldLoadNextPage: Bool = true
    var isApiCallInProgress: Bool = false
    
    var paginationTriggerPageNumber = 1
    var paginatingViewCount = 1
    
    var consumedDevices: [String: Any] = [String: Any]()
    
    var tableDataArray: [[String: Any]] = [[String: Any]]()
    
    var updatedTableArray: [[String: Any]] = [[String: Any]]()
    var meta: [String: Any]? = nil
    
    var pageConfig: [String: Any]? = nil
    
    let MIN_REQUIRED_DEVICE_LIST = 5
    
    var canShowEmptyScreen: Bool = false
    
    weak var workflowRef: OstWorkflowCallbacks? = nil
    
    override func configure() {
        super.configure();
        
        titleLabel.updateAttributedText(data: pageConfig?[OstContent.OstComponentType.titleLabel.getComponentName()],
                                        placeholders: pageConfig?[OstContent.OstComponentType.placeholders.getComponentName()])
        
        leadLabel.updateAttributedText(data: pageConfig?[OstContent.OstComponentType.infoLabel.getComponentName()],
                                       placeholders: pageConfig?[OstContent.OstComponentType.placeholders.getComponentName()])
        
        self.shouldFireIsMovingFromParent = true;
    }
    
    func getActionButtonText() -> String {
        if nil != pageConfig {
            if let cell = pageConfig!["cell"] as? [String: Any],
                let actionButton = cell["action_button"] as? [String: Any],
                let text = actionButton["text"] as? String {
                
                return text
            }
        }
        return ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getDeviceList(hardRefresh: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isApiCallInProgress {
            workflowRef?.showInitialLoader(for: getWorkflowType())
        }
    }
    
    func getWorkflowType() -> OstWorkflowType {
        fatalError("getWorkflowType did not override")
    }
    
    //MARK: - Add Subview
    override func addSubviews() {
        super.addSubviews()
        
        setupTableView()
        self.addSubview(titleLabel)
        self.addSubview(leadLabel)
        self.addSubview(deviceTableView)
    }
    
    func setupTableView() {
        deviceTableView.delegate = self
        deviceTableView.dataSource = self
        
        registerCells()
        setupRefreshControl()
    }
    
    func registerCells() {
        self.deviceTableView.register(OstDeviceTableViewCell.self,
                                      forCellReuseIdentifier: OstDeviceTableViewCell.deviceCellIdentifier)
        
        self.deviceTableView.register(OstPaginationLoaderTableViewCell.self,
                                      forCellReuseIdentifier: OstPaginationLoaderTableViewCell.paginationCellIdentifier)
        
        self.deviceTableView.register(OstEmptyDLTableViewCell.self,
                                      forCellReuseIdentifier: OstEmptyDLTableViewCell.emptyDLCellIdentifier)
    }
    
    func setupRefreshControl() {
        
        if #available(iOS 10.0, *) {
            self.deviceTableView.refreshControl = self.refreshControl
        } else {
            self.deviceTableView.addSubview(self.refreshControl)
        }
    }
    
    //MARK: - Add Constraints
    override func addLayoutConstraints() {
        super.addLayoutConstraints()
        addTitleLabelLayoutConstraints()
        addLeadLabelLayoutConstraints()
        addDeviceTableConstraitns()
    }
    
    func addTitleLabelLayoutConstraints() {
        titleLabel.topAlignWithParent(multiplier: 1, constant: 20)
        titleLabel.applyBlockElementConstraints()
    }
    
    func addLeadLabelLayoutConstraints() {
        leadLabel.placeBelow(toItem: titleLabel)
        leadLabel.applyBlockElementConstraints(horizontalMargin: 40)
    }
    
    func addDeviceTableConstraitns() {
        deviceTableView.placeBelow(toItem: leadLabel)
        deviceTableView.applyBlockElementConstraints(horizontalMargin: 0)
        deviceTableView.bottomAlignWithParent()
    }
    
    //MARK: - Table View Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.tableDataArray.count
        case 1:
            return self.paginatingViewCount
        case 2:
            if canShowEmptyScreen && self.tableDataArray.count == 0 {
                return 1
            }
            return 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: OstBaseTableViewCell
        
        switch indexPath.section {
        case 0:
            let deviceTableViewCell = getTableViewCell(tableView, forIndexPath: indexPath) as! OstDeviceTableViewCell
            deviceTableViewCell.setActionButtonText(getActionButtonText())
            if tableDataArray.count > indexPath.row {
                let deviceDetails = tableDataArray[indexPath.row]
                
                deviceTableViewCell.setDeviceDetails(deviceDetails, forIndex: indexPath.row+1)
                deviceTableViewCell.onActionPressed = {[weak self] (deviceDetails) in
                    self?.onCellSelected?(deviceDetails)
                }
            }else {
                deviceTableViewCell.setDeviceDetails(nil, forIndex: indexPath.row+0)
                deviceTableViewCell.onActionPressed = nil
            }
            
            cell = deviceTableViewCell
            
        case 1:
            let pCell: OstPaginationLoaderTableViewCell
            if nil == self.paginatingCell {
                pCell = tableView.dequeueReusableCell(withIdentifier: OstPaginationLoaderTableViewCell.paginationCellIdentifier,
                                                      for: indexPath) as! OstPaginationLoaderTableViewCell
                self.paginatingCell = pCell
            }else {
                pCell = self.paginatingCell!
            }
            
            if isNextPageAvailable() || (self.isNewDataAvailable || self.shouldReloadData) {
                pCell.startAnimating()
            }else {
                pCell.stopAnimating()
            }
            
            cell = pCell
            
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: OstEmptyDLTableViewCell.emptyDLCellIdentifier,
                                                 for: indexPath) as! OstEmptyDLTableViewCell
        default:
            cell = OstBaseTableViewCell()
        }
        
        return cell
    }
    
    func getTableViewCell(_ tableView: UITableView, forIndexPath indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: OstDeviceTableViewCell.deviceCellIdentifier,
                                             for: indexPath) as! OstDeviceTableViewCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            if !isNextPageAvailable() && !self.isNewDataAvailable && !self.shouldReloadData {
                return 0
            }
        }
        
        if (indexPath.section == 2) {
            if canShowEmptyScreen && tableDataArray.count == 0 {
                return tableView.frame.size.height
            }
            return 0
        }
        
        return UITableView.automaticDimension
    }
    
    //MARK: - Scroll View Delegate
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.reloadDataIfNeeded()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.reloadDataIfNeeded()
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if tableDataArray.count > 55 {
            return
        }
        if !self.isNewDataAvailable
            && self.shouldLoadNextPage
            && scrollView.panGestureRecognizer.translation(in: scrollView.superview!).y < 0 {
            
            if (shouldRequestPaginationData(isUpDirection: false,
                                            andTargetPoint: targetContentOffset.pointee.y)) {
                
                self.shouldLoadNextPage = false
                self.getDeviceList()
            }
        }
    }
    
    func shouldRequestPaginationData(isUpDirection: Bool = false,
                                     andTargetPoint targetPoint: CGFloat) -> Bool {
        
        let triggerPoint: CGFloat = CGFloat(self.paginationTriggerPageNumber) * self.deviceTableView.frame.size.height
        if (isUpDirection) {
            return targetPoint <= triggerPoint
        }else {
            return targetPoint >= (self.deviceTableView.contentSize.height - triggerPoint)
        }
    }
    
    //MARK: - Pull to Refresh
    @objc func pullToRefresh(_ sender: Any? = nil) {
        self.getDeviceList(hardRefresh: true)
    }
    
    func reloadDataIfNeeded() {
        
        let isScrolling: Bool = (self.deviceTableView.isDragging) || (self.deviceTableView.isDecelerating)
        
        if !isScrolling && self.isNewDataAvailable {
            tableDataArray = updatedTableArray
            self.deviceTableView.reloadData()
            self.isNewDataAvailable = false
            self.shouldLoadNextPage = true
        }
        
        if !isApiCallInProgress {
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    //MARK: - Get Device
    func getDeviceList(hardRefresh: Bool = false) {
        if isApiCallInProgress {
            reloadDataIfNeeded()
            return
        }
        
        var nextPagePayload: [String: Any]? = nil
        if hardRefresh {
            meta = nil
            updatedTableArray = []
            consumedDevices = [:]
        } else {
            nextPagePayload = getNextPagePayload()
            if nil == nextPagePayload {
                reloadDataIfNeeded()
                self.shouldLoadNextPage = true
                return
            }
        }
        
        isApiCallInProgress = true
        
        OstJsonApi.getDeviceList(forUserId: self.userId!,
                                 params: nextPagePayload,
                                 delegate: self)
    }
    
    func onFetchDeviceSuccess(_ apiResponse: [String: Any]?) {
        canShowEmptyScreen = true
        isApiCallInProgress = false
        
        let currentUser = OstWalletSdk.getUser(self.userId!)
        let currentDevice = currentUser!.getCurrentDevice()
        
        meta = apiResponse?["meta"] as? [String: Any]
        let devices: [[String: Any]]? = OstJsonApi.getResultAsArray(apiData: apiResponse) as? [[String : Any]]
        
        var newDevices: [[String: Any]] = [[String: Any]]()
        for device in devices ?? [] {
            if (device["status"] as? String ?? "").caseInsensitiveCompare("AUTHORIZED") == .orderedSame {
                if let deviceAddress = device["address"] as? String,
                    consumedDevices[deviceAddress] == nil {
                    
                    if currentDevice!.address!.caseInsensitiveCompare(deviceAddress) != .orderedSame {
                        newDevices.append(device)
                        consumedDevices[deviceAddress] = device
                    }
                }
            }
        }
        
        updatedTableArray.append(contentsOf: newDevices)
        
        if updatedTableArray.count < MIN_REQUIRED_DEVICE_LIST && isNextPageAvailable() {
            getDeviceList()
            return
        }
        
        self.isNewDataAvailable = true
        workflowRef?.hideLoader()
        
        reloadDataIfNeeded()
    }
    
    //MARK: - OstJsonApiDelegate
    func onOstJsonApiSuccess(data: [String : Any]?) {
        onFetchDeviceSuccess(data)
    }
    
    func onOstJsonApiError(error: OstError?, errorData: [String : Any]?) {
        onFetchDeviceSuccess(nil)
    }
    
    func isNextPageAvailable() -> Bool {
        return getNextPagePayload() != nil
    }
    
    func getNextPagePayload() -> [String: Any]? {
        guard let nextPagePayload = meta?["next_page_payload"] as? [String: Any] else {
            return nil
        }
        if nextPagePayload.isEmpty {
            return nil
        }
        return nextPagePayload
    }
}
