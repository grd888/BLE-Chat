//
//  HomeViewModel.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/12/23.
//

import Foundation
import OSLog

protocol HomeViewModelProtocol {
    var onErrorMessage: ((String, ActionType?) -> Void)? { set get }
    var deviceName: String { get set }
    func startScanning()
    func numberOfContacts() -> Int
}
enum ActionType {
    case gotoSettings(String)
}

class HomeViewModel: HomeViewModelProtocol {

    var onErrorMessage: ((String, ActionType?) -> Void)?
    var deviceName = "iPhone"
    
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
            self.contactList = devices.map{ Contact(name: $0.name, device: $0.peripheral.name ?? $0.peripheral.description)}
        }
    }
    
    func startScanning() {
        bluetoothService.start()
    }
    
    func numberOfContacts() -> Int {
        return contactList.count
    }
}
