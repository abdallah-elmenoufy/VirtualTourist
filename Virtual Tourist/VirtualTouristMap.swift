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
        return CoreDataStackManager.sharedInstance().managedObjectContext!
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
        
    }


    // Dropping a Pin will convert the tapped point to a coordinate, save it to CoreData and ...
    // TODO: - Add a network call to download flickr images in the background thread
    
    func dropPin(gestureRecognizer: UIGestureRecognizer) {
        
        // Extract the tapped point and convert it to a coordinate
        let tappedPoint: CGPoint = gestureRecognizer.locationInView(mapView)
        let touchMapPoint: CLLocationCoordinate2D = mapView.convertPoint(tappedPoint, toCoordinateFromView: mapView)
        
        // Add the tappedPin to the MapView and to CoreData
        if UIGestureRecognizerState.Began == gestureRecognizer.state {
            let pin = Pin(annotationLatitude: touchMapPoint.latitude, annotationLongitude: touchMapPoint.longitude, context: sharedContext)
            mapView.addAnnotation(pin)
            CoreDataStackManager.sharedInstance().saveContext()
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
            println("Error at fetching Pins \(error)")
        }
        
        return results as! [Pin]
    }

    
    // MARK: - MKMapViewDelegate
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        if deleteButton!.title == "Done" {
            
            let pin = view.annotation as! Pin
            sharedContext.deleteObject(pin)
            mapView.removeAnnotation(pin)
            
            CoreDataStackManager.sharedInstance().saveContext()
          
        }
    }
    
    
}

