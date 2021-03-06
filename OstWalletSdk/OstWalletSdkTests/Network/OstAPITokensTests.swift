/*
 Copyright © 2019 OST.com Inc
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 */

import XCTest
@testable import OstWalletSdk

class OstAPITokensTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    class OstMockTokensAPI: OstAPIBase {
        override init(userId: String) {
            super.init(userId: userId)
        }

        override var getBaseURL: String {
            return "https://s4-api.stagingost.com/testnet/v2"
        }
        
        override var getResource: String {
            return "/tokens/"
        }
    }
    // TODO: Fix the test cases.
//    class MockApiSigner: OstAPISigner {
//        override init(userId: String) {
//            super.init(userId: userId)
//        }
//
//        override func getAPISigner() -> ApiSigner? {
//            return ApiSigner(userId: userId, APIKey: "0x6edc3804eb9f70b26731447b4e43955c5532f2195a6fe77cbed287dbd3c762ce")
//        }
//    }
    
//    func testGetToken() throws {
//        let userId = "6c6ea645-d86d-4449-8efa-3b54743f83de"
//
//        let tokensAPIObj = OstMockTokensAPI(userId: userId)
//
//        var params: [String: Any] = ["token_id": "58",
//                                     "request_timestamp": String(Date.timestamp()),
//                                     "user_id": userId,
//                                     "api_signer_id":"0xf65c7a49981db56AED34beA4617E32e326ACf977",
//                                     "signature_kind":"OST1-PS",
//                                     "wallet_address": "0x60A20Cdf6a21a73Fb89475221D252865C695e302"]
//
//        params["api_signature"] = try! MockApiSigner(userId: userId).sign(resource: tokensAPIObj.getResource, params: params)
//
//        tokensAPIObj.get(params: params as [String: AnyObject], onSuccess: { (httpSuccessResponse) in
//            Logger.log(message: "successResponse", parameterToPrint: httpSuccessResponse)
//        }) { (httpFailureResponse) in
//            Logger.log(message: "failureResponse", parameterToPrint: httpFailureResponse)
//        }
//
//    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
