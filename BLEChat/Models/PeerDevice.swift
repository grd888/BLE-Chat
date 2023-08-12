//
//  PeerDevice.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/12/23.
//

import Foundation
import CoreBluetooth

struct PeerDevice {
    let peripheral: CBPeripheral
    let name: String
    
    init(peripheral: CBPeripheral, name: String = "Unknown") {
        self.peripheral = peripheral
        self.name = name
    }
}

extension PeerDevice: Hashable {}
