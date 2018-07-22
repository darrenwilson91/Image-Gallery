//
//  GalleryChooserTableViewController.swift
//  Image Gallery
//
//  Created by Darren Wilson on 21/07/2018.
//  Copyright © 2018 Darren Wilson. All rights reserved.
//

import UIKit

class GalleryChooserTableViewController: UITableViewController, UITextFieldDelegate {
    
    private var galleries = [ImageGallery]()
    private var recentlyDeletedGalleries = [ImageGallery]()
    private var currentlyShownGallery: ImageGallery?

    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        galleries.append(ImageGallery())
        tableView.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return galleries.count
        } else if section == 1 {
            return recentlyDeletedGalleries.count
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Galleries"
        }
        else if section == 1 {
            return "Recently Deleted"
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "galleryTableCell", for: indexPath)
        
        if let galleryTableCell = cell as? GalleryTableViewCell {
            
            if indexPath.section == 0 {
                galleryTableCell.name = galleries[indexPath.item].name
                galleryTableCell.resignationHandler = { [weak self, unowned galleryTableCell, unowned tableView] in
                    if let indexPath = tableView.indexPath(for: galleryTableCell) {
                        self?.galleries[indexPath.item].name = galleryTableCell.name!
                    }
                }
            } else if indexPath.section == 1 {
                galleryTableCell.name = recentlyDeletedGalleries[indexPath.item].name
                galleryTableCell.resignationHandler = { [weak self, unowned galleryTableCell] in
                    if let indexPath = tableView.indexPath(for: galleryTableCell) {
                        self?.recentlyDeletedGalleries[indexPath.item].name = galleryTableCell.name!
                    }
                }
            }
            
            let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didDoubleTapCell(sender:)))
            doubleTapGestureRecognizer.numberOfTapsRequired = 2
            galleryTableCell.addGestureRecognizer(doubleTapGestureRecognizer)
        }

        return cell
    }
    
    @objc
    func didDoubleTapCell(sender: UITapGestureRecognizer) {
        if let cell = sender.view as? GalleryTableViewCell {
            cell.nameTextField.isEnabled = true
            cell.nameTextField.becomeFirstResponder()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            performSegue(withIdentifier: "showGallery", sender: indexPath)
        }
    }

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            if indexPath.section == 0 {
                tableView.performBatchUpdates({
                    recentlyDeletedGalleries.append(galleries[indexPath.item])
                    galleries.remove(at: indexPath.item)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
                }, completion: nil)
                if recentlyDeletedGalleries.last === currentlyShownGallery {
                    tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: UITableViewScrollPosition.top)
                }
            } else if indexPath.section == 1 {
                tableView.performBatchUpdates({
                    recentlyDeletedGalleries.remove(at: indexPath.item)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }, completion: nil)
            }
            
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if (indexPath.section == 0) {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 1 {
            var actions = [UIContextualAction]()
            let undeleteAction = UIContextualAction(style: .destructive, title: "Undelete") { (action, sourceView, completionHandler) in
                tableView.performBatchUpdates({
                    self.galleries.append(self.recentlyDeletedGalleries[indexPath.item])
                    self.recentlyDeletedGalleries.remove(at: indexPath.item)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    tableView.insertRows(at: [IndexPath(row: self.galleries.count - 1, section: 0)], with: .fade)
                    tableView.reloadData()
                }, completion: nil)
            }
            undeleteAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            actions.append(undeleteAction)
            let swipeConfig = UISwipeActionsConfiguration(actions: actions)
            
            return swipeConfig
        } else {
            return nil
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showGallery", let indexPath = sender as? IndexPath, let imageGalleryNavController = segue.destination as? UINavigationController, let imageGalleryViewController = imageGalleryNavController.viewControllers.first as? ImageGalleryViewController {
            imageGalleryViewController.imageGallery = galleries[indexPath.item]
            currentlyShownGallery = galleries[indexPath.item]
        }
    }

}
