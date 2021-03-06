/*
 Copyright © 2019 OST.com Inc
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 */

import Foundation

class OstBundle {
    
    enum PermissionKey: String {
        case NSFaceIDUsageDescription
        case CFBundleShortVersionString
    }
    
    /// Get content of files
    ///
    /// - Parameters:
    ///   - file: file name
    ///   - fileExtension: file extension
    /// - Returns: Content of file
    /// - Throws: OstError
    class func getContentOf(file: String, fileExtension: String) -> String? {
        let ostBundle = OstBundle()
        let bundleObj = ostBundle.getSdkBundle()
        return ostBundle.getFileContent(file,
                                            fileExtension: fileExtension,
                                            fromBundle: bundleObj)
    }
    
    /// Get application plist content
    ///
    /// - Parameters:
    ///   - key: Key name
    ///   - fileName: File name
    /// - Returns: Content for key
    /// - Throws: OstError
    class func getApplicationPlistContent(
        for key: String,
        fromFile fileName: String) -> AnyObject? {
        
        let ostBundle = OstBundle()
        let bundleObj = ostBundle.getApplicatoinBundle()
        return ostBundle.getDescription(
            for: key,
            fromFile: fileName,
            withExtension: "plist",
            inBundle: bundleObj
        )
    }
    
    /// Get content from application Info.plist.
    ///
    /// - Parameter key: Key name
    /// - Returns: Content for key.
    class func getApplictionInfoPlistContent(for key: String) -> Any? {
        let ostBundle = OstBundle()
        let bundleObj = ostBundle.getApplicatoinBundle()
        return bundleObj.object(forInfoDictionaryKey: key)
    }
    
    /// Get Sdk version
    ///
    /// - Returns: version string
    class func getSdkVersion() -> String  {
        let ostBundle = OstBundle()
        let bundleObj = ostBundle.getSdkBundle()
        let version = ostBundle.getDescription(for: PermissionKey.CFBundleShortVersionString.rawValue,
                                                   fromFile: "Info",
                                                   withExtension: "plist",
                                                   inBundle: bundleObj)
        return (version as? String) ?? ""
    }
    
    //MARK: Private Methods
    
    /// Initialize
    fileprivate init() { }
    
    class func getSdkBundle() -> Bundle {
        let ostBundle = OstBundle()
        let bundleObj = ostBundle.getSdkBundle()
        return bundleObj
    }
    
    /// Get Sdk bundle
    ///
    /// - Returns: Bundle
    func getSdkBundle() -> Bundle {
        let bundle = Bundle(for: type(of: self))
        return bundle
    }
    
    /// Get application bundle
    ///
    /// - Returns: Bundle
    class func getApplicationBundle() -> Bundle {
        let ostBundle = OstBundle()
        let bundleObj = ostBundle.getApplicatoinBundle()
        return bundleObj
    }
    
    /// Get application bundle
    ///
    /// - Returns: Bundle
    func getApplicatoinBundle() -> Bundle {
        let bundle = Bundle.main
        return bundle
    }
    
    /// Get file content
    ///
    /// - Parameters:
    ///   - fileName: File name
    ///   - fileExtension: Extension of file
    ///   - bundle: File exists in bundle name
    /// - Returns: Content of file
    /// - Throws: OstError
    fileprivate func getFileContent(_ fileName: String,
                                fileExtension: String,
                                fromBundle bundle: Bundle) -> String? {
        
        if let filepath = bundle.path(forResource: fileName, ofType: fileExtension),
            let contents = try? String(contentsOfFile: filepath) {
            return contents
        }
        return nil
    }
    
    /// Get permission description
    ///
    /// - Parameters:
    ///   - key: Permission key
    ///   - fileName: File name
    ///   - extension: File extension
    ///   - bundle: Bundle
    /// - Returns: Description Text
    /// - Throws: OstError
    fileprivate func getDescription(for key: String,
                                    fromFile fileName: String,
                                    withExtension fileExtension: String,
                                    inBundle bundle: Bundle) -> AnyObject? {
        
        let plistPath: String? = bundle.path(forResource: fileName, ofType: fileExtension)!
        let plistXML = FileManager.default.contents(atPath: plistPath!)!
        
        var propertyListForamt =  PropertyListSerialization.PropertyListFormat.xml //Format of the Property List.
        let plistData: [String: AnyObject]? = try? PropertyListSerialization
            .propertyList(from: plistXML,
                          options: .mutableContainersAndLeaves,
                          format: &propertyListForamt) as! [String : AnyObject]
        
        return plistData?[key];
    }
    
    
    /// Get plist data
    ///
    /// - Parameters:
    ///   - fileName: File name
    ///   - bundle: Bundle
    /// - Returns: Data
    class func getPlistFileData(fromFile fileName: String,
                                inBundle bundle: Bundle) -> [String: AnyObject]? {
        
        if let plistPath: String = bundle.path(forResource: fileName, ofType: "plist"),
            let plistXML = FileManager.default.contents(atPath: plistPath) {
        
            var propertyListForamt =  PropertyListSerialization.PropertyListFormat.xml //Format of the Property List.
            
            let plistData: [String: AnyObject]? = try? PropertyListSerialization
                .propertyList(from: plistXML,
                              options: .mutableContainersAndLeaves,
                              format: &propertyListForamt) as! [String : AnyObject]
            
            return plistData
        }
        return nil
    }
}
