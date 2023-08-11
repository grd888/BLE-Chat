//
//  HomeViewController.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/11/23.
//

import UIKit

class HomeViewController: UIViewController {

    var discoverService: BluetoothService!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .cyan
        discoverService = BluetoothService()
        discoverService.errorNotifier = { [unowned self] error in
            switch error {
            case .unauthorized:
                self.showAlert(title: "Permission Required", message: "You have disallowed bluetooth usage. To enable chat functionality, go to Settings and allow Bluetooth usage.")
            }
        }
    }
    
    func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Go to Settings", style: .default) { _ in
            self.goToSettings()
        })
        alert.addAction(UIAlertAction(title: "Not now", style: .cancel))
        present(alert, animated: true)
    }
    
    func goToSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
}

