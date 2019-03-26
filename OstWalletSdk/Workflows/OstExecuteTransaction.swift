/*
 Copyright © 2019 OST.com Inc
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 */

import Foundation
import BigInt

public enum OstExecuteTransactionType: String {
    case DirectTransfer = "Direct Transfer"
    case Pay = "Pricer"
}

class OstExecuteTransaction: OstWorkflowBase {

    private let ABI_METHOD_NAME_DIRECT_TRANSFER = "directTransfers"
    private let ABI_METHOD_NAME_PAY = "pay"
    
    private let OST_DECIMAL_VALUE = 18
    
    typealias ExecuteTransactionPayloadParams =
        (ruleName:String, addresses:[String], amounts:[String], tokenId:String)
    
    /// Rule name
    private static let PAYLOAD_RULE_NAME_KEY = "rn"
    /// Token holder addresses
    private static let PAYLOAD_ADDRESSES_KEY = "ads"
    /// amounts to transfer
    private static let PAYLOAD_AMOUNTS_KEY = "ams"
    /// token id
    private static let PAYLOAD_TOKEN_ID_KEY = "tid"
    // transaction
    private static let META_PAYLOAD_TRANSACTION_NAME_KEY = "tn"
    // transaction type
    private static let META_PAYLOAD_TRANSACTION_TYPE_KEY = "tt"
    // transaction detail
    private static let META_PAYLOAD_TRANSACTION_DETAILS_KEY = "td"
    
    /// Get execute transaction params from qr-code payload
    ///
    /// - Parameter payload: qr-code payload
    /// - Returns: ExecuteTransactionPayloadParams
    /// - Throws: OstError
    class func getExecuteTransactionParamsFromQRPayload(_ payload: [String: Any?]) throws -> ExecuteTransactionPayloadParams {
        
        guard let ruleName: String = payload[OstExecuteTransaction.PAYLOAD_RULE_NAME_KEY] as? String else {
            throw OstError("w_et_getpfqrp_1", .invalidQRCode)
        }
        guard let addresses: [String] = payload[OstExecuteTransaction.PAYLOAD_ADDRESSES_KEY] as? [String] else {
            throw OstError("w_et_getpfqrp_2", .invalidQRCode)
        }
        for address in addresses {
            if !address.isValidAddress {
                throw OstError("w_et_getpfqrp_3", .invalidQRCode)
            }
        }
        guard let amounts: [String] = payload[OstExecuteTransaction.PAYLOAD_AMOUNTS_KEY] as? [String] else {
            throw OstError("w_et_getpfqrp_4", .invalidQRCode)
        }
        guard let tokenId: String = OstUtils.toString(payload[OstExecuteTransaction.PAYLOAD_TOKEN_ID_KEY] as Any?) else {
            throw OstError("w_et_getpfqrp_5", .invalidQRCode)
        }
        
        return (ruleName, addresses, amounts, tokenId)
    }
    
    
    /// Get transaction meta property from QR-Code payload
    ///
    /// - Parameter metaPayload: Meta property payload
    /// - Returns: Dictionary
    class func getTransactionMetaFromFromQRPayload(_ metaPayload: [String: Any?]?) -> [String: String] {
        var transactionMeta: [String: String] = [:]
        if (nil != metaPayload) {
            if let transactionName = metaPayload![OstExecuteTransaction.META_PAYLOAD_TRANSACTION_NAME_KEY] as? String {
                transactionMeta["name"] = transactionName
            }
            if let transactionType = metaPayload![OstExecuteTransaction.META_PAYLOAD_TRANSACTION_TYPE_KEY] as? String {
                transactionMeta["type"] = transactionType
            }
            if let transactionDetails = metaPayload![OstExecuteTransaction.META_PAYLOAD_TRANSACTION_DETAILS_KEY] as? String {
                transactionMeta["details"] = transactionDetails
            }
        }
        
        return transactionMeta
    }
    
    static private let ostExecuteTransactionQueue = DispatchQueue(label: "com.ost.sdk.OstExecuteTransaction", qos: .background)
    private let workflowTransactionCountForPolling = 1
    private let toAddresses: [String]
    private let amounts: [String]
    private let ruleName: String
    private let transactionMeta: [String: String]
    
    private var rule: OstRule? = nil
    private var activeSession: OstSession? = nil
    private var calldata: String? = nil
    private var eip1077Hash: String? = nil
    private var signature: String? = nil
    private var rawCalldata: String? = nil
    private var pricePoint: [String: Any]? = nil
    private var transactionValueInWei: BigInt? = nil
    
    /// Initialize Execute Transaction
    ///
    /// - Parameters:
    ///   - userId: User id.
    ///   - ruleName: Rule name to execute.
    ///   - toAddresses: Address whome to transfer amount.
    ///   - amounts: Amount to transfer.
    ///   - delegate: Callback.
    init(userId: String,
         ruleName: String,
         toAddresses: [String],
         amounts: [String],
         transactionMeta: [String: String],
         delegate: OstWorkflowDelegate) {
        
        self.toAddresses = toAddresses
        self.amounts = amounts
        self.ruleName = ruleName
        self.transactionMeta = transactionMeta
        super.init(userId: userId, delegate: delegate)
    }
    
    /// Get workflow Queue
    ///
    /// - Returns: DispatchQueue
    override func getWorkflowQueue() -> DispatchQueue {
        return OstExecuteTransaction.ostExecuteTransactionQueue
    }
    
    /// validate parameters
    ///
    /// - Throws: OstError
    override func validateParams() throws {
        try super.validateParams()
        try self.workFlowValidator!.isUserActivated()
        try self.workFlowValidator!.isDeviceAuthorized()
        
        let allowedRuleNames = [OstExecuteTransactionType.DirectTransfer.rawValue.uppercased(),
                                OstExecuteTransactionType.Pay.rawValue.uppercased()]
        if (!allowedRuleNames.contains(self.ruleName.uppercased())) {
            throw OstError("w_et_vp_2", OstErrorText.rulesNotFound)
        }
        
        let filteredAddresses = toAddresses.filter({$0 != ""})
        if (amounts.count != filteredAddresses.count) {
            throw OstError("w_et_vp_3", .invalidAddressToTransfer)
        }
    }
    
    /// process
    ///
    /// - Throws: OstError
    override func process() throws {
        self.rule = try getRuleIfPresent()
        if (nil == self.rule) {
            try fetchTokenRules()
            self.rule = try getRuleIfPresent()
            if (nil == self.rule) {
                throw OstError("w_et_p_1", .rulesNotFound)
            }
        }
        
        switch self.ruleName.uppercased() {
        case OstExecuteTransactionType.Pay.rawValue.uppercased():
            try self.processForPricer()
            
        case OstExecuteTransactionType.DirectTransfer.rawValue.uppercased():
            try self.processForDirectTransfer()
            
        default:
            return
        }
    }
    
    /// Get appropriate rule from datatabase
    ///
    /// - Throws: OstError
    private func getRuleIfPresent() throws -> OstRule? {
        if let rules = try OstRule.getByParentId(self.currentUser!.tokenId!) {
            for rule in rules {
                if (self.ruleName.caseInsensitiveCompare(rule.name!) == .orderedSame) {
                    return rule
                }
            }
        }
        return nil
    }
    
    /// Get token rules from server
    private func fetchTokenRules() throws {
        var ostError: OstError? = nil
        let group = DispatchGroup()
        group.enter()
        
        try OstAPIRule(userId: self.userId).getRules(onSuccess: { () in
            group.leave()
        }) { (error) in
            ostError = error
            group.leave()
        }
        group.wait()
        
        if (nil != ostError) {
            throw ostError!
        }
    }
    
    /// Get session addresses from keymanager and fetch session data from db.
    private func getActiveSession() throws -> OstSession? {
        var ostSession: OstSession?  = nil
        let keyManager = OstKeyManager(userId: self.userId)
        let sessionAddresses = try keyManager.getSessions()
        for sessionAddress in sessionAddresses {
            if let session: OstSession = try OstSession.getById(sessionAddress) {
                if (session.approxExpirationTimestamp > Date().timeIntervalSince1970) {
                    let spendingLimit = BigInt(session.spendingLimit ?? "0")
                    if spendingLimit >= self.transactionValueInWei! {
                        ostSession = session
                        break
                    }
                }else {
                    try? keyManager.deleteSessionKey(sessionAddress: sessionAddress)
                }
            }
        }
        return ostSession
    }
    
    /// Generate EIP1077 hash.
    private func createSignatureForTransaction() throws {
        let transaction: OstSession.Transaction = OstSession.Transaction(from: self.currentUser!.tokenHolderAddress!)
        transaction.to = self.rule!.address!
        transaction.data = self.calldata!
        transaction.nonce = OstUtils.toString(self.activeSession!.nonce)!
        transaction.txnCallPrefix = TokenRule.EXECUTE_RULE_CALLPREFIX
        
        self.eip1077Hash = try self.activeSession!.getEIP1077Hash(transaction)
        self.signature = try self.activeSession!.signTransaction(self.eip1077Hash!)
    }
    
    /// Execute transaction.
    private func executeTransaction() {
        do {
            var params: [String: Any] = [:]
            params["to"] = self.rule!.address!
            params["raw_calldata"] = self.rawCalldata!
            params["nonce"] = OstUtils.toString(self.activeSession!.nonce)!
            params["calldata"] = self.calldata!
            params["signer"] = self.activeSession!.address!
            params["signature"] = self.signature!
            params["meta_property"] = self.transactionMeta
            
            try? self.activeSession!.incrementNonce()
            
            try OstAPITransaction(userId: self.userId)
                .executeTransaction(
                    params: params,
                    onSuccess: { (ostTransaction) in
                        self.postRequestAcknowledged(entity: ostTransaction)
                        self.pollingForTransaction(transaction: ostTransaction)
                }) { (error) in
                    self.fetchAllSessions()
                    self.postError(error)
            }
        }catch let error {
            self.fetchSession(error: error as! OstError)
        }
    }
    
    /// Fetch session if transaction failed and retry.
    private func fetchSession(error: OstError) {
        do {
            try OstAPISession(userId: self.userId).getSession(sessionAddress: self.activeSession!.address!, onSuccess: { (ostSession) in
                self.postError(error)
            }) { (ostError) in
                self.postError(error)
            }
        }catch let error {
            self.postError(error)
        }
    }
    
    /// Fetch all sessions from server
    private func fetchAllSessions() {
        let fetchSessionQueue = DispatchQueue.init(label: "com.ost.fetchSessionQueue", qos: .background)
        fetchSessionQueue.async {
            let keyManager = OstKeyManager(userId: self.userId)
            let sessoionAPI = OstAPISession(userId: self.userId)
            if let sessions = try? keyManager.getSessions() {
                for session in sessions {
                    try? sessoionAPI.getSession(sessionAddress: session, onSuccess: nil, onFailure: nil)
                }
            }
        }
    }
    
    /// Polling for checking transaction status
    private func pollingForTransaction(transaction: OstTransaction) {
        let successCallback: ((OstTransaction) -> Void) = { ostSession in
            self.postWorkflowComplete(entity: ostSession)
        }
        
        let failureCallback:  ((OstError) -> Void) = { error in
            self.fetchSession(error: error)            
        }
        // Logger.log(message: "test starting polling for userId: \(self.userId) at \(Date.timestamp())")
        
        OstTransactionPollingService(userId: self.userId,
                                     transaciotnId: transaction.id,
                                     successStatus: OstTransaction.Status.SUCCESS.rawValue,
                                     failureStatus: OstTransaction.Status.FAILED.rawValue,
                                     workflowTransactionCount: self.workflowTransactionCountForPolling,
                                     successCallback: successCallback,
                                     failureCallback: failureCallback).perform()
    }
    
    /// Get current workflow context
    ///
    /// - Returns: OstWorkflowContext
    override func getWorkflowContext() -> OstWorkflowContext {
        return OstWorkflowContext(workflowType: .executeTransaction)
    }
    
    /// Get context entity
    ///
    /// - Returns: OstContextEntity
    override func getContextEntity(for entity: Any) -> OstContextEntity {
        return OstContextEntity(entity: entity, entityType: .transaction)
    }
}

//MARK: - Execute transaction for pay
extension OstExecuteTransaction {
    
    /// process for pricer
    private func processForPricer() throws {
        if (nil == self.pricePoint) {
            try fetchPricePoint()
            if nil == self.pricePoint {
                throw OstError("w_et_pfdt_1", OstErrorText.callDataFormationFailed)
            }
        }
        
        self.transactionValueInWei = try getTransactionValueInWeiForPay()
        
        guard let session = try getActiveSession() else {
            throw OstError("w_et_pfp_2", OstErrorText.sessionNotFound)
        }
        self.activeSession = session
        
        self.calldata = try getCallDataForPricerRule()
        if ( nil == self.calldata) {
            throw OstError("w_et_pfdt_2", OstErrorText.callDataFormationFailed)
        }
        
        try createSignatureForTransaction()
        try createRawCallDataForPay()
        executeTransaction()
    }
    
    /// Fetch price point from server
    ///
    /// - Throws: OstError
    private func fetchPricePoint() throws {
        var err: OstError? = nil
        let group = DispatchGroup()
        group.enter()
        try OstAPIChain(userId: self.userId)
            .getPricePoint(onSuccess: { (pricePointDict) in
                self.pricePoint = pricePointDict
                group.leave()
            }, onFailure: { (ostError) in
                err = ostError
                group.leave()
            })
        group.wait()
        
        if (nil != err) {
            throw err!
        }
    }
    
    /// Get call data for given rule name.
    ///
    /// - Parameter ruleName: rule name to execute transaction.
    /// - Returns: calldata
    /// - Throws: OstError
    private func getCallDataForPricerRule() throws -> String? {
        let currencyPriceInWei = try getPricePointInWei()
        return try PricerRule().getPayExecutableData(abiMethodName: self.ABI_METHOD_NAME_PAY,
                                                     from: self.currentUser!.tokenHolderAddress!,
                                                     toAddresses: self.toAddresses,
                                                     amounts: self.amounts,
                                                     currencyCode: OstConfig.getPricePointCurrencySymbol(),
                                                     currencyPrice: currencyPriceInWei.description
        )
    }
    
    /// Get currency value in Wei
    ///
    /// - Returns: Currency in wei
    /// - Throws: OstError
    private func getPricePointInWei() throws -> BigInt {
        guard let ostDict = self.pricePoint![OstConfig.getPricePointTokenSymbol()] as? [String: Any] else {
            throw OstError("w_et_gcviw_1", OstErrorText.pricePointNotFound)
        }
        
        let fiatValInString = String(format: "%@", ostDict[OstConfig.getPricePointCurrencySymbol()] as! CVarArg)
        let components = try OstConversion.getNumberComponents(fiatValInString)
        
        guard let decimal = OstUtils.toInt(ostDict["decimals"] as Any) else {
            throw OstError("w_et_gcviw_2", OstErrorText.callDataFormationFailed)
        }
        
        let finalExponentComponent = decimal + components.exponent
        let currencyPriceInWei = components.number * BigInt(10).power(finalExponentComponent)
    
        return currencyPriceInWei
    }
    
    /// Get Transaction spending amount.
    ///
    /// - Returns: BigInt of transaction spending amount
    /// - Throws: OstError
    func getTransactionValueInWeiForPay() throws -> BigInt {
        var totalAmount: BigInt = BigInt("0")
        
        guard let token = try OstToken.getById(self.currentUser!.tokenId!) else {
            throw OstError("w_et_gtviwfp_1", OstErrorText.invalidAmount)
        }
        guard let ostToBtConversionFactor = token.conversionFactor else {
            throw OstError("w_et_gtviwfp_2", OstErrorText.conversionFactorNotFound)
        }
        guard let btDecimal = token.decimals else {
            throw OstError("w_et_gtviwfp_2", OstErrorText.btDecimalNotFound)
        }
        guard let ostDict = self.pricePoint![OstConfig.getPricePointTokenSymbol()] as? [String: Any] else {
            throw OstError("w_et_gcviw_1", OstErrorText.pricePointNotFound)
        }
        
        let fiatValInString = String(format: "%@", ostDict[OstConfig.getPricePointCurrencySymbol()] as! CVarArg)
        
        for amount in self.amounts {
            let btAmount = try OstConversion.fiatToBt(ostToBtConversionFactor: ostToBtConversionFactor,
                                                      btDecimal: btDecimal,
                                                      ostDecimal: self.OST_DECIMAL_VALUE,
                                                      fiatAmount: BigInt(amount)!,
                                                      pricePoint: fiatValInString)    
            totalAmount += btAmount
        }
        return totalAmount
    }
    
    
    /// Create raw call data for pay
    ///
    /// - Throws: OstError
    private func createRawCallDataForPay() throws {
        let currencyPriceInWei = try getPricePointInWei()
        let rawCalldata: [String: Any] = ["method": self.ABI_METHOD_NAME_PAY,
                                          "parameters": [self.currentUser!.tokenHolderAddress!,
                                                         self.toAddresses,
                                                         self.amounts,
                                                         OstConfig.getPricePointCurrencySymbol(),
                                                         currencyPriceInWei.description]]
        self.rawCalldata = try OstUtils.toJSONString(rawCalldata)
    }
}

//MARK: - Execute transaction for direct transfer
extension OstExecuteTransaction {
    
    /// process for direct transfer
    private func processForDirectTransfer() throws  {
        self.transactionValueInWei = try getTransactionValueForDirectTransfer()
        
        guard let session = try getActiveSession() else {
            throw OstError("w_et_pfdt_1", OstErrorText.sessionNotFound)
        }
        self.activeSession = session
        
        self.calldata = try getCallDataForDirectTransfer()
        if ( nil == self.calldata) {
            throw OstError("w_et_pfdt_1", OstErrorText.callDataFormationFailed)
        }
        
        try createSignatureForTransaction()
        try createRawCallDataForDirectTransfer()
        executeTransaction()
    }
    
    /// Get call data for given rule name.
    ///
    /// - Parameter ruleName: rule name to execute transaction.
    /// - Returns: calldata
    /// - Throws: OstError
    private func getCallDataForDirectTransfer() throws -> String? {
        return try TokenRule().getDirectTransfersExecutableData(abiMethodName: self.ABI_METHOD_NAME_DIRECT_TRANSFER,
                                                                tokenHolderAddresses: self.toAddresses,
                                                                amounts: self.amounts)
    }
    
    /// Create raw call data for direct transfer
    ///
    /// - Throws: OstError
    private func createRawCallDataForDirectTransfer() throws {
        let rawCalldata: [String: Any] = ["method": self.ABI_METHOD_NAME_DIRECT_TRANSFER,
                                          "parameters": [self.toAddresses, self.amounts]]
        self.rawCalldata = try OstUtils.toJSONString(rawCalldata)
    }
    
    /// Get total spending limit of transaction
    ///
    /// - Returns: BigInt of total transaciton amount
    /// - Throws: OstError
    private func getTransactionValueForDirectTransfer() throws -> BigInt {
        var totalAmount: BigInt = BigInt("0")
        for amount in self.amounts {
            guard let amountInBigInt = BigInt(amount) else {
                throw OstError("w_et_gtsl_1", OstErrorText.invalidAmount)
            }
            totalAmount += amountInBigInt
        }
        return totalAmount
    }
    
}
