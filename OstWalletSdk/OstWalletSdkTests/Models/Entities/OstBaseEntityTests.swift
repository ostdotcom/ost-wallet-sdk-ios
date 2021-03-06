/*
 Copyright © 2019 OST.com Inc
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 */

import XCTest
@testable import OstWalletSdk

class OstBaseEntityTests: XCTestCase {
    
    
    var jsonObject: [String: Any] = ["id":"123","parent_id":"1","status":"active","uts": "12324","name": "alice"]
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testInitObj() {
        
        XCTAssertNotNil(try OstUser(jsonObject), "Object creation failed.")
        XCTAssertNotNil(try OstUser(["id":1]), "Object creation failed.")
    }
    
    func testObjectCreationFailed() {
        jsonObject["id"] = nil
        XCTAssertThrowsError(try OstUser(jsonObject))
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
