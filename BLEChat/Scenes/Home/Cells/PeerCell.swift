//
//  PeerCell.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/12/23.
//

import UIKit
import SnapKit

class PeerCell: UITableViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
    
    private var nameLabel = UILabel()
    private var deviceLabel =  UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, deviceLabel])
        stackView.axis = .vertical
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        nameLabel.text = "Name"
        deviceLabel.text = "Device"
    }
    
    func configure(with viewModel: ContactViewModel) {
        nameLabel.text = viewModel.name
        deviceLabel.text = viewModel.device
    }

}
