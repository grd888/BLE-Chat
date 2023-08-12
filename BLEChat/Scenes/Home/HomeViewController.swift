//
//  HomeViewController.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/11/23.
//

import UIKit
import OSLog

class HomeViewController: UIViewController {
    private var viewModel: HomeViewModelProtocol
    
    init(viewModel: HomeViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .cyan
        viewModel.deviceName = UIDevice.current.name
        viewModel.onErrorMessage = { [unowned self] message, action in
            DispatchQueue.main.async {
                switch action {
                case .gotoSettings(let actionTitle):
                    self.showAlert(title: "Error", message: message,actionTitle: actionTitle, action: self.goToSettings)
                default:
                    self.showAlert(title: "Error", message: message)
                }
            }
        }
    }
    
    func showAlert(title: String?,
                   message: String?,
                   actionTitle: String? = "OK",
                   action: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default) { _ in
            if let action { action() }
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
