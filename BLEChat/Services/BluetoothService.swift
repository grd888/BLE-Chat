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
    var deviceName = "Gecko" {
        didSet { startAdvertising() }
    }
    
    private var central: CBCentral?
    private var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var peripheralManager: CBPeripheralManager!
    private var centralCharacteristic: CBCharacteristic?
    private var peripheralCharacteristic: CBMutableCharacteristic?
    
    private let queue = DispatchQueue(label: "org.gdelgado.blechat", qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    
    init(deviceName: String? = nil) {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: queue)
        peripheralManager = CBPeripheralManager(delegate: self, queue: queue)
        if let deviceName { self.deviceName = deviceName }
    }
    
    private func startAdvertising() {
        guard peripheralManager.state == .poweredOn else { return }
        if peripheralManager.isAdvertising {
            peripheralManager.stopAdvertising()
        }
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: Constants.chatDiscoveryServiceID,
            CBAdvertisementDataLocalNameKey: deviceName
        ])
        os_log("Peripheral started advertising")
    }
}

extension BluetoothService: CBCentralManagerDelegate {
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var name = peripheral.identifier.description
        if let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            name = deviceName
        }
        
    }
    
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
        guard let centralManager = centralManager else { return }

        // Start scanning for a peripheral that matches our saved device
        centralManager.scanForPeripherals(withServices: [Constants.chatDiscoveryServiceID],
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])

        os_log("Started scanning.")
    }
}

extension BluetoothService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else { return }
        startAdvertising()
    }
}
