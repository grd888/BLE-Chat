//
//  BlueToothChatService.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/14/23.
//

import Foundation
import CoreBluetooth

enum BluetoothChatState {
    case scanning               // Scanning as a central
    case advertising            // Advertising as a peripheral
    case chattingAsCentral      // Connected and chatting as a central
    case chattingAsPeripheral   // Connected and chatting as a peripheral
}

class BluetoothChatService: NSObject, ChatService {
    
    
    var messageReceivedHandler: ((String) -> Void)?
    
    private var deviceIdentifier: UUID
    
    private var state = BluetoothChatState.scanning

    private var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var peripheralManager: CBPeripheralManager?
    private var central: CBCentral?

    private var centralCharacteristic: CBCharacteristic?
    private var peripheralCharacteristic: CBMutableCharacteristic?

    private var pendingMessageData: Data?
    
    init(deviceIdentifier: UUID) {
        // Save the device
        self.deviceIdentifier = deviceIdentifier
        super.init()
        // Start the central, scanning immediately
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func send(message: String) {
        let messageData = message.data(using: .utf8)!
        
        switch state {
        case .scanning:
            // If we haven't established a connection yet,
            // make this device a peripheral and start advertising
            pendingMessageData = messageData
            startAdvertising()
        case .advertising:
            // If we're advertising, replace the last message
            pendingMessageData = messageData
        case .chattingAsCentral:
            sendCentralData(messageData)
        case .chattingAsPeripheral:
            sendPeripheralData(messageData)
        }
    }
    
    private func startAdvertising() {
        guard state == .scanning, peripheralManager == nil else { return }

        state = .advertising

        // Create the peripheral manager, which will implicitly kick off the
        // update status delegate
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    private func sendCentralData(_ data: Data) {
        guard let characteristic = centralCharacteristic, let peripheral = self.peripheral else { return }
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    private func sendPeripheralData(_ data: Data) {
        guard let characteristic = self.peripheralCharacteristic, let central = self.central else { return }
        peripheralManager?.updateValue(data, for: characteristic, onSubscribedCentrals: [central])
    }
    
    
}

extension BluetoothChatService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        guard central.isScanning == false else { return }

        startScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripheral.identifier == deviceIdentifier else { return }
        centralManager?.connect(peripheral, options: nil)
        self.peripheral = peripheral

        // Change our state to chatting as central
        state = .chattingAsCentral
    }
    
    /// Called when a peripheral has successfully connected to this device (which is acting as a central)
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Stop scanning once we've connected
        central.stopScan()

        // Configure a delegate for the peripheral
        peripheral.delegate = self

        // Scan for the chat characteristic we'll use to communicate
        peripheral.discoverServices([Constants.chatServiceID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
        
        resetCentral()
        startScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
        resetCentral()
        startScan()
    }
    
    private func resetCentral() {
        // Reset all state
        self.state = .scanning
        self.peripheral = nil
    }

    /// Begin scanning for any peripherals matching the chat service we support
    private func startScan() {
        guard let centralManager = centralManager, !centralManager.isScanning else { return }

        // Start scanning for a peripheral that matches our saved device
        centralManager.scanForPeripherals(withServices: [Constants.chatServiceID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
}

extension BluetoothChatService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else { return }
        
        peripheralCharacteristic = CBMutableCharacteristic(type: Constants.chatCharacteristicID,
                                                           properties: [.write, .notify],
                                                           value: nil,
                                                           permissions: .writeable)
        let service = CBMutableService(type: Constants.chatServiceID, primary: true)
        service.characteristics = [peripheralCharacteristic!]
        peripheralManager?.add(service)
        let advertisementData: [String: Any] = [CBAdvertisementDataServiceUUIDsKey: [Constants.chatServiceID]]
        peripheralManager?.startAdvertising(advertisementData)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        centralManager?.stopScan()
        state = .chattingAsPeripheral
        self.central = central
        if let data = pendingMessageData {
            sendPeripheralData(data)
            pendingMessageData = nil
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        self.central = nil
        centralManager?.scanForPeripherals(withServices: [Constants.chatServiceID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        guard let request = requests.first, let data = request.value else { return }
        let message = String(decoding: data, as: UTF8.self)
        messageReceivedHandler?(message)
    }
}

extension BluetoothChatService: CBPeripheralDelegate {
    private func cleanUp() {
        guard let peripheral = peripheral, peripheral.state != .disconnected else { return }
        peripheral.services?.forEach { service in
            service.characteristics?.forEach { characteristic in
                if characteristic.uuid != Constants.chatCharacteristicID { return }
                if characteristic.isNotifying {
                    peripheral.setNotifyValue(false, for: characteristic)
                }
            }
        }
        centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Unable to discover service: \(error.localizedDescription)")
            cleanUp()
            return
        }
        peripheral.services?.forEach({ service in
            peripheral.discoverCharacteristics([Constants.chatCharacteristicID], for: service)
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Unable to discover characteristics: \(error.localizedDescription)")
            cleanUp()
            return
        }
        
        service.characteristics?.forEach { characteristic in
            guard characteristic.uuid == Constants.chatCharacteristicID else { return }

            // Subscribe to this characteristic, so we can be notified when data comes from it
            peripheral.setNotifyValue(true, for: characteristic)

            // Hold onto a reference for this characteristic for sending data
            self.centralCharacteristic = characteristic
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Characteristic value update failed: \(error.localizedDescription)")
            return
        }
        guard let data = characteristic.value else { return }
        let message = String(decoding: data, as: UTF8.self)
        messageReceivedHandler?(message)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Characteristic update notification failed: \(error.localizedDescription)")
            return
        }

        // Ensure this characteristic is the one we configured
        guard characteristic.uuid == Constants.chatCharacteristicID else { return }

        // Check if it is successfully set as notifying
        if characteristic.isNotifying {
            print("Characteristic notifications have begun.")
        } else {
            print("Characteristic notifications have stopped. Disconnecting.")
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        if let data = pendingMessageData {
            sendCentralData(data)
            pendingMessageData = nil
        }
    }
}
