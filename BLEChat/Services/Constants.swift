//
//  Constants.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/11/23.
//

import Foundation
import CoreBluetooth

struct Constants {
    static let chatDiscoveryServiceID = CBUUID(string: "1708b25c-ad02-49f0-82ce-cb4556623eb1")

    static let chatServiceID = CBUUID(string: "9c1182b5-8687-4619-9188-b6b3e3bfbfc9")

    static let chatCharacteristicID = CBUUID(string: "0aaeb74a-31cb-4955-b35e-7208edb79fd4")

}
