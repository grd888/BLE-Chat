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

extension PeerDevice: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.peripheral.identifier == rhs.peripheral.identifier
    }
}
extension PeerDevice: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(peripheral.identifier)
    }
}
