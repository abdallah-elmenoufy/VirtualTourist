//
//  VirtualTouristMap.swift
//  Virtual Tourist
//
//  Created by Abdallah ElMenoufy on 8/5/15.
//  Copyright (c) 2015 Abdallah ElMenoufy. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class VirtualTouristMap: UIViewController, MKMapViewDelegate {

    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tapToDeletePinsLabel: UILabel!
    
    var deleteButton: UIBarButtonItem?
    
    // Get a reference to the sharedContext, which is used by CoreData to Save, Update, and Fetch Pins
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add LongPressGestureRecognizer to allow dropping Pins
        var longPress = UILongPressGestureRecognizer(target: self, action: "dropPin:")
        longPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPress)
        
        // Set the mapView delegate to be (self)
        mapView.delegate = self
        
        // Load all pre-saved Pins from CoreData
        mapView.addAnnotations(fetchAllPins())
        
        // Hide the tapToDeletePinsLabel label
        tapToDeletePinsLabel.hidden = true
        
        // Set the Delete button to be the system-editButtonItem
        deleteButton = editButtonItem()
        navigationItem.rightBarButtonItem = deleteButton
        deleteButton?.action = "editButtonTapped"
        
        // Load the map to the last location before app-termination
        loadMapRegion()
        
    }
    
// ==================================================================================================
    
    // MARK: - Helper variables and functions 
    
    var lastPinDropped: Pin? = nil
    var pinToBeAdded: Pin? = nil

    // Dropping a Pin will convert the tapped point to a coordinate, save it to CoreData and make network call to flickr to get the associated photos with this pin coordinate
    func dropPin(gestureRecognizer: UIGestureRecognizer) {
        
        // Extract the tapped point and convert it to a coordinate
        let tappedPoint: CGPoint = gestureRecognizer.locationInView(mapView)
        let touchMapPoint: CLLocationCoordinate2D = mapView.convertPoint(tappedPoint, toCoordinateFromView: mapView)
        
        // Add the tappedPin to the MapView, ...
        switch gestureRecognizer.state {
            
            //...and use it to initialise a new Pin managed object. Store it for reuse.
        case .Began:
            pinToBeAdded = Pin(coordinate: touchMapPoint, context: sharedContext)
            mapView.addAnnotation(pinToBeAdded)
            
            //If the user drags the pin around, use KVO to update the location of the pin
            //and the coordinate property of the Pin object.
        case .Changed:
            pinToBeAdded!.willChangeValueForKey("coordinate")
            pinToBeAdded!.coordinate = touchMapPoint
            pinToBeAdded!.didChangeValueForKey("coordinate")
            
            //When the user drops the pin, store it for error handling, fetch the associated
            //photos and finally save it to Core Data.
        case .Ended:
            lastPinDropped = pinToBeAdded
            fetchPhotosForPin(pinToBeAdded!)
            CoreDataStackManager.sharedInstance.saveContext()
            
        default:
            return
        }
    }

    // Function to process the Edit/Done button related actions when tapped to delete Pins
    func editButtonTapped() {
        
        if editButtonItem().title == "Edit" {
            tapToDeletePinsLabel.hidden = false
            editButtonItem().title = "Done"
            
            // Shift the mapView up when tapPinLabel shows up
            mapView.frame.origin.y -= tapToDeletePinsLabel.frame.height
            
        } else if editButtonItem().title == "Done" {
            tapToDeletePinsLabel.hidden = true
            editButtonItem().title = "Edit"
            
            // Shift the mapView down again when tapPinLabel hides
            mapView.frame.origin.y += tapToDeletePinsLabel.frame.height
        }
    }

    // Function to fetchAllPins from CoreData when app re-launchs
    func fetchAllPins() -> [Pin] {
        
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        
        if error != nil {
            alertUserWithTitle("Error",
                message: "There was an error getting your early-saved Pins, close the app and try again",
                retry: false)
        }
        
        return results as! [Pin]
    }

    
    // Function to fetchAllPhotos for a selected Pin on the map
    func fetchPhotosForPin(pin: Pin) {
        
        FlickrClient.sharedInstance.downloadPhotosForPin(pin, completionHandler: {
            success, error in
            
            if success {
                
                //Save the new Photo objects to Core Data.
                dispatch_async(dispatch_get_main_queue(), {
                    CoreDataStackManager.sharedInstance.saveContext()
                })
            } else {
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.alertUserWithTitle("Error",
                        message: "There was an error downloading this Pin's pictures",
                        retry: true)
                })
            }
        })
    }

    
    //Function to create an alert and show it to the user
    func alertUserWithTitle(title: String, message: String, retry: Bool) {
        
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
                    
                    self.fetchPhotosForPin(self.lastPinDropped!)
            })
            alert.addAction(retryAction)
        }
        
        alert.addAction(okAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
// ==================================================================================================
    
    // MARK: - NSUserDefaults Constants, and methods
    
    // 1 - Constants: used to save the current map region to restore it when the app re-launch
    let CenterLatitudeKey     = "Center Latitude Key"
    let CenterLongitudeKey    = "Center Longitude Key"
    let SpanLatitudeDeltaKey  = "Span Latitude Delta Key"
    let SpanLongitudeDeltaKey = "Span Longitude Delta Key"
    
    
    // 2 - Methods: a) Save Map Region
    func saveMapRegion() {
        
        //The mapView region property is a struct containing 4 double values, saves each value individually to NSUserDefaults.
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.center.latitude, forKey: CenterLatitudeKey)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.center.longitude, forKey: CenterLongitudeKey)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.latitudeDelta, forKey: SpanLatitudeDeltaKey)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.longitudeDelta, forKey: SpanLongitudeDeltaKey)
    }

    // 2 - Methods: b) Reload the Map Region
    func loadMapRegion() {
        
        //Check the map 4 items into user defaults, if they exist then zoom map to old location.
        let centerLatitude = NSUserDefaults.standardUserDefaults().doubleForKey(CenterLatitudeKey)
        
        if centerLatitude != 0 {
            
            //Gather all the map items...
            let centreLongitude    = NSUserDefaults.standardUserDefaults().doubleForKey(CenterLongitudeKey)
            let spanLatitudeDelta  = NSUserDefaults.standardUserDefaults().doubleForKey(SpanLatitudeDeltaKey)
            let spanLongitudeDelta = NSUserDefaults.standardUserDefaults().doubleForKey(SpanLongitudeDeltaKey)
            
            let center = CLLocationCoordinate2DMake(centerLatitude, centreLongitude)
            let span = MKCoordinateSpanMake(spanLatitudeDelta, spanLongitudeDelta)
            
            //...into a region...
            let region = MKCoordinateRegionMake(center, span)
            
            //...and move the map back to where the user left off before terminate the app
            mapView.region = region
        }
    }

// ==================================================================================================
    
    // MARK: - MKMapViewDelegate
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        if deleteButton!.title == "Done" {
            
            let pin = view.annotation as! Pin
            sharedContext.deleteObject(pin)
            mapView.removeAnnotation(pin)
            
            CoreDataStackManager.sharedInstance.saveContext()
          
        } else {
            
            // Get the new View Controller
            let photoCVC = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoCollectionViewController") as! PhotoCollectionViewController
            
            // And the Pin
            let pin = view.annotation as! Pin
            
            // Pass the pin
            photoCVC.receivedPin = pin
            
            // Then make the segue
            self.navigationController?.pushViewController(photoCVC, animated: true)
        }

    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        //Use dequeued pin annotation view if available, otherwise create a new one
        if let annotation = annotation as? Pin {
            
            let identifier = "Pin"
            var view: MKPinAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
                
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = false
                view.animatesDrop = true
                view.draggable = false
            }
            
            return view
        }
        
        return nil
    }
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        
        //Save the map region as the user moves it around.
        saveMapRegion()
    }

}

