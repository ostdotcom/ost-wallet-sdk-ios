/*
 Copyright © 2019 OST.com Inc
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 */

import Foundation

public class OstError: Error {
    
    public internal(set) var isApiError = false
    
    public let internalCode:String
    public let errorMessage:String
    public let messageTextCode:OstErrorText;
    
    public var description: String {
        return errorMessage
    }
    public var errorInfo: [String: Any]? = nil

    init(_ code: String, _ messageTextCode: OstErrorText) {
        self.internalCode = code
        self.errorMessage = messageTextCode.rawValue
        self.messageTextCode = messageTextCode;
    }
    
    //@available(*, deprecated, message: "Please use OstError(code:String, messageTextCode:OstErrorText)")
    init(_ code: String, _ errorMessage: String) {
        self.internalCode = code
        self.errorMessage = errorMessage
        self.messageTextCode = .tempMessageTextCode
    }
    
    init(fromApiResponse response: [String: Any]) {
        let err = response["err"] as! [String: Any]
        self.internalCode = err["code"] as! String
        self.errorMessage = err["msg"] as! String
        self.messageTextCode = OstErrorText.apiResponseError;
        errorInfo = response
    }
}

public enum OstErrorText: String {
    case userNotFound = "user not found."
    case invalidUser = "user is invalid."
    case userAlreadyActivated = "user is activated."
    case userNotActivated = "User is not activated."
    case userNotActivating = "User is not activating"
    case deviceNotset = "Device is not setup. Please Setup device first. call OstWalletSdk.setupDevice"
    case deviceNotAuthorized = "Device is not authorized."
    case deviceAuthorized = "Device is already authorized."
    case deviceNotRecovering = "Device is not in recovering mode."
    case deviceNotRevoking = "Device is not revoking."
    case deviceAlreadyAuthorized = "Device is authorized."
    case deviceNotAuthorizing = "Device is not authorizing."
    case wrongDeviceAddress = "Wrong device address."
    case processSameDevice = "Trying to process same device."
    case differentOwnerDevice = "Device does not belongs to you."
    case accessControlFailed = "Unable to create access control object."
    case unableToGetPublicKey = "Unable to get public key."
    case encryptFail = "Error while encrypting data with public key."
    case decryptFail = "Error while decrypting data with private key."
    case keychainDeleteItemFail = "Error while deleting item from keychain."
    case keychainAddItemFail = "Error while adding item in keychain."
    case generatePrivateKeyFail = "Error while generating private key."
    case noPrivateKeyFound = "Private key not found."
    case mnemonicsNotStored = "Failed to store mnemonics."
    case mnemonicsNotFound = "Mnemonics not found."
    case scryptKeyGenerationFailed = "Failed to generate SCrypt key."
    case seedCreationFailed = "Failed to create seed from mnemonics."
    case walletGenerationFailed = "Failed to create wallet from seed."
    case signTxFailed = "Failed to sign transaction with private key."
    case signatureFailed = "Failed to sign message with private key."
    case apiAddressNotFound = "API address not found."
    case apiEndpointNotFound = "API endpoint not found."
    case userEntityNotFound = "User not found."
    case entityNotAvailable = "Entity not available."
    case unknownEntity = "Unknown entity."
    case invalidAPIResponse = "Invalid API response."
    case unableToGetSalt = "Unable to get salt."
    case unableToChainInformation = "Unable to get chain information."
    case deviceNotRegistered = "Device is not registered."
    case deviceAlreadyRegistered = "Device is registered."
    case deviceManagerNotFound = "Device manager is not persent."
    case userActivationFailed = "Activation of user failed."
    case deviceNotFound = "Device not found."
    case invalidPayload = "Invalid paylaod to process."
    case paperWalletNotFound = "Paper wallet not found."
    case invalidDataDefination = "Invalid data defination"
    case recoveryAddressNotFound = "Recovery address for user is not set."
    case recoveryOwnerAddressNotFound = "Recovery owner address for user is not set."
    case recoveryOwnerAddressCreationFailed = "Recovery owner address creation failed."
    case linkedAddressNotFound = "Linked address for user is not set."
    case invalidRecoveryAddress = "Invalid recovery address."
    case invalidUserId = "Invalid user id."
    case invalidTokenId = "Invalid token id."
    case tokenNotFound = "Token not found."
    case signatureGenerationFailed = "Signature generation failed."
    case unexpectedError = "Unexpected error."
    case abiEncodeFailed = "ABI encoding failed."
    case qrReadFailed = "Can not read data from given image."
    case qrCodeGenerationFailed = "QR-Code generation failed."
    case qrCodeImageGenerationFailed = "QR-Code image generation failed."
    case functionNotFoundInABI = "Generating ABI encodable values failed."
    case failedWithMaxRetryCount = "Failed after maximum retry count."
    case invalidSolidityTypeInt = "Invalid solidity type, expected Int or Uint."
    case invalidSolidityTypeAddress = "Invalid solidity type address."
    case invalidJsonObjectIdentifier = "JsonObject doesn't have desired identifier"
    case jsonConversionFailed = "JSON conversion to object failed."
    case addDeviceFlowCancelled = "Add device flow cancelled."
    case objectCreationFailed = "Object creation failed."
    case invalidId = "Invalid id."
    case unexpectedState = "Unexpected state."
    case toAddressNotFound = "To address not found."
    case signerAddressNotFound = "Signer address not found."
    case dbExecutionFailed = "DB execution failed."
    case invalidEntityType = "Invalid entity type."
    case invalidQRCode = "Invalid QR Code"
    case invalidRuleName = "Invalid Rule name"
    case invalidAddressToTransfer = "Invalid address to transfer value."
    case sessionNotAuthorizing = "Session is not authorizing."
    case maxUserValidatedCountReached = "Exceeded pin retry limit."
    case recoveryPinNotFoundInKeyManager = "recovery pin not found in key manager."
    case rulesNotFound = "Rules not found."
    case invalidAmount = "Amount to do transaction is invalid."
    case sessionNotFound = "Session not found."
    case callDataFormationFailed = "Calldata formation failed."
    case transactionFailed = "Transaction failed."
    case resetPinFailed = "Reset pin failed."
    case failedFetchRecoveryOwnerAddress = "Failed to get recovery owner address."
    case pricePointNotFound = "Price point not found."
    case invalidPricePoint = "Invalid price point."
    case invalidNumber = "Invalid number"
    case invalidExpirationTimeStamp = "Invalid expiration timestamp"
    case requestTimedOut = "Request timed out"
    case failedToProcess = "Entity failed to process"
    case samePin = "Old and new pin both are same"
    case conversionFactorNotFound = "Conversion factor not present"
    case btDecimalNotFound = "Decimal value not found"
    case keyNotFound = "Key not found"
    case failedToReadOstSdkPlist = "Failed to read configurations from OstWalletSdk.plist"
    
    //API-Errors
    case invalidApiEndPoint = "Invalid Api Endpoint"
    case apiSignatureGenerationFailed = "Api Signature generation failed."
    case sessionApiFailed = "Failed to fetch session information."
    case pinValidationFailed = "Pin entered are same or wrong."
    case invalidMnemonics = "Incorrect mnemonics."

    //Generic errors.
    case sdkError = "An internal SDK error has occoured."
    case apiResponseError = "Api responsed with error. Please see error info."
    case tempMessageTextCode = "Something went wrong."
    case userCanceled = "User canceled"
}