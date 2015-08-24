//
//  PhotoCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Abdallah ElMenoufy on 8/22/15.
//  Copyright (c) 2015 Abdallah ElMenoufy. All rights reserved.
//

import CoreData
import MapKit
import UIKit

class PhotoCollectionViewController: UIViewController {
    
    //MARK: - Properties
    
    @IBOutlet weak var mapView:             MKMapView!
    @IBOutlet weak var collectionView:      UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImagesLabel:       UILabel!
    
    //Arrays to keep track of selected or updated collection view cells
    var selectedIndexes   = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths : [NSIndexPath]!
    var updatedIndexPaths : [NSIndexPath]!
    
    //Pin received from MapViewController
    var receivedPin: Pin!
    
    //MARK: Core Data convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext!
    }
    
    // fetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        //Create fetch request for photos which match the sent Pin.
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.receivedPin)
        fetchRequest.sortDescriptors = []
        
        //Create fetched results controller with the new fetch request.
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
        }()
    
    
    //MARK: - View methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //Set delegates, datasource for map and collection views and fetched results controller
        mapView.delegate = self
        mapView.userInteractionEnabled = false
        
        //Update mapView based on the user's pin
        mapView.addAnnotation(receivedPin)
        centerMapOnPin(receivedPin)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //Perform initial fetch
        var error: NSError?
        fetchedResultsController.performFetch(&error)
        
        if let error = error {
            
            alertUserWithTitle("Error",
                message: "Error getting data for the selected pin, try dropping another one!",
                retry: false)
        }
        
        //If there are no images associated with the pin, show label to user and disable newCollectionButton
        if fetchedResultsController.fetchedObjects?.count == 0 {
            
            noImagesLabel.hidden = false
            newCollectionButton.enabled = false
        }
    }
    
    override func viewDidLayoutSubviews() {
        
        //Layout the collectionView cells properly on the View
        let layout = UICollectionViewFlowLayout()
        
        layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        let width = (floor(self.collectionView.frame.size.width / 3)) - 7
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    
    //MARK: - IBAction methods
    
    @IBAction func newCollectionButtonTapped(sender: UIButton) {
        
        //If no photos are selected...
        if selectedIndexes.count == 0 {
            
            //get a new set of images.
            getNewPhotoSet()
            
        } else {
            
            //If some photos are selected...
            for index in selectedIndexes {
                
                //...delete them from the context...
                sharedContext.deleteObject(fetchedResultsController.objectAtIndexPath(index) as! Photo)
            }
            
            //...remove the deleted image indexes and update the button...
            selectedIndexes = []
            updateNewCollectionButton()
            
            //...and save.
            CoreDataStackManager.sharedInstance.saveContext()
        }
    }
    
    //MARK: - Helper functions
    
    func configureCell(cell: PhotoCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        
        //If the user has selected a cell, grey it out...
        if let index = find(selectedIndexes, indexPath) {
            
            UIView.animateWithDuration(0.1,
                animations: {
                    cell.imageView.alpha = 0.5
            })
        } else {
            
            //...otherwise show it clearly.
            UIView.animateWithDuration(0.1,
                animations: {
                    cell.imageView.alpha = 1.0
            })
        }
    }
    
    func centerMapOnPin(pin: Pin) {
        
        //Center the map around the user's pin at a moderate distance.
        let region = MKCoordinateRegionMakeWithDistance(pin.coordinate, 20000, 20000)
        mapView.region = region
    }
    
    func updateNewCollectionButton() {
        
        //Change the "New Collection" button's title depending on whether the user has selected any cells.
        if selectedIndexes.count > 0 {
            
            newCollectionButton.setTitle("Delete Selected Images", forState: .Normal)
        } else {
            
            newCollectionButton.setTitle("New Collection", forState: .Normal)
        }
    }
    
    func retryImageDownloadForPhoto(photo: Photo) {
        
        //Get image for photo object, and save the context
        FlickrClient.sharedInstance.getImageForPhoto(photo, completionHandler: {
            success, error in
            
            dispatch_async(dispatch_get_main_queue(), {
                CoreDataStackManager.sharedInstance.saveContext()
            })
        })
    }
    
    func getNewPhotoSet() {
        
        //Disable button to prevent spamming.
        newCollectionButton.enabled = false
        
        //Delete the existing photos...
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            
            sharedContext.deleteObject(photo)
        }
        
        //...save the context...
        CoreDataStackManager.sharedInstance.saveContext()
        
        //...and get a new set of photos from Flickr.
        FlickrClient.sharedInstance.downloadPhotosForPin(receivedPin, completionHandler: {
            success, error in
            
            if success {
                
                //Save the context and enable the newCollectionButton
                dispatch_async(dispatch_get_main_queue(), {
                    CoreDataStackManager.sharedInstance.saveContext()
                    self.newCollectionButton.enabled = true
                })
            } else {
                
                //Give the user an alert and retry option, renable the newCollectionButton in case user doesn't retry
                dispatch_async(dispatch_get_main_queue(), {
                    self.alertUserWithTitle("Error", message: error!.localizedDescription, retry: true)
                    self.newCollectionButton.enabled = true
                })
            }
        })
    }
    
    func alertUserWithTitle(title: String, message: String, retry: Bool) {
        
        //Create alert and show it to user.
        let alert = UIAlertController(title: title,
            message: message,
            preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK",
            style: .Default,
            handler: nil)
        
        if retry {
            
            let retryAction = UIAlertAction(title: "Retry",
                style: .Destructive,
                handler: {
                    action in
                    
                    self.getNewPhotoSet()
            })
            alert.addAction(retryAction)
        }
        
        alert.addAction(okAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

//MARK: - MKMapViewDelegate

extension PhotoCollectionViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        //Use dequeued pin annotation view if available, otherwise create a new one.
        if let annotation = annotation as? Pin {
            
            let identifier = "Pin"
            var view: MKPinAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
                
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.enabled = false
                view.animatesDrop = true
            }
            
            return view
        }
        
        return nil
    }
}

//MARK: - UICollectionViewDelegate

extension PhotoCollectionViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        //Disallow selection if the cell is waiting for its image to appear.
        if cell.activityIndicatorView.isAnimating() {
            
            return false
        }
        
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        //Get cell and photo associated with the indexPath.
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // If photo image failed to download before, retry download here.
        if photo.imageFilePath == "error" {
            
            //UI changes to indicate activity.
            cell.activityIndicatorView.startAnimating()
            cell.imageView.alpha = 0.0
            cell.imageView.image = nil
            
            retryImageDownloadForPhoto(photo)
            return
        }
        
        //If the user touches a cell, add or remove it from the selectedIndexes array...
        if let index = find(selectedIndexes, indexPath) {
            
            selectedIndexes.removeAtIndex(index)
        } else {
            
            selectedIndexes.append(indexPath)
        }
        
        //...reconfigure the cell...
        configureCell(cell, atIndexPath: indexPath)
        
        //...and update the newCollectionButton.
        updateNewCollectionButton()
    }
}

//MARK: - UICollectionViewDataSource

extension PhotoCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        //Try to get section info from the fetched results controller...
        if let sectionInfo = self.fetchedResultsController.sections?[section] as? NSFetchedResultsSectionInfo {
            
            //...and return the number of items in the section...
            return sectionInfo.numberOfObjects
        }
        
        //...else return default number.
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //Get a new or dequeued cell...
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        //...if there is an image, update the cell appropriately...
        if photo.image != nil {
            
            cell.activityIndicatorView.stopAnimating()
            cell.imageView.alpha = 0.0
            cell.imageView.image = photo.image
            
            UIView.animateWithDuration(0.2,
                animations: { cell.imageView.alpha = 1.0 })
        }
        
        //...modify it if the user has selected it...
        self.configureCell(cell, atIndexPath: indexPath)
        
        //...and return it.
        return cell
    }
}

//MARK: - NSFetchedResultsControllerDelegate

extension PhotoCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        //Prepare for changed content from Core Data
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths  = [NSIndexPath]()
        updatedIndexPaths  = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        //Add the indexPath of the changed objects to the appropriate array, depending on the type of change
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            
        case .Update:
            updatedIndexPaths.append(indexPath!)
            
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        //Check to make sure UI elements are correctly displayed.
        if controller.fetchedObjects?.count > 0 {
            
            noImagesLabel.hidden = true
            newCollectionButton.enabled = true
        }
        
        //Make the relevant updates to the collectionView once Core Data has finished its changes.
        collectionView.performBatchUpdates({
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
}

