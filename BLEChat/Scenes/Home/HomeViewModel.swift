//
//  HomeViewModel.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/12/23.
//

import Foundation
import OSLog

protocol HomeViewModelProtocol {
    var onDeviceUpdate: (() -> Void)? { set get }
    var onErrorMessage: ((String, ActionType?) -> Void)? { set get }
    var deviceName: String { set get }
    func startScanning()
    func numberOfContacts() -> Int
    func contact(at index: Int) -> Contact
}
enum ActionType {
    case gotoSettings(String)
}

class HomeViewModel: HomeViewModelProtocol {
    var onDeviceUpdate: (() -> Void)?
    var onErrorMessage: ((String, ActionType?) -> Void)?
    var deviceName = "iPhone" {
        didSet {
            bluetoothService.setDeviceName(deviceName)
        }
    }
    
    private var bluetoothService: BluetoothServiceProtocol!
    private var contactList = [Contact]() {
        didSet {
            logger.info("Contact list updated.")
        }
    }
    private var logger = Logger(subsystem: "org.gdelgado.blechat", category: "HomeViewModel")
    
    init(bluetoothService: BluetoothServiceProtocol) {
        self.bluetoothService = bluetoothService
        setupBluetoothService()
    }
    
    func setupBluetoothService() {
        bluetoothService.setDeviceName(deviceName)
        bluetoothService.errorNotifier = { [unowned self] error in
            switch error {
            case .unsupported:
                self.onErrorMessage?("Bluetooth is not supported on this device.", nil)
            case .unauthorized:
                self.onErrorMessage?("You have disallowed bluetooth usage. To enable chat functionality, go to Settings and allow Bluetooth usage.", ActionType.gotoSettings("Go to Settings"))
            }
        }
        bluetoothService.deviceListUpdated = { [unowned self] devices in
            self.contactList = devices.map{ Contact(id: $0.peripheral.identifier,
                                                    name: $0.name,
                                                    device: $0.peripheral.name ?? $0.peripheral.description)}
            self.onDeviceUpdate?()
        }
    }
    
    func startScanning() {
        bluetoothService.start()
    }
    
    func numberOfContacts() -> Int {
        return contactList.count
    }
    
    func contact(at index: Int) -> Contact {
        return contactList[index]
    }
}

struct ContactViewModel {
    var name: String {
        return contact.name
    }
    var device: String {
        return contact.device
    }
    var id: UUID {
        return contact.id
    }
    private var contact: Contact
    
    init(contact: Contact) {
        self.contact = contact
    }
}
