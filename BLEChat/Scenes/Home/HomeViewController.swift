//
//  HomeViewController.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/11/23.
//

import UIKit
import OSLog

class HomeViewController: UIViewController, Alertable {
    private var viewModel: HomeViewModelProtocol
    private var logger = Logger(subsystem: "org.gdelgado.blechat", category: "HomeViewController")
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
                    self.showAlert(title: "Error",
                                   message: message,
                                   cancelTitle: "Maybe later",
                                   actionTitle: actionTitle,
                                   action: self.goToSettings)
                default:
                    self.showAlert(title: "Error", message: message)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.startScanning()
        logger.info("viewWillAppear: ask viewModel to start scanning")
    }
}
