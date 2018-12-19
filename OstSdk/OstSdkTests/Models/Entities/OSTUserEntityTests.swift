//
//  OSTUserEntityTests.swift
//  OstSdkTests
//
//  Created by aniket ayachit on 10/12/18.
//  Copyright © 2018 aniket ayachit. All rights reserved.
//

import XCTest
@testable import OstSdk

class OSTUserEntityTests: XCTestCase {
    
    var jsonData: [String: Any] = ["id":"123","parent_id":"1","status":"active","uts": "12324","name": "Aniket"]
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInitSuccess(){
        var userEntity: OSTUser
        do{
            userEntity = try OSTUser(jsonData: jsonData)
            XCTAssertNotNil(userEntity)
        }catch let error{
            print("Init failed for user entity failed. \(error)")
            XCTAssertTrue(false, "User entity creation failed.")
        }
    }
    
   
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
