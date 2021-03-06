/*
 Copyright © 2019 OST.com Inc
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 */

import Foundation
import LocalAuthentication
import CryptoSwift
import EthereumKit

let SERVICE_NAME = "com.ost"
let ETHEREUM_KEY_PREFIX = "Ethereum_key_for_"
let MNEMONICS_KEY_PREFIX = "Mnemonics_for_"
let SESSION_KEY_PREFIX = "Session_key_for_"
let SECURE_ENCLAVE_KEY_PREFIX = "secure_enclave_identifier_"
let USER_DEVICE_KEY_PREFIX = "user_device_info_for_"
let ETH_META_MAPPING_KEY = "EthKeyMetaMapping"
let MNEMONICS_META_MAPPING_KEY = "EthKeyMnemonicsMetaMapping"
let SESSION_META_MAPPING_KEY = "SessionKeyMetaMapping"
let API_ADDRESS_KEY = "api_address"
let DEVICE_ADDRESS_KEY = "device_address"
let RECOVERY_PIN_HASH = "recovery_pin_hash"
let BIOMETRIC_PREFERENCE = "biometric_preference"

struct EthMetaMapping {
    /// Ethererum address
    var address: String
    
    /// Entity id to look up the private key of the ethereum address in keychain
    var entityId: String
    
    /// Secure enclave reference key
    var identifier: String
    
    /// Boolean to indicate if secure enclave is used to encrypt the data
    var isSecureEnclaveEncrypted: Bool

    /// Initializer for EthMetaMapping.
    ///
    /// - Parameters:
    ///   - address: Ethereum key
    ///   - entityId: Keychain item identifier
    ///   - identifier: Secure enclave key identifier
    ///   - isSecureEnclaveEncrypted: A boolean to indicate if secure enclave encrption is used for storing data
    init(address: String, entityId: String, identifier: String = "", isSecureEnclaveEncrypted: Bool = false) {
        self.address = address
        self.entityId = entityId
        self.identifier = identifier
        self.isSecureEnclaveEncrypted = isSecureEnclaveEncrypted
    }
    
    /// Converts the EthMetaMapping data in to dictionary format
    ///
    /// - Returns: [String: Any] dictionary
    func toDictionary() -> [String: Any] {
        let dict: [String : Any] = ["entityId": self.entityId,
                                    "address": self.address,
                                    "identifier": self.identifier,
                                    "isSecureEnclaveEncrypted": self.isSecureEnclaveEncrypted]
        return dict
    }
    
    /// Get EthMetaMapping object from Dictionary
    ///
    /// - Parameter dictionary: Dictionary containing eth meta mapping values
    /// - Returns: EthMetaMapping object
    static func getEthMetaMapping(from dictionary:[String: Any]) -> EthMetaMapping {
        let ethMetaMappingObj = EthMetaMapping(
            address: dictionary["address"] as! String,
            entityId: dictionary["entityId"] as! String,
            identifier: dictionary["identifier"] as! String,
            isSecureEnclaveEncrypted: dictionary["isSecureEnclaveEncrypted"] as! Bool
        );
        return ethMetaMappingObj
    }
}

/// Class for managing the ethereum keys.
private class OstInternalKeyManager : OstKeyManagerDelegate {
    let PRIVATE_KEY_LENGTH = 64
    
//    typealias SignedData = (address: String, signature: String)
    
    // MARK: - Instance varaibles
    
    /// Helper object to interact with keychain
    private var keychainHelper: OstKeychainHelper
    
    /// Current user id
    private var userId: String
    
    /// Secure enclave identifier key
    private var secureEnclaveIdentifier: String
    
    /// Current user's device info
    private var currentUserDeviceInfo: [String: Any]? = nil
    
    // MARK: - Initializers
    
    /// Class initializer
    ///
    /// - Parameter userId: User id whose keys will be managed.
    init (userId: String) {
        self.userId = userId
        self.keychainHelper = OstKeychainHelper(service: SERVICE_NAME)
        self.secureEnclaveIdentifier = OstInternalKeyManager.getSecureEnclaveKey(forUserId: userId)
    }
    
    /// Clear user device ifor
    ///
    /// - Throws: OstError
    func clearUserDeviceInfo() throws {
        try setUserDeviceInfo(deviceInfo: [ : ])
    }
    
    //MARK: - API key

    /// Function to create API address and key.
    /// The address and key are stored securely in the keychain.
    ///
    /// - Returns: API address
    /// - Throws: Exceptions that occurs while creating and storing the keys
    func createAPIKey() throws -> String {
        let ethKeys: OstWalletKeys = try OstCryptoImpls()
            .generateOstWalletKeys(userId: self.userId,
                                   forKeyType: .api)
        
        if (ethKeys.privateKey == nil || ethKeys.address == nil) {
            throw OstError("s_i_km_cak_1", .generatePrivateKeyFail)
        }
        try storeEthereumKey(ethKeys.privateKey!, forAddress: ethKeys.address!)
        try storeAPIAddress(ethKeys.address!)
        return ethKeys.address!
    }
    
    /// Store the API address in keychain
    ///
    /// - Parameter address: Ethereum address that needs to be stored
    /// - Throws: Exceptions that occurs while storing the address
    private func storeAPIAddress(_ address: String) throws {
        var userDeviceInfo: [String: Any] = getUserDeviceInfo()
        userDeviceInfo[API_ADDRESS_KEY] = address
        try setUserDeviceInfo(deviceInfo: userDeviceInfo)
    }
    
    /// Get the current users API address
    ///
    /// - Returns: API address
    func getAPIAddress() -> String? {
        let userDeviceInfo: [String: Any] = getUserDeviceInfo()
        return userDeviceInfo[API_ADDRESS_KEY] as? String
    }
    
    /// Get the private key for the API address
    ///
    /// - Returns: Private key for the API address if available otherwise nil
    /// - Throws: Exception that occurs while getting the private key
    private func getAPIKey() throws -> String? {
        if let apiAddress = getAPIAddress() {
            return try getEthereumKey(forAddresss: apiAddress)
        }
        return nil
    }
    
    //MAKR: - Biometric Preference
    
    /// Get Biometric preference for user.
    ///
    /// - Returns: true if BiometricEnabled, default false
    func isBiometricEnabled() -> Bool {
        let userDeviceInfo: [String: Any] = getUserDeviceInfo()
        return userDeviceInfo[BIOMETRIC_PREFERENCE] as? Bool ?? false
    }
    
    /// Set Biometric preference for user.
    ///
    /// - Parameter preference: Biometric preference
    /// - Throws: OstError
    func setBiometricPreference(_ preference: Bool) throws {
        var userDeviceInfo: [String: Any] = getUserDeviceInfo()
        userDeviceInfo[BIOMETRIC_PREFERENCE] = preference
        try setUserDeviceInfo(deviceInfo: userDeviceInfo)
    }
    
    //MARK: - Device Key
    
    /// Create the device private key and address.
    /// This also stores the private key and address securly in the keychain
    ///
    /// - Returns: Device address
    /// - Throws: Exceptions that occurs while storing the address or key in the keychain
    func createDeviceKey() throws -> String {
        let ethKeys: OstWalletKeys = try OstCryptoImpls()
            .generateOstWalletKeys(userId: self.userId,
                                   forKeyType: .device)
        
        if (ethKeys.privateKey == nil || ethKeys.address == nil) {
            throw OstError("s_i_km_cdk_1", .generatePrivateKeyFail)
        }
        try storeMnemonics(ethKeys.mnemonics!, forAddress: ethKeys.address!)
        try storeEthereumKey(ethKeys.privateKey!, forAddress: ethKeys.address!)
        try storeDeviceAddress(ethKeys.address!)
        return ethKeys.address!
    }
    
    /// Store the device address in the keychain
    ///
    /// - Parameter address: Device address
    /// - Throws: Exception that occurs while storing the device address in keychain
    private func storeDeviceAddress(_ address: String) throws {
        var userDeviceInfo: [String: Any] = getUserDeviceInfo()
        userDeviceInfo[DEVICE_ADDRESS_KEY] = address
        try setUserDeviceInfo(deviceInfo: userDeviceInfo)
    }
    
    /// Get current user's stored device address from keychain
    ///
    /// - Returns: Device address if available otherwise nil
    func getDeviceAddress() -> String? {
        let userDeviceInfo: [String: Any] = getUserDeviceInfo()
        return userDeviceInfo[DEVICE_ADDRESS_KEY] as? String
    }
    
    /// Get private key of current user's stored device address
    ///
    /// - Returns: Private key for device address if available otherwise nil
    /// - Throws: Exception that accurs while getting the private key from keychain
    private func getDeviceKey() throws -> String? {
        if let deviceAddress = getDeviceAddress() {
            return try getEthereumKey(forAddresss: deviceAddress)
        }
        return nil
    }
    
    /// Get the 12 words mnemonic keys for the current user's device address
    ///
    /// - Returns: JSON serialized 12 words mnemonics key
    /// - Throws: Exception that occurs while getting the keys from keychain
    func getDeviceMnemonics() throws -> [String]? {
        if let deviceAddress = getDeviceAddress() {
            if let ethMetaMapping: EthMetaMapping =  getMnemonicsMetaMapping(forAddress: deviceAddress) {
                if let jsonString: String = try getString(from: ethMetaMapping) {
                    return try OstUtils.toJSONObject(jsonString) as? [String]
                }
            }
        }
        return nil
    }
    
    //MARK: - Session Key
    
    /// Create the session private key and address.
    /// This also stores the private key and address securly in the keychain
    ///
    /// - Returns: Device address
    /// - Throws: Exceptions that occurs while storing the address or key in the keychain
    func createSessionKey() throws -> String {
        let ethKeys: OstWalletKeys = try OstCryptoImpls()
            .generateOstWalletKeys(userId: self.userId,
                                   forKeyType: .session)
        
        if (ethKeys.privateKey == nil || ethKeys.address == nil) {
            throw OstError("s_i_km_csk_1", .generatePrivateKeyFail)
        }
        try storeSessionKey(ethKeys.privateKey!, forAddress: ethKeys.address!)
        return ethKeys.address!
    }
    
    /// Delete all sessions for user
    func deleteAllSessions() {
        if let sessionAddresses: [String] = try? getSessions() {
            for sessionAddress in sessionAddresses {
                try? deleteSessionKey(sessionAddress: sessionAddress)
            }
        }
    }
    
    /// Get all the session addresses available in the device
    ///
    /// - Returns: Array containing session addresses
    /// - Throws: OstError
    func getSessions() throws -> [String] {
        return getAllAddresses(ForKey: SESSION_META_MAPPING_KEY)
    }

    /// Delete session address and its key
    ///
    /// - Parameter sessionAddress: Session address
    /// - Throws: OstError
    func deleteSessionKey(sessionAddress: String) throws {
        try deleteMetaMapping(forAddress: sessionAddress, forKey: SESSION_META_MAPPING_KEY)
    }

    //MARK: - Recovery
    
    /// Get recovery owner address
    ///
    /// - Parameters:
    ///   - passphrasePrefix: Passphrase prefix
    ///   - userPin: User pin
    ///   - salt: Salt used to create recovery owner address
    /// - Returns: Recovery owner address
    /// - Throws: OstError
    func getRecoveryOwnerAddressFrom(
        passphrasePrefix: String,
        userPin: String,
        salt: String) throws -> String {
        
        let recoveryOwnerAddress = try OstCryptoImpls()
            .generateRecoveryKey(
            passphrasePrefix: passphrasePrefix,
            userPin: userPin,
            userId: self.userId,
            salt: salt,
            n: OstConstants.OST_RECOVERY_PIN_SCRYPT_N,
            r: OstConstants.OST_RECOVERY_PIN_SCRYPT_R,
            p: OstConstants.OST_RECOVERY_PIN_SCRYPT_P,
            size: OstConstants.OST_RECOVERY_PIN_SCRYPT_DESIRED_SIZE_BYTES
        )
        
        return recoveryOwnerAddress
    }


    /// Verify pin. This will first check the pin hash, if it does not match
    /// then it will generate the recovery owner address and match it.
    ///
    /// - Parameters:
    ///   - passphrasePrefix: Application Passphrase prefix
    ///   - userPin: User pin
    ///   - salt: Salt
    ///   - recoveryOwnerAddress: Recovery owner address
    /// - Returns: `true` if verified otherwise `false`
    func verifyPin(
        passphrasePrefix: String,
        userPin: String,
        salt: String,
        recoveryOwnerAddress: String) -> Bool {
    
        var isValid = self.validatePinHash(
            passphrasePrefix: passphrasePrefix,
            userPin: userPin,
            salt: salt,
            recoveryOwnerAddress: recoveryOwnerAddress
        )

        if !isValid {
            do {
                let generatedAddress = try self.getRecoveryOwnerAddressFrom(
                    passphrasePrefix: passphrasePrefix,
                    userPin: userPin,
                    salt: salt
                )
                
                isValid = recoveryOwnerAddress.caseInsensitiveCompare(generatedAddress) ==  .orderedSame
                
                // Store the pin hash in the keychain, so that the next validation will be faster
                if isValid {
                    try? self.storePinHash(
                        passphrasePrefix: passphrasePrefix,
                        userPin: userPin,
                        salt: salt,
                        recoveryOwnerAddress: recoveryOwnerAddress
                    )
                }
                
            } catch {
                isValid = false
            }
        }

        return isValid
    }
    
    /// Delete stored pin hash
    ///
    /// - Throws: OstError
    func deletePinHash() throws {
        var userDeviceInfo: [String: Any] = getUserDeviceInfo()
        userDeviceInfo[RECOVERY_PIN_HASH] = nil
        try setUserDeviceInfo(deviceInfo: userDeviceInfo)
    }
    
}

// MARK: - Pin hash related functions
private extension OstInternalKeyManager {

    /// Generate pin hash from given parameters
    ///
    /// - Parameters:
    ///   - passphrasePrefix: Application Passphrase prefix
    ///   - userPin: User pin
    ///   - salt: Salt
    ///   - recoveryOwnerAddress: Recovery owner address
    /// - Returns: Pin hash
    func generatePinHash(
        passphrasePrefix: String,
        userPin: String,
        salt: String,
        recoveryOwnerAddress: String) -> String {
        
        let rawString = "\(self.userId)\(passphrasePrefix)\(userPin)\(salt)\(recoveryOwnerAddress.lowercased())"
        let pinHash = rawString.sha3(.keccak256)
        return pinHash
    }
    
    /// Store pin hash
    ///
    /// - Parameter pinHash: Pin hash
    /// - Throws: OstError
    func storePinHash(_ pinHash: String) throws {
        var pinHashData: Data? = nil
        if #available(iOS 10.3, *) {
            if Device.hasSecureEnclave {
                let enclaveHelperObj = OstSecureEnclaveHelper(tag: self.secureEnclaveIdentifier)
                if let privateKey: SecKey = try enclaveHelperObj.getPrivateKey() {
                    pinHashData = try enclaveHelperObj.encrypt(data: pinHash.data(using: .utf8)!, withPrivateKey: privateKey)
                }
            }
        }
        if (pinHashData == nil) {
            pinHashData = OstUtils.toEncodedData(pinHash)
        }
        
        var userDeviceInfo: [String: Any] = getUserDeviceInfo()
        userDeviceInfo[RECOVERY_PIN_HASH] = pinHashData
        try setUserDeviceInfo(deviceInfo: userDeviceInfo)
    }
    
    /// Generate the pin hash from given parameters and store them in the keychain
    ///
    /// - Parameters:
    ///   - passphrasePrefix: Application Passphrase prefix
    ///   - userPin: User pin
    ///   - salt: Salt
    ///   - recoveryOwnerAddress: Recovery owner address
    /// - Throws: OstError
    func storePinHash(
        passphrasePrefix: String,
        userPin: String,
        salt: String,
        recoveryOwnerAddress: String) throws{
        
        let generatedPinHash = self.generatePinHash(
            passphrasePrefix: passphrasePrefix,
            userPin: userPin,
            salt: salt,
            recoveryOwnerAddress: recoveryOwnerAddress
        )
        
        try self.storePinHash(generatedPinHash)
    }
    
    /// Get stored pin hash
    ///
    /// - Returns: Pin hash
    /// - Throws: OstError
    func getPinHash() throws -> String {
        let userDeviceInfo: [String: Any] = getUserDeviceInfo()
        guard let pinData = userDeviceInfo[RECOVERY_PIN_HASH] as? Data else {
            throw OstError("o_s_i_km_gph_1", .recoveryPinNotFoundInKeyManager)
        }
        if Device.hasSecureEnclave {
            if #available(iOS 10.3, *) {
                let enclaveHelperObj = OstSecureEnclaveHelper(tag: self.secureEnclaveIdentifier)
                if let privateKey: SecKey = enclaveHelperObj.getPrivateKeyFromKeychain() {
                    let dData = try enclaveHelperObj.decrypt(data: pinData, withPrivateKey: privateKey)
                    let pinHash: String = String(data: dData, encoding: .utf8)!
                    return pinHash
                }
                throw OstError("s_i_km_gph_1", .noPrivateKeyFound)
            }
        }else {
            return OstUtils.toDecodedValue(pinData) as! String
        }
        throw OstError("o_s_i_km_gph_2", .recoveryPinNotFoundInKeyManager)
    }
    
    /// Validate pin hash
    ///
    /// - Parameters:
    ///   - passphrasePrefix: Application Passphrase prefix
    ///   - userPin: User pin
    ///   - salt: Salt
    ///   - recoveryOwnerAddress: Recovery owner address
    /// - Returns: `true` if valid otherwise `false`
    func validatePinHash(
        passphrasePrefix: String,
        userPin: String,
        salt: String,
        recoveryOwnerAddress: String) -> Bool {
        
        var isValid = true;
        let generatedPinHash = self.generatePinHash(
            passphrasePrefix: passphrasePrefix,
            userPin: userPin,
            salt: salt,
            recoveryOwnerAddress: recoveryOwnerAddress
        )
        
        do {
            let storedPinHash = try self.getPinHash()
            isValid = generatedPinHash.elementsEqual(storedPinHash)
        } catch {
            isValid = false
        }
        return isValid
    }
    
}

// MARK: - MetaMapping getters and setters
private extension OstInternalKeyManager {
    /// Set the eth meta mapping in the keychain
    ///
    /// - Parameter ethMetaMapping: EthMetaMapping object that needs to be stored in keychain
    /// - Throws: Exception that occurs while setting the data in keychain
    func setEthKeyMetaMapping(_ ethMetaMapping: EthMetaMapping) throws {
        try setMetaMapping(ethMetaMapping, forKey: ETH_META_MAPPING_KEY)
    }
    
    /// Get the eth meta mapping object from the keychain
    ///
    /// - Parameter address: Ethereum address to lookup the EthMetaMapping object
    /// - Returns: EthMetaMapping object
    func getEthKeyMetaMapping(forAddress address: String) -> EthMetaMapping?  {
        return getMetaMapping(forAddress: address, andKey: ETH_META_MAPPING_KEY)
    }
    
    /// Set mnemonics meta mapping in the keychain
    ///
    /// - Parameter ethMetaMapping: EthMetaMapping object that needs to be stored in keychain
    /// - Throws: Exception that occurs while setting the data in keychain
    func setMnemonicsMetaMapping(_ ethMetaMapping: EthMetaMapping) throws {
        try setMetaMapping(ethMetaMapping, forKey: MNEMONICS_META_MAPPING_KEY)
    }
    
    /// Get the mnemonic meta mapping object from the keychain
    ///
    /// - Parameter address: Ethereum address to lookup the EthMetaMapping object
    /// - Returns: EthMetaMapping object
    func getMnemonicsMetaMapping(forAddress address: String) -> EthMetaMapping?  {
        return getMetaMapping(forAddress: address, andKey: MNEMONICS_META_MAPPING_KEY)
    }
    
    /// Set the session meta mapping in the keychain
    ///
    /// - Parameter ethMetaMapping: EthMetaMapping object that needs to be stored in keychain
    /// - Throws: Exception that occurs while setting the data in keychain
    func setSessionKeyMetaMapping(_ ethMetaMapping: EthMetaMapping) throws {
        try setMetaMapping(ethMetaMapping, forKey: SESSION_META_MAPPING_KEY)
    }
    
    /// Get the session meta mapping object from the keychain
    ///
    /// - Parameter address: Ethereum address to lookup the EthMetaMapping object
    /// - Returns: EthMetaMapping object
    func getSessionKeyMetaMapping(forAddress address: String) -> EthMetaMapping?  {
        return getMetaMapping(forAddress: address, andKey: SESSION_META_MAPPING_KEY)
    }
}

// MARK: - Lookup storage keys
private extension OstInternalKeyManager {
    /// Get the storage key for user device info
    ///
    /// - Parameter userId: User id for key formation
    /// - Returns: Storage key for user device info
    static func getUserDeviceInfoStorageKey(forUserId userId:String) -> String {
        return "\(USER_DEVICE_KEY_PREFIX)\(userId)"
    }
    
    /// Get ethereum address storage key
    ///
    /// - Parameter address: Ethereum address for key formation
    /// - Returns: Storage key for ethereum address lookup
    static func getAddressStorageKey(forAddress address: String) -> String {
        return "\(ETHEREUM_KEY_PREFIX)\(address.lowercased())"
    }
    
    /// Get the storage key for mnemonics lookup
    ///
    /// - Parameter address: Ethereum address for key formation
    /// - Returns: Storage key for mnemonics lookup
    static func getMnemonicsStorageKey(forAddress address: String) -> String {
        return "\(MNEMONICS_KEY_PREFIX)\(address.lowercased())"
    }
    
    /// Get the storage key for session lookup
    ///
    /// - Parameter address: Ethereum address for key formation
    /// - Returns: Storage key for mnemonics lookup
    static func getSessionStorageKey(forAddress address: String) -> String {
        return "\(SESSION_KEY_PREFIX)\(address.lowercased())"
    }
    
    /// Get the key for secure enclave lookup
    ///
    /// - Parameter userId: User id for key formation
    /// - Returns: Key for secure enclave
    static func getSecureEnclaveKey(forUserId userId: String) -> String {
        return "\(SECURE_ENCLAVE_KEY_PREFIX)\(userId.lowercased())"
    }
    
    /// Get the storage key for current user device info
    ///
    /// - Returns: Storage key for user device info
    func getCurrentUserDeviceInfoStorageKey() -> String {
        return OstInternalKeyManager.getUserDeviceInfoStorageKey(forUserId: self.userId);
    }
}

// MARK: - Private functions
private extension OstInternalKeyManager {
    /// Get the user device info for the current user
    ///
    /// - Returns: User device info dictionary
    func getUserDeviceInfo() -> [String: Any] {
        if (currentUserDeviceInfo != nil) {
            return currentUserDeviceInfo!
        }
        if let userDevice: Data = keychainHelper.getDataFromKeychain(forKey: getCurrentUserDeviceInfoStorageKey()) {
            currentUserDeviceInfo = userDevice.toDictionary()
            return currentUserDeviceInfo!
        }
        return [:]
    }
    
    /// Set user device info for the current user
    ///
    /// - Parameter deviceInfo: Device info dictionary object
    /// - Throws: OSTError
    func setUserDeviceInfo(deviceInfo: [String: Any]) throws {
        currentUserDeviceInfo = deviceInfo
        let deviceInfoData = OstUtils.toEncodedData(deviceInfo)
        try keychainHelper.setDataInKeychain(data: deviceInfoData, forKey: getCurrentUserDeviceInfoStorageKey())
    }
    
    /// Set meta mapping in the keychain
    ///
    /// - Parameters:
    ///   - ethMetaMapping: EthMetaMapping object
    ///   - key: Storage key
    /// - Throws: OSTError
    func setMetaMapping(_ ethMetaMapping: EthMetaMapping, forKey key: String) throws {
        let address: String = ethMetaMapping.address.lowercased()
        var userDeviceInfo: [String: Any] = getUserDeviceInfo()
        var ethKeyMappingData: [String: [String: Any]] = userDeviceInfo[key] as? [String: [String: Any]] ?? [:]
        ethKeyMappingData[address] = ethMetaMapping.toDictionary()
        userDeviceInfo[key] = ethKeyMappingData
        try setUserDeviceInfo(deviceInfo: userDeviceInfo)
    }
    
    /// Get meta mapping for the given address and storage key
    ///
    /// - Parameters:
    ///   - address: Ethereum address for which the meta mapping is to be fetched
    ///   - key: Storage key
    /// - Returns: EthMetaMapping object if available otherwise nil
    func getMetaMapping(forAddress address: String, andKey key: String) -> EthMetaMapping? {
        let userDeviceInfo: [String: Any] = getUserDeviceInfo()
        let ethKeyMappingData: [String: [String: Any]]? = userDeviceInfo[key] as? [String: [String: Any]]
        if let keyMappingValues =  ethKeyMappingData?[address.lowercased()] {
            return EthMetaMapping.getEthMetaMapping(from: keyMappingValues)
        }
        return nil
    }
    
    /// Get all address for a meta mapping type
    ///
    /// - Parameter key: Meta mapping key
    /// - Returns: Array of addresses
    func getAllAddresses(ForKey key:String) -> [String] {
        let userDeviceInfo: [String: Any] = getUserDeviceInfo()
        guard let ethKeyMappingData: [String: [String: Any]] = userDeviceInfo[key] as? [String: [String: Any]] else {
            return []
        }
        return Array(ethKeyMappingData.keys)
    }

    /// Delete meta mapping in the keychain
    ///
    /// - Parameters:
    ///   - ethMetaMapping: EthMetaMapping object
    ///   - key: Storage key
    /// - Throws: OSTError
    func deleteMetaMapping(forAddress address: String, forKey key: String) throws {
        var userDeviceInfo: [String: Any] = getUserDeviceInfo()
        
        if var ethKeyMappingData:[String: Any] = userDeviceInfo[key] as? [String : Any] {
            if let ethKeyMapping: [String: Any] = ethKeyMappingData[address.lowercased()] as? [String: Any] {
                try deleteString(forKey: ethKeyMapping["entityId"] as! String)
                ethKeyMappingData[address.lowercased()] = nil;
                userDeviceInfo[key] = ethKeyMappingData
                try setUserDeviceInfo(deviceInfo: userDeviceInfo)
            }
        }
    }
    
    /// Store mnemonics in the keychain for given ethereum address
    ///
    /// - Parameters:
    ///   - mnemonics: Array containing 12 words
    ///   - address: Ethereum address
    /// - Throws: OSTError
    func storeMnemonics(_ mnemonics: [String], forAddress address: String) throws {
        let entityId = OstInternalKeyManager.getMnemonicsStorageKey(forAddress: address)
        var ethMetaMapping = EthMetaMapping(address: address, entityId: entityId, identifier: self.secureEnclaveIdentifier)
        
        if let jsonString = try OstUtils.toJSONString(mnemonics) {
            try storeString(jsonString, ethMetaMapping: &ethMetaMapping)
            try setMnemonicsMetaMapping(ethMetaMapping)
            return
        }
        throw OstError("s_i_km_sm_1", .mnemonicsNotStored)
    }
    
    /// Store etheruem key in the keychain
    ///
    /// - Parameters:
    ///   - key: Storage key
    ///   - address: Ethereum address
    /// - Throws: OSTError
    func storeEthereumKey(_ key: String, forAddress address: String) throws {
        let entityId = OstInternalKeyManager.getAddressStorageKey(forAddress: address)
        var ethMetaMapping = EthMetaMapping(address: address, entityId: entityId, identifier: self.secureEnclaveIdentifier)
        try storeString(key, ethMetaMapping: &ethMetaMapping)
        try setEthKeyMetaMapping(ethMetaMapping)
    }
    
    /// Store session key in the keychain
    ///
    /// - Parameters:
    ///   - key: Storage key
    ///   - address: Ethereum address
    /// - Throws: OSTError
    func storeSessionKey(_ key: String, forAddress address: String) throws {
        let entityId = OstInternalKeyManager.getAddressStorageKey(forAddress: address)
        var ethMetaMapping = EthMetaMapping(address: address, entityId: entityId, identifier: self.secureEnclaveIdentifier)
        try storeString(key, ethMetaMapping: &ethMetaMapping)
        try setSessionKeyMetaMapping(ethMetaMapping)
    }
    
    /// Get session key from the keychain
    ///
    /// - Parameter address: Session address
    /// - Returns: Private key for given session address
    /// - Throws: OstError
    func getSessionKey(forAddress address: String) throws -> String? {
        if let ethMetaMapping: EthMetaMapping =  getSessionKeyMetaMapping(forAddress: address) {
            return try getString(from: ethMetaMapping)
        }
        return nil
    }

    /// Get the private key for the given ethereum address
    ///
    /// - Parameter address: Ethereum address
    /// - Returns: Private key for the ethereum address
    /// - Throws: OSTError
    func getEthereumKey(forAddresss address: String) throws -> String? {
        if let ethMetaMapping: EthMetaMapping =  getEthKeyMetaMapping(forAddress: address) {
            return try getString(from: ethMetaMapping)
        }
        return nil
    }
    
    /// Stores string in keychain. Updates the meta mapping object if the secure enclave encryption is performed
    ///
    /// - Parameters:
    ///   - string: A string that needs to be stored in keychain
    ///   - storageKey: Storage key
    ///   - ethMetaMapping: EthMetaMapping object
    /// - Throws: OSTError
    func storeString(_ string: String, ethMetaMapping: inout EthMetaMapping) throws {
        var eData: Data? = nil
        if #available(iOS 10.3, *) {
            if Device.hasSecureEnclave {
                let enclaveHelperObj = OstSecureEnclaveHelper(tag: ethMetaMapping.identifier)
                if let privateKey: SecKey = try enclaveHelperObj.getPrivateKey() {
                    eData = try enclaveHelperObj.encrypt(data: string.data(using: .utf8)!, withPrivateKey: privateKey)
                    ethMetaMapping.isSecureEnclaveEncrypted = true
                }
            }
        }
        if (eData == nil) {
            eData = OstUtils.toEncodedData(string)
            ethMetaMapping.identifier = ""
        }
        
        try keychainHelper.setDataInKeychain(data: eData!, forKey: ethMetaMapping.entityId)
    }
    
    /// Get the string for keychain. If the string was encrypted with secure enclave it will decrypt it
    ///
    /// - Parameters:
    ///   - ethMetaMapping: EthMetaMapping object
    /// - Returns: String
    /// - Throws: OSTError
    func getString(from ethMetaMapping: EthMetaMapping) throws -> String? {
        if let eData: Data = keychainHelper.getDataFromKeychain(forKey: ethMetaMapping.entityId) {
            if ethMetaMapping.isSecureEnclaveEncrypted {
                if #available(iOS 10.3, *) {
                    let enclaveHelperObj = OstSecureEnclaveHelper(tag: ethMetaMapping.identifier)
                    if let privateKey: SecKey = enclaveHelperObj.getPrivateKeyFromKeychain() {
                        let dData = try enclaveHelperObj.decrypt(data: eData, withPrivateKey: privateKey)
                        let jsonString: String = String(data: dData, encoding: .utf8)!
                        return jsonString
                    } else {
                        // Logger.log(message: "Private key not found.")
                        throw OstError("s_i_km_gs_1", .noPrivateKeyFound)
                    }
                }
            }else {
                return OstUtils.toDecodedValue(eData) as? String
            }
        }
        return nil
    }
    
    /// Delete the string from keychain
    ///
    /// - Parameter key: Key to be deleted
    /// - Throws: OstError
    func deleteString(forKey key: String) throws {
        try keychainHelper.deleteStringFromKeychain(forKey: key)
    }
}

//MARK: - Signing related methods
private extension OstInternalKeyManager {
    /// Sign message with API private key
    ///
    /// - Parameter message: Message to sign
    /// - Returns: Signed message
    /// - Throws: OstError
    func signWithAPIKey(message: String) throws -> String {
        guard let apiPrivateKey = try self.getAPIKey() else{
            throw OstError("s_i_km_swpk_1", .noPrivateKeyFound)
        }
        return try sign(message, withPrivatekey: apiPrivateKey)
    }
    
    /// Sign message with device private key
    ///
    /// - Parameter tx: Transaction string to sign
    /// - Returns: Signed message
    /// - Throws: OstError
    func signWithDeviceKey(_ tx: String) throws -> String {
        guard let devicePrivateKey = try self.getDeviceKey() else{
            throw OstError("s_i_km_swdk_1", .noPrivateKeyFound)
        }
        return try signTx(tx, withPrivatekey: devicePrivateKey)
    }
    
    /// Sign message with session's private key
    ///
    /// - Parameter tx: Transaction string to sign
    /// - Returns: Signed message
    /// - Throws: OstError
    func signWithSessionKey(_ tx: String, withAddress address: String) throws -> String {
        guard let sessionPrivateKey = try self.getSessionKey(forAddress: address) else{
            throw OstError("s_i_km_swsk_1", .noPrivateKeyFound)
        }
        return try signTx(tx, withPrivatekey: sessionPrivateKey)
    }
    
    /// Sign data with private key that is generated by mnemonics keys
    ///
    /// - Parameters:
    ///   - tx: Transaction to sign
    ///   - mnemonics: 12 words mnemonics keys
    /// - Returns: Signed message
    /// - Throws: OstError
    func signWithExternalDevice(_ tx: String, withMnemonics mnemonics: [String]) throws -> String {
        let ostWalletKeys = try OstCryptoImpls()
            .generateEthereumKeys(userId: self.userId,
                                  withMnemonics: mnemonics,
                                  forKeyType: .device)
        
        if (ostWalletKeys.address == nil || ostWalletKeys.privateKey == nil) {
            throw OstError("s_i_km_swm_1", .walletGenerationFailed)
        }
        return try signTx(tx, withPrivatekey: ostWalletKeys.privateKey!)
    }
    
    /// Sign data with recovery key
    ///
    /// - Parameters:
    ///   - tx: Transaction string to sign
    ///   - userPin: User pin
    ///   - passphrasePrefix: Passphrase prefix
    ///   - salt: Salt used to generate recovery key
    /// - Returns: SignedData
    /// - Throws: OstError
    func signWithRecoveryKey(
        tx:String,
        userPin: String,
        passphrasePrefix: String,
        salt: String) throws -> SignedData {
        
        let wallet = try OstCryptoImpls().getWallet(
            passphrasePrefix: passphrasePrefix,
            userPin: userPin,
            userId: self.userId,
            salt: salt,
            n: OstConstants.OST_RECOVERY_PIN_SCRYPT_N,
            r: OstConstants.OST_RECOVERY_PIN_SCRYPT_R,
            p: OstConstants.OST_RECOVERY_PIN_SCRYPT_P,
            size: OstConstants.OST_RECOVERY_PIN_SCRYPT_DESIRED_SIZE_BYTES
        )
        
        let privateKey = wallet.privateKey()
        let signedMessage = try signTx(tx, withPrivatekey: privateKey.toHexString())
        return (wallet.address(), signedMessage)
    }

    /// Sign message with private key
    ///
    /// - Parameter message: Message to sign
    /// - Returns: Signed message
    /// - Throws: OstError
    private func sign(_ message: String, withPrivatekey key: String) throws -> String {
        let privateKeyWithPadding = getPaddedPrivateKey(privateKey: key)
        let wallet : Wallet = Wallet(network: OstConstants.OST_WALLET_NETWORK,
                                     privateKey: privateKeyWithPadding,
                                     debugPrints: OstConstants.PRINT_DEBUG)
        
        var singedData: String
        do {
            singedData = try wallet.personalSign(message: message)
        } catch {
            throw OstError("s_i_km_s_1", .signTxFailed)
        }
        return singedData.addHexPrefix()
    }
    
    /// Sign the transaction with private key
    ///
    /// - Parameters:
    ///   - tx: Raw transaction string
    ///   - privateKey: private key string
    /// - Returns: Signed transaction string
    /// - Throws: OSTError
    private func signTx(_ tx: String, withPrivatekey privateKey: String) throws -> String {
        let privateKeyWithPadding = getPaddedPrivateKey(privateKey: privateKey)
        let priKey : PrivateKey = PrivateKey(raw: Data(hex: privateKeyWithPadding))
        
        var singedData: Data
        do {
            singedData = try priKey.sign(hash: Data(hex: tx))
        } catch {
            throw OstError("s_i_km_stx_1", .signTxFailed)
        }
        singedData[64] += 27
        let singedTx = singedData.toHexString().addHexPrefix();
        return singedTx
    }

    /// Get padded private key
    ///
    /// - Parameter privateKey: Private key
    /// - Returns: String of padded private key with length 64
    private func getPaddedPrivateKey(privateKey: String) -> String {
        let privateKeyHex = privateKey.stripHexPrefix()
        let privateKeyWithPadding = privateKeyHex.padLeft(totalWidth: PRIVATE_KEY_LENGTH, with: "0")
        return privateKeyWithPadding
    }
}

enum Device {
    /// To check that device has secure enclave or not
    static var hasSecureEnclave: Bool {
        return !isSimulator && hasBiometrics
    }
    
    /// To Check that this is this simulator
    private static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR == 1
    }
    
    /// Check that this device has Biometrics features available
    private static var hasBiometrics: Bool {
        //Local Authentication Context
        let localAuthContext = LAContext()
        var error: NSError?
        
        /// Policies can have certain requirements which, when not satisfied, would always cause
        /// the policy evaluation to fail - e.g. a passcode set, a fingerprint
        /// enrolled with Touch ID or a face set up with Face ID. This method allows easy checking
        /// for such conditions.
        var isValidPolicy = localAuthContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        guard isValidPolicy == true else {
            
            if #available(iOS 11, *) {
                
                if error!.code != LAError.biometryNotAvailable.rawValue {
                    isValidPolicy = true
                } else{
                    isValidPolicy = false
                }
            }
            else {
                if error!.code != LAError.touchIDNotAvailable.rawValue {
                    isValidPolicy = true
                }else{
                    isValidPolicy = false
                }
            }
            return isValidPolicy
        }
        return isValidPolicy
    }
}

class OstKeyManagerGateway {
    
    /// Initialize
    private init() {}
    
    /// Get API Signer
    ///
    /// - Parameter userId: User Id
    /// - Returns: OstAPISigner
    class func getOstApiSigner(userId: String) -> OstAPISigner {
        let keyManagerDelegate: OstKeyManagerDelegate = OstInternalKeyManager(userId: userId)
        return OstAPISigner(userId: userId,
                            keyManagerDelegate: keyManagerDelegate)
    }
    
    /// Get key manager
    ///
    /// - Parameter userId: User Id
    /// - Returns: OstKeyManager
    class func getOstKeyManager(userId: String) -> OstKeyManager {
        let keyManagerDelegate: OstKeyManagerDelegate = OstInternalKeyManager(userId: userId)
        return OstKeyManager(userId: userId,
                             keyManagareDelegate: keyManagerDelegate)
    }
    
    /// Get pin manager
    ///
    /// - Parameters:
    ///   - userId: User Id
    ///   - passphrasePrefix: Passphrase prefix
    ///   - userPin: User pin
    ///   - newUserPin: New user pin
    /// - Returns: OstPinManager
    class func getOstPinManager(userId: String,
                                passphrasePrefix: String,
                                userPin: String,
                                newUserPin: String? = "") -> OstPinManager {
        
        let keyManagerDelegate: OstKeyManagerDelegate = OstInternalKeyManager(userId: userId)
        return OstPinManager(userId: userId,
                             passphrasePrefix: passphrasePrefix,
                             userPin: userPin,
                             newUserPin: newUserPin,
                             keyManagareDelegate: keyManagerDelegate)
    }
    
    /// Get authorize session signer
    ///
    /// - Parameters:
    ///   - userId: User Id
    ///   - sessionAddress: Session address
    ///   - spendingLimit: Spending limit
    ///   - expirationHeight: Expiration height(Absolute value)
    /// - Returns: OstAuthorizeSessionSigner
    class func getOstAuthorizeSessionSigner(userId: String,
                                            sessionAddress: String,
                                            spendingLimit: String,
                                            expirationHeight: String) -> OstAuthorizeSessionSigner {
        
        let keyManagerDelegate: OstKeyManagerDelegate = OstInternalKeyManager(userId: userId)
        return OstAuthorizeSessionSigner(userId: userId,
                                         sessionAddress: sessionAddress,
                                         spendingLimit: spendingLimit,
                                         expirationHeight: expirationHeight,
                                         keyManagerDelegate: keyManagerDelegate)
    }
    
    /// Get authorize device with mnemonics signer
    ///
    /// - Parameters:
    ///   - userId: User Id
    ///   - deviceAddressToAdd: Device address to authorize
    ///   - mnemonicsManager: OstMnemonicsKeyManager
    /// - Returns: OstAuthorizeDeviceWithMnemonicsSigner
    class func getOstAuthorizeDeviceWithMnemonicsSigner(userId: String,
                                                        deviceAddressToAdd: String,
                                                        mnemonicsManager: OstMnemonicsKeyManager) -> OstAuthorizeDeviceWithMnemonicsSigner {
        
        let keyManagerDelegate: OstKeyManagerDelegate = OstInternalKeyManager(userId: userId)
        return OstAuthorizeDeviceWithMnemonicsSigner(userId: userId,
                                                     deviceAddressToAdd: deviceAddressToAdd,
                                                     mnemonicsManager: mnemonicsManager,
                                                     keyManagerDelegate: keyManagerDelegate)
    }
    
    /// Get authorize device with QR-Code signer
    ///
    /// - Parameters:
    ///   - userId: User Id
    ///   - deviceAddressToAdd: Device address to authorize
    /// - Returns: OstAuthorizeDeviceWithQRSigner
    class func getOstAuthorizeDeviceWithQRSigner(userId: String,
                                                 deviceAddressToAdd: String) -> OstAuthorizeDeviceWithQRSigner {
        
        let keyManagerDelegate: OstKeyManagerDelegate = OstInternalKeyManager(userId: userId)
        return OstAuthorizeDeviceWithQRSigner(userId: userId,
                                              address: deviceAddressToAdd,
                                              keyManagerDelegate: keyManagerDelegate)
    }
    
    /// Get revoke device with signer
    ///
    /// - Parameters:
    ///   - userId: User Id
    ///   - linkedAddress: Linked address
    ///   - deviceAddressToRevoke: Device address to revoke
    /// - Returns: OstRevokeDeviceSigner
    class func getOstRevokeDeviceSigner(userId: String,
                                        linkedAddress: String,
                                        deviceAddressToRevoke: String) -> OstRevokeDeviceSigner {
        
        let keyManagerDelegate: OstKeyManagerDelegate = OstInternalKeyManager(userId: userId)
        return OstRevokeDeviceSigner(userId: userId,
                                     linkedAddress: linkedAddress,
                                     deviceAddressToRevoke: deviceAddressToRevoke,
                                     keyManagerDelegate: keyManagerDelegate)
    }
    
    /// Get logout all session signer
    ///
    /// - Parameter userId: User Id
    /// - Returns: OstLogoutAllSessionSigner
    class func getOstLogoutAllSessionSigner(userId: String) -> OstLogoutAllSessionSigner {
        let keyManagerDelegate: OstKeyManagerDelegate = OstInternalKeyManager(userId: userId)
        return OstLogoutAllSessionSigner(userId: userId,
                                         keyManagerDelegate: keyManagerDelegate)
    }
    
    /// Get Biometric manager
    ///
    /// - Parameter userId: User Id
    /// - Returns: OstBiometricManager
    class func getOstBiometricManager(userId: String) -> OstBiometricManager {
        let keyManagerDelegate: OstKeyManagerDelegate = OstInternalKeyManager(userId: userId)
        return OstBiometricManager(userId: userId,
                                   keyManagareDelegate: keyManagerDelegate)
    }
}

