//
//  ImageGalleryViewController.swift
//  Image Gallery
//
//  Created by Darren Wilson on 12/07/2018.
//  Copyright © 2018 Darren Wilson. All rights reserved.
//

import UIKit

class ImageGalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UICollectionViewDropDelegate, UICollectionViewDragDelegate, UICollectionViewDelegateFlowLayout {

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
            galleryCollectionView.dragDelegate = self
        }
    }
    
    var galleryImageURLs = [URL]()
    var galleryImageAspectRatios = [CGFloat]()
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
        return galleryImageURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageGalleryCell", for: indexPath)
        
        if let galleryCell = cell as? ImageGalleryCell {
            imageFetcher = ImageFetcher(handler: { (url, image) in
                DispatchQueue.main.async {
                    if self.galleryImageURLs[indexPath.item] == url {
                        galleryCell.image.image = image
                    }
                }
            })
            
            imageFetcher?.fetch(galleryImageURLs[indexPath.item])
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: galleryImageWidth, height: galleryImageWidth * galleryImageAspectRatios[indexPath.item])
    }
    
    // Perform the drop
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        
        
        
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                // TODO: Handle dragging from within the gallery
                if let url = item.dragItem.localObject as? URL {
                    collectionView.performBatchUpdates({
                        galleryImageURLs.remove(at: sourceIndexPath.item)
                        let removedAspectRatio = galleryImageAspectRatios.remove(at: sourceIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        
                        galleryImageURLs.insert(url, at: destinationIndexPath.item)
                        galleryImageAspectRatios.insert(removedAspectRatio, at: destinationIndexPath.item)
                        collectionView.insertItems(at: [destinationIndexPath])
                    }, completion: nil)
                    
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            } else {
                let placeholderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "ImageGalleryCellLoading"))
                
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    if let image = provider as? UIImage {
                        self.galleryImageAspectRatios.insert(image.aspectRatio, at: destinationIndexPath.item)
                    }
                }
                        
                item.dragItem.itemProvider.loadObject(ofClass: URL.self, completionHandler: { (provider, error) in
                    DispatchQueue.main.async {
                        if let url = provider {
                            placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                                self.galleryImageURLs.insert(url, at: insertionIndexPath.item)
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
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItem(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItem(at: indexPath)
    }
    
    private func dragItem(at indexPath: IndexPath) -> [UIDragItem] {
        if let image = (galleryCollectionView.cellForItem(at: indexPath) as? ImageGalleryCell)?.image.image {
            let url = galleryImageURLs[indexPath.item]
            
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: url as NSURL))
            dragItem.itemProvider.registerObject(image, visibility: .all)
            dragItem.localObject = url as NSURL
            return [dragItem]
        }
        return []
    }
}

extension ImageGalleryViewController {
    static var DEFAULT_GALLERY_IMAGE_WIDTH: CGFloat {
        return 120
    }
}

extension UIImage {
    var aspectRatio: CGFloat {
        if size.width > 0 {
            return size.height / size.width
        } else {
            return 1.0
        }
    }
}
