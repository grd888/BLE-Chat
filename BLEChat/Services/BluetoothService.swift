//
//  BluetoothService.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/11/23.
//

import Foundation
import CoreBluetooth
import OSLog

class BluetoothService: NSObject {
    enum BLEChatServiceError: Error {
        case unauthorized
    }
    var errorNotifier: ((BLEChatServiceError) -> Void)?
    
    private var central: CBCentral?
    private var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var peripheralManager: CBPeripheralManager?
    private var centralCharacteristic: CBCharacteristic?
    private var peripheralCharacteristic: CBMutableCharacteristic?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension BluetoothService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .resetting, .poweredOff, .unknown:
            break
        case .unsupported:
            assertionFailure("Show a message to the user that bluetooth is not supported")
        case .unauthorized:
            errorNotifier?(.unauthorized)
        case .poweredOn:
            guard !central.isScanning else { return }
            startScan()
        @unknown default:
            assertionFailure("Unknown CBCentralManager state detected.")
        }
    }
    
    private func startScan() {
        os_log("Start scanning.")
    }
}
