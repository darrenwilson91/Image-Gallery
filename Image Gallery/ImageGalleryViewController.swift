//
//  ImageGalleryViewController.swift
//  Image Gallery
//
//  Created by Darren Wilson on 12/07/2018.
//  Copyright © 2018 Darren Wilson. All rights reserved.
//

import UIKit

class ImageGalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UICollectionViewDropDelegate, UICollectionViewDelegateFlowLayout {


    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
        }
    }
    
    @IBOutlet weak var galleryCollectionView: UICollectionView! {
        didSet {
            galleryCollectionView.delegate = self
            galleryCollectionView.dataSource = self
            galleryCollectionView.dropDelegate = self
        }
    }
    
    var galleryImages = [(URL, Double)]()
    var galleryImageWidth: CGFloat = DEFAULT_GALLERY_IMAGE_WIDTH
    var imageFetcher: ImageFetcher?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = galleryCollectionView.frame.size
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return galleryImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageGalleryCell", for: indexPath)
        
        if let galleryCell = cell as? ImageGalleryCell {
            imageFetcher = ImageFetcher(handler: { (url, image) in
                DispatchQueue.main.async {
                    if self.galleryImages[indexPath.item].0 == url {
                        galleryCell.image.image = image
                    }
                }
            })
            
            imageFetcher?.fetch(galleryImages[indexPath.item].0)
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: galleryImageWidth, height: galleryImageWidth)
    }
    
    // Perform the drop
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        
        
        
        for item in coordinator.items {
            let placeholderContext = coordinator.drop(coordinator.items[0].dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "ImageGalleryCellLoading"))
            
            if let sourceIndexPath = item.sourceIndexPath {
                // TODO: Handle dragging from within the gallery
                collectionView.performBatchUpdates({
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                }, completion: nil)
            } else {
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    if let image = provider as? UIImage {
                        //TODO: Calculate and store the image aspect ratio
                    }
                }
                        
                item.dragItem.itemProvider.loadObject(ofClass: URL.self, completionHandler: { (provider, error) in
                    DispatchQueue.main.async {
                        if let url = provider {
                            placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                                self.galleryImages.insert((url, 1.0), at: insertionIndexPath.item)
                            })
                        } else {
                            placeholderContext.deletePlaceholder()
                        }
                    }
                })
            }
        }
    }

    // Check to see if we can accept this type of drop
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: UIImage.self) && session.canLoadObjects(ofClass: NSURL.self)
    }

    // Tell what to do with the drop (copy or move)
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        // TODO: When implementing drag within the gallery to rearrange will need to add logic here to allow .move operation
        if session.localDragSession != nil {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
        }
    }
}

extension ImageGalleryViewController {
    static var DEFAULT_GALLERY_IMAGE_WIDTH: CGFloat {
        return 120
    }
}
