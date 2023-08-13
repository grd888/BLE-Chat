//
//  TextFieldCell.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/13/23.
//

import UIKit
import SnapKit

class TextFieldCell: UITableViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
    var textFieldChangedHandler: ((String) -> Void)?
    private var textField = UITextField()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        textField.placeholder = "iPhone"
        textField.delegate = self
        contentView.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }
}

extension TextFieldCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        var deviceName = textField.text
        if deviceName?.count ?? 0 == 0 { deviceName = textField.placeholder ?? "iPhone" }
        textFieldChangedHandler?(deviceName!)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
