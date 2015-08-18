//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Abdallah ElMenoufy on 8/6/15.
//  Copyright (c) 2015 Abdallah ElMenoufy. All rights reserved.
//


import MapKit
import CoreData

@objc(Pin)

class Pin: NSManagedObject, MKAnnotation {
    
    // MARK: - Properties
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var numberOfPagesReturned: NSNumber?
    @NSManaged var photos: NSMutableOrderedSet
    
    var coordinate: CLLocationCoordinate2D {
        
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
        
        get {
            return CLLocationCoordinate2DMake(latitude, longitude)
        }
    }
    
    // MARK: - Initialisers
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        
        // Core Data
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.photos = NSMutableOrderedSet()
    }
    
}
