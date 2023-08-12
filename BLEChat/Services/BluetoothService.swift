//
//  BluetoothService.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/11/23.
//

import Foundation
import CoreBluetooth
import OSLog

protocol BluetoothServiceProtocol {
    var errorNotifier: ((BLEChatServiceError) -> Void)? { get set }
    func setDeviceName(_ name: String)
}
enum BLEChatServiceError: Error {
    case unauthorized
}
class BluetoothService: NSObject, BluetoothServiceProtocol {
    
    var errorNotifier: ((BLEChatServiceError) -> Void)?
    var deviceName = "Gecko" {
        didSet {
            os_log("Setting device name to \(self.deviceName)")
            startAdvertising()
        }
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
    
    func setDeviceName(_ name: String) {
        self.deviceName = name
    }
    /// updates list of found peers
    private func updateDeviceList(with device: PeerDevice) {
        print("Peer name: \(device.name)")
        os_log("Found a device: \(device.peripheral.name ?? device.peripheral.identifier.description)")
    }
    
    private func startAdvertising() {
        guard peripheralManager.state == .poweredOn else { return }
        if peripheralManager.isAdvertising {
            peripheralManager.stopAdvertising()
        }
        peripheralManager.startAdvertising(
            [CBAdvertisementDataServiceUUIDsKey: [Constants.chatDiscoveryServiceID],
             CBAdvertisementDataLocalNameKey: deviceName])
        os_log("Peripheral started advertising using name \(self.deviceName)")
    }
}

extension BluetoothService: CBCentralManagerDelegate {
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var name = peripheral.identifier.description
        if let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            name = deviceName
        }
        
        if let uuids = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            print(uuids[0].uuidString)
        }
        let device = PeerDevice(peripheral: peripheral, name: name)
        DispatchQueue.main.async {
            self.updateDeviceList(with: device)
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
