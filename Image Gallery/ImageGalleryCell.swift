//
//  ImageGalleryCell.swift
//  Image Gallery
//
//  Created by Darren Wilson on 13/07/2018.
//  Copyright © 2018 Darren Wilson. All rights reserved.
//

import UIKit

class ImageGalleryCell: UICollectionViewCell {
    
    @IBOutlet weak var image: UIImageView! {
        didSet {
            //image.sizeToFit()
        }
    }
    
    
}
