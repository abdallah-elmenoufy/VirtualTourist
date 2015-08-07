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
    
    // Manage latitude and longitude properties
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    
    
    // Standard CoreData init(s)
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // Class initializer with CoreData
    init(annotationLatitude: Double, annotationLongitude: Double, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        latitude = NSNumber(double: annotationLatitude)
        longitude = NSNumber(double: annotationLongitude)
        
    }
    
    // MKAnnotation Protocol
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude as! Double, longitude: longitude as! Double)
    }
    
}
