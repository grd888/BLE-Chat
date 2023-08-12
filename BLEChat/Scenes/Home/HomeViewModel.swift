//
//  HomeViewModel.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/12/23.
//

import Foundation

protocol HomeViewModelProtocol {
    var onErrorMessage: ((String, ActionType?) -> Void)? { set get }
    var deviceName: String { get set }
    func numberOfContacts() -> Int
}
enum ActionType {
    case gotoSettings(String)
}

class HomeViewModel: HomeViewModelProtocol {
    
    private var bluetoothService: BluetoothServiceProtocol!
    private var contactList = [Contact]()
    var onErrorMessage: ((String, ActionType?) -> Void)?
    var deviceName = "iPhone"
    
    init(bluetoothService: BluetoothServiceProtocol) {
        self.bluetoothService = bluetoothService
        setupBluetoothService()
    }
    
    func setupBluetoothService() {
        bluetoothService.setDeviceName(deviceName)
        bluetoothService.errorNotifier = { [unowned self] error in
            switch error {
            case .unauthorized:
                self.onErrorMessage?("You have disallowed bluetooth usage. To enable chat functionality, go to Settings and allow Bluetooth usage.", ActionType.gotoSettings("Go to Settings"))
            }
        }
    }
    
    func numberOfContacts() -> Int {
        return contactList.count
    }
}
