//
//  GalleryTableViewCell.swift
//  Image Gallery
//
//  Created by Darren Wilson on 21/07/2018.
//  Copyright © 2018 Darren Wilson. All rights reserved.
//

import UIKit

class GalleryTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    var resignationHandler: (() -> Void)?

    @IBOutlet weak var nameTextField: UITextField! {
        didSet {
            nameTextField.isEnabled = false
            nameTextField.delegate = self
        }
    }
    
    var name: String? {
        get {
            return nameTextField.text
        }
        set {
            nameTextField.text = newValue
            setNeedsDisplay()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - Text Field Delegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.isEnabled = false
        if let handler = resignationHandler {
            handler()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}
