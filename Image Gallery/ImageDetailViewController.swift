//
//  ImageDetailViewController.swift
//  Image Gallery
//
//  Created by Darren Wilson on 17/07/2018.
//  Copyright © 2018 Darren Wilson. All rights reserved.
//

import UIKit

class ImageDetailViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.minimumZoomScale = 1 / 25
            scrollView.maximumZoomScale = 1.0
            scrollView.addSubview(imageView)
        }
    }
    
    private var imageView = UIImageView()
    
    var imageURL: URL?
    
    private var imageFetcher: ImageFetcher?
    
    private var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            imageView.sizeToFit()
            scrollView?.contentSize = imageView.frame.size
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    private func fetchImage() {
        if imageURL != nil {
            imageFetcher = ImageFetcher(handler: { (url, image) in
                if url == self.imageURL {
                    DispatchQueue.main.async {
                        self.image = image
                    }
                }
                self.imageFetcher = nil
            })
            imageFetcher?.fetch(imageURL!)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLoad() {
        if image == nil {
            fetchImage()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
