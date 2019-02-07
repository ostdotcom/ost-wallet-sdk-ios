//
//  Log.swift
//  OstSdk
//
//  Created by aniket ayachit on 06/02/19.
//  Copyright © 2019 aniket ayachit. All rights reserved.
//

import Foundation
import Alamofire

public class Logger {
    public class func log(message: String? = nil, parameterToPrint: Any? = nil, function: String = #function) {
        #if DEBUG
        debugPrint()
        debugPrint("************************ START *********************************")
        debugPrint("function: \(function)")
        debugPrint("\(message ?? "") : \(parameterToPrint ?? "") ")
        debugPrint("************************* END *******************************")
        #endif
    }
}

extension Request {
    public func debugLog() -> Self {
        #if DEBUG
        debugPrint()
        debugPrint("=======================================")
        debugPrint(self)
        debugPrint("=======================================")
        #endif
        return self
    }
}
