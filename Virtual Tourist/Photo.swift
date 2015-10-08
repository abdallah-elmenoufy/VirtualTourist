//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Abdallah ElMenoufy on 8/22/15.
//  Copyright (c) 2015 Abdallah ElMenoufy. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Photo)

class Photo: NSManagedObject {
    
    //MARK: - Properties
    
    @NSManaged var photoURL: String
    @NSManaged var imageFilePath: String?
    @NSManaged var pin: Pin
    
    var image: UIImage? {
        
        if let imageFilePath = imageFilePath {
            
            // Check to see if there's an error downloading the images for each Pin
            if imageFilePath == "error" {
                
                return UIImage(named: "Ooops.jpg")
            }
            
            // Get the filePath
            let fileName = imageFilePath.lastPathComponent
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
            let pathArray = [dirPath, fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            return UIImage(contentsOfFile: fileURL.path!)
        }
        return nil
    }
    
    //MARK: - Initialisers
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(photoURL: String, pin: Pin, context: NSManagedObjectContext) {
        
        //Core Data
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.photoURL = photoURL
        self.pin = pin
    }
    
    //MARK: - Overrides
    
    override func prepareForDeletion() {
        
        //Delete the associated image file when the Photo managed object is deleted
        if let fileName = imageFilePath?.lastPathComponent {
            
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
            let pathArray = [dirPath, fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            do {
                try NSFileManager.defaultManager().removeItemAtURL(fileURL)
            } catch _ {
            }
        }
    }
    
}

/* Added extension for String struct to get the lastPathComponent as a workaround for non-existance in Swift 2.0
Reference are here: https://forums.developer.apple.com/thread/13580 */

extension String {
    
    var lastPathComponent: String {
        
        get {
            return (self as NSString).lastPathComponent
        }
    }
}
