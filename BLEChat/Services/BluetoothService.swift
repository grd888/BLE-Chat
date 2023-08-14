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
    var deviceListUpdated: (([PeerDevice]) -> Void)? { get set }
    
    func start()
    func setDeviceName(_ name: String)
}

enum BLEChatServiceError: Error {
    case unauthorized
    case unsupported
}
class BluetoothService: NSObject, BluetoothServiceProtocol {
    
    var errorNotifier: ((BLEChatServiceError) -> Void)?
    var deviceListUpdated: (([PeerDevice]) -> Void)?
    
    var deviceName = "Gecko" {
        didSet {
            logger.info("Setting device name to \(self.deviceName)")
            startAdvertising()
        }
    }
    
    private var central: CBCentral?
    private var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var peripheralManager: CBPeripheralManager?
    private var centralCharacteristic: CBCharacteristic?
    private var peripheralCharacteristic: CBMutableCharacteristic?
    
    private var deviceList = [PeerDevice]()
    
    private var logger = Logger(subsystem: "org.gdelgado.blechat", category: "BluetoothService")
    private let queue = DispatchQueue(label: "org.gdelgado.blechat", qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    
    init(deviceName: String? = nil) {
        super.init()
        if let deviceName { self.deviceName = deviceName }
    }
    
    func start() {
        centralManager = CBCentralManager(delegate: self, queue: queue)
        peripheralManager = CBPeripheralManager(delegate: self, queue: queue)
    }
    
    func setDeviceName(_ name: String) {
        self.deviceName = name
    }
    /// updates list of found peers
    private func updateDeviceList(with device: PeerDevice) {
        if let index = deviceList.firstIndex(where: {$0.peripheral.identifier == device.peripheral.identifier}) {
            deviceList[index] = device
        } else {
            deviceList.append(device)
        }
        deviceListUpdated?(deviceList)
//        if !deviceList.contains(device) {
//            deviceList.insert(device)
//            deviceListUpdated?(Array(deviceList))
//        } else if deviceList.co
    }
    
    private func startAdvertising() {
        guard let peripheralManager else { return }
        guard peripheralManager.state == .poweredOn else { return }
        if peripheralManager.isAdvertising {
            peripheralManager.stopAdvertising()
        }
        peripheralManager.startAdvertising(
            [CBAdvertisementDataServiceUUIDsKey: [Constants.chatDiscoveryServiceID],
             CBAdvertisementDataLocalNameKey: deviceName])
        logger.info("Peripheral started advertising using name \(self.deviceName)")
    }
}

extension BluetoothService: CBCentralManagerDelegate {
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var name = peripheral.identifier.description
        if let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            name = deviceName
        }
        
        logger.info("Found a device name: \(peripheral.name ?? peripheral.identifier.description)")
        logger.info("Peer name is: \(name)")
        logger.info("Device ID: \(peripheral.identifier.description)")
                let device = PeerDevice(peripheral: peripheral, name: name)
        if let uuids = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            logger.debug("UUID: \(uuids.first?.uuidString ?? "no UUID")")
        }
        DispatchQueue.main.async {
            self.updateDeviceList(with: device)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .resetting, .poweredOff, .unknown:
            break
        case .unsupported:
            errorNotifier?(.unsupported)
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

        logger.info("Started scanning for service with UUID: \(Constants.chatDiscoveryServiceID)")
    }
}

extension BluetoothService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else { return }
        startAdvertising()
    }
}
