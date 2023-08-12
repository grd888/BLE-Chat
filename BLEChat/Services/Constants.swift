//
//  Constants.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/11/23.
//

import Foundation
import CoreBluetooth

struct Constants {
    static let chatDiscoveryServiceID = CBUUID(string: "42332fe8-9915-11ea-bb37-0242ac130002")

    static let chatServiceID = CBUUID(string: "43eb0d29-4188-4c84-b1e8-73231e02af95")

    static let chatCharacteristicID = CBUUID(string: "f0ab5a15-b003-4653-a248-73fd504c128f")

}
