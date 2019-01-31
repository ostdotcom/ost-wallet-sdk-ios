//
//  OstUserEntityTests.swift
//  OstSdkTests
//
//  Created by aniket ayachit on 10/12/18.
//  Copyright © 2018 aniket ayachit. All rights reserved.
//

import XCTest
@testable import OstSdk

class OstUserTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInitUser() throws {
        let id = "1"
        let userDict = ["id": "\(id)a",
            "token_holder_id": "\(id)a",
            "multisig_id": "\(id)a",
            "economy_id" : "\(id)a",
            "updated_timestamp" : Date.timestamp()] as [String : Any]
            
            
        let user: OstUser? = try OstSdk.parseUser(userDict)
        print(user ?? "")
        XCTAssertNotNil(user, "user should not be nil")
        XCTAssertEqual(user?.id, userDict["id"] as? String, "id is not equal")
        XCTAssertEqual(user?.multisig_id, userDict["multisig_id"] as? String, "id is not equal")
    }
    
    func testBulkInitUser() throws {
        for i in 2..<5 {
            let id = i
            let userDict = ["id": "\(id)a",
                "token_holder_id": "\(id)a",
                "multisig_id": "\(id)a",
                "economy_id" : "\(id)a",
                "updated_timestamp" : Date.timestamp()] as [String : Any]
            
            let user: OstUser? = try OstSdk.parseUser(userDict)
            print(user ?? "")
            XCTAssertNotNil(user, "user should not be nil")
            XCTAssertEqual(user?.id, userDict["id"] as? String, "id is not equal")
            XCTAssertEqual(user?.multisig_id, userDict["multisig_id"] as? String, "id is not equal")
        }
    }
    
    func testGetEntity() {
        do {
            let user: OstUser? = try OstUserModelRepository.sharedUser.getById("1a") as? OstUser
            XCTAssertNil(user)
            let user1: OstUser? = try OstUserModelRepository.sharedUser.getById("4a") as? OstUser
            XCTAssertNotNil(user1)
        }catch let error{
            print(error)
        }
    }
   
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}