//
//  ImageGalleryCell.swift
//  Image Gallery
//
//  Created by Darren Wilson on 13/07/2018.
//  Copyright © 2018 Darren Wilson. All rights reserved.
//

import UIKit

class ImageGalleryCell: UICollectionViewCell {
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            //image.sizeToFit()
        }
    }
    
    var imageURL: URL? = nil {
        didSet {
            fetchImage()
        }
    }
    
    private var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            imageView.sizeToFit()
            spinner?.stopAnimating()
        }
    }
    
    private func fetchImage() {
        if let url = imageURL {
            spinner.isHidden = false
            spinner.startAnimating()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let urlContents = try? Data(contentsOf: url)
                DispatchQueue.main.async {
                    if let imageData = urlContents, url == self?.imageURL {
                        self?.image = UIImage(data: imageData)
                    }
                }
            }
        }
    }
    
}
