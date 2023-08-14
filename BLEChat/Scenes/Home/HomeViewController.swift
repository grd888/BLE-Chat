//
//  HomeViewController.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/11/23.
//

import UIKit
import OSLog
import SnapKit

class HomeViewController: UIViewController, Alertable {
    struct Section {
        static let name = 0
        static let devices = 1
    }
    private var tableView: UITableView!
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
        setupView()
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
                    self.showAlert(title: "Error", message: message, cancelTitle: nil)
                }
            }
        }
        viewModel.onDeviceUpdate = { [unowned self] in
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.startScanning()
        logger.info("viewWillAppear: ask viewModel to start scanning")
    }
    
    private func setupView() {
        title = "Home"
        setupTableView()
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: TextFieldCell.reuseIdentifier)
        tableView.register(PeerCell.self, forCellReuseIdentifier: PeerCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Section.name {
            return 1
        } else {
            return viewModel.numberOfContacts()
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Section.name {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TextFieldCell.reuseIdentifier, for: indexPath) as? TextFieldCell else {
                assertionFailure("Could not dequeue TextFieldCell")
                return UITableViewCell()
            }
            cell.textFieldChangedHandler = { name in
                self.viewModel.deviceName = name
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PeerCell.reuseIdentifier, for: indexPath) as? PeerCell else {
                assertionFailure("Could not dequeue PeerCell")
                return UITableViewCell()
            }
            let contact = viewModel.contact(at: indexPath.row)
            cell.configure(with: contact)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Section.name {
            return "Device name"
        } else {
            return "Available peers"
        }
    }
}
