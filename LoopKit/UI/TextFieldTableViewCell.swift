//
//  TextFieldTableViewCell.swift
//  Naterade
//
//  Created by Nathan Racklyeft on 5/22/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import UIKit


public protocol TextFieldTableViewCellDelegate: class {
    func textFieldTableViewCellDidBeginEditing(_ cell: TextFieldTableViewCell)
    
    func textFieldTableViewCellDidEndEditing(_ cell: TextFieldTableViewCell)
}


public class TextFieldTableViewCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var unitLabel: UILabel?

    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField.delegate = self
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()

        textField.delegate = nil
        unitLabel?.text = nil
    }
    
    public override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: true)
        
        if selected {
            if textField.isFirstResponder {
                textField.resignFirstResponder()
            } else {
                textField.becomeFirstResponder()
            }
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.layoutMargins.left = separatorInset.left
        contentView.layoutMargins.right = separatorInset.left
    }
    
    weak var delegate: TextFieldTableViewCellDelegate?
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.textFieldTableViewCellDidBeginEditing(self)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.textFieldTableViewCellDidEndEditing(self)
    }
}
