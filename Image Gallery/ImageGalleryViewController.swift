//
//  ImageGalleryViewController.swift
//  Image Gallery
//
//  Created by Darren Wilson on 12/07/2018.
//  Copyright © 2018 Darren Wilson. All rights reserved.
//

import UIKit

class ImageGalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UICollectionViewDropDelegate, UICollectionViewDragDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var galleryCollectionView: UICollectionView! {
        didSet {
            galleryCollectionView.delegate = self
            galleryCollectionView.dataSource = self
            galleryCollectionView.dropDelegate = self
            galleryCollectionView.dragDelegate = self
            galleryCollectionView.allowsSelection = true
            
            let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(adjustCellWidth(byHandlingGestureRecognizedBy:)))
            galleryCollectionView.addGestureRecognizer(pinchGestureRecognizer)
        }
    }
    
    var imageGallery = ImageGallery()
    
    var galleryImageWidth: CGFloat = DEFAULT_GALLERY_IMAGE_WIDTH
    var imageFetcherForIndexPath = [IndexPath:ImageFetcher]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageGallery.imageCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageGalleryCell", for: indexPath)
        self.imageFetcherForIndexPath.removeValue(forKey: indexPath)
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.frame = cell.frame
        cell.backgroundView = activityIndicator
        activityIndicator.startAnimating()
        
        if let galleryCell = cell as? ImageGalleryCell {
            galleryCell.imageView.image = nil
            
            imageFetcherForIndexPath[indexPath] = ImageFetcher(handler: { (url, image) in
                DispatchQueue.main.async {
                    if self.imageGallery.imageURLs[indexPath.item] == url {
                        if let activityIndicator = galleryCell.backgroundView as? UIActivityIndicatorView {
                            activityIndicator.stopAnimating()
                        }
                        galleryCell.imageView.image = image
                    }
                    self.imageFetcherForIndexPath.removeValue(forKey: indexPath)
                }
            })
            
            imageFetcherForIndexPath[indexPath]?.fetch(imageGallery.imageURLs[indexPath.item])
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: galleryImageWidth, height: galleryImageWidth * imageGallery.imageAspectRatios[indexPath.item])
    }
    
    // Perform the drop
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        
        
        
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                // TODO: Handle dragging from within the gallery
                if let url = item.dragItem.localObject as? URL {
                    collectionView.performBatchUpdates({
                        imageGallery.imageURLs.remove(at: sourceIndexPath.item)
                        let removedAspectRatio = imageGallery.imageAspectRatios.remove(at: sourceIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        
                        imageGallery.imageURLs.insert(url, at: destinationIndexPath.item)
                        imageGallery.imageAspectRatios.insert(removedAspectRatio, at: destinationIndexPath.item)
                        collectionView.insertItems(at: [destinationIndexPath])
                    }, completion: nil)
                    
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            } else {
                let placeholderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "ImageGalleryCellLoading"))
                
                _ = item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    if let image = provider as? UIImage {
                        self.imageGallery.imageAspectRatios.insert(image.aspectRatio, at: destinationIndexPath.item)
                    }
                }
                        
                _ = item.dragItem.itemProvider.loadObject(ofClass: URL.self, completionHandler: { (provider, error) in
                    DispatchQueue.main.async {
                        if let url = provider {
                            placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                                self.imageGallery.imageURLs.insert(url, at: insertionIndexPath.item)
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
        if let image = (galleryCollectionView.cellForItem(at: indexPath) as? ImageGalleryCell)?.imageView.image {
            let url = imageGallery.imageURLs[indexPath.item]
            
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: url as NSURL))
            dragItem.itemProvider.registerObject(image, visibility: .all)
            dragItem.localObject = url as NSURL
            return [dragItem]
        }
        return []
    }
    
    @objc
    private func adjustCellWidth(byHandlingGestureRecognizedBy recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .changed, .ended:
            if !( (galleryImageWidth >= galleryCollectionView.frame.width * 0.8) && (recognizer.scale >= 1.0)
                || (galleryImageWidth <= galleryCollectionView.frame.width * 0.1) && (recognizer.scale <= 1.0)) {
                galleryImageWidth *= recognizer.scale
                recognizer.scale = 1.0
                galleryCollectionView.collectionViewLayout.invalidateLayout()
            }
        default: break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showImageDetail", sender: collectionView.cellForItem(at: indexPath))
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showImageDetail" {
            if let senderCell = sender as? ImageGalleryCell {
                if let imageDetailViewController = segue.destination as? ImageDetailViewController {
                    if let indexPath = galleryCollectionView.indexPath(for: senderCell) {
                        let imageUrl = imageGallery.imageURLs[indexPath.item]
                        
                        imageDetailViewController.imageURL = imageUrl
                    }
                }
            }
        }
    }

}

extension ImageGalleryViewController {
    static var DEFAULT_GALLERY_IMAGE_WIDTH: CGFloat {
        return 300
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
