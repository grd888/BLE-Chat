//
//  Alertable.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/12/23.
//

import UIKit

protocol Alertable {
    func showAlert(title: String?,
                   message: String?,
                   cancelTitle: String?,
                   actionTitle: String?,
                   action: (() -> Void)?)
    func goToSettings()
}

extension Alertable where Self: UIViewController {
    func showAlert(title: String?,
                   message: String?,
                   cancelTitle: String?,
                   actionTitle: String? = "OK",
                   action: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default) { _ in
            if let action { action() }
        })
        if cancelTitle != nil {
            alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
        }
        present(alert, animated: true)
    }
    
    func goToSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
}

