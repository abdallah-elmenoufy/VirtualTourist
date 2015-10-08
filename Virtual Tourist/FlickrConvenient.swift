//
//  FlickrConvineince.swift
//  Virtual Tourist
//
//  Created by Abdallah ElMenoufy on 8/7/15.
//  Copyright (c) 2015 Abdallah ElMenoufy. All rights reserved.
//

import Foundation
import MapKit
import CoreData

extension FlickrClient {

    //MARK: - Convenience
    
    func downloadPhotosForPin(pin: Pin, completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        //If a pin has photos already, generate a random page from the available pages on Flickr and add it to the parameters
        // Initializing randomPage variable
        var randomPage: Int = 1
        
        if let numberOfPages = pin.numberOfPagesReturned {
            
            let numberOfPagesAsInt = numberOfPages as Int
             randomPage = Int((arc4random_uniform(UInt32(numberOfPagesAsInt)))) + 1 //Avoids returning 0 as a response.
            
        }
        
        //Declare parameters for the network call
        let parameters: [String : AnyObject] = [
            
            URLKeys.Method         : Methods.Search,
            URLKeys.APIKey         : Constants.FlickrAPIKey,
            URLKeys.DataFormat     : URLValues.JSONDataFormat,
            URLKeys.NoJSONCallback : 1,
            URLKeys.Latitude       : pin.coordinate.latitude,
            URLKeys.Longitude      : pin.coordinate.longitude,
            URLKeys.Extras         : URLValues.MediumPhotoURL,
            URLKeys.Page           : randomPage,
            URLKeys.PerPage        : 21
        ]
        
        //Make the call
        GETMethod(parameters, completionHandler: {
            results, error in
            
            if let error = error {
                
                completionHandler(success: false, error: error)
            } else {
                
                //If we get some photos...
                if let photosDictionary = results.valueForKey(JSONResponseKeys.Photos) as? [String: AnyObject],
                    photosArray = photosDictionary[JSONResponseKeys.Photo] as? [[String : AnyObject]],
                    numberOfPhotoPages = photosDictionary[JSONResponseKeys.Pages]     as? Int {
                        
                        //...save the number of pages returned to the Pin object...
                        pin.numberOfPagesReturned = numberOfPhotoPages
                        
                        //...extract the photo URL from each photo...
                        for photoDictionary in photosArray {
                            
                            let photoURLString = photoDictionary[URLValues.MediumPhotoURL] as! String
                            
                            //...create a new Photo managed object with it...
                            let newPhoto = Photo(photoURL: photoURLString, pin: pin, context: self.sharedContext)
                            
                            //...then attempt to get the image from the URL.
                            self.getImageForPhoto(newPhoto, completionHandler: {
                                success, error in
                                
                                //Save the context whatever happens, as errors are handled through the Photo object.
                                dispatch_async(dispatch_get_main_queue(), {
                                    CoreDataStackManager.sharedInstance.saveContext()
                                })
                            })
                        }
                        
                        completionHandler(success: true, error: nil)
                } else {
                    
                    completionHandler(success: false, error: NSError(domain: "downloadPhotosForPin", code: 0, userInfo: nil))
                }
            }
        })
    }
    
    func getImageForPhoto(photo: Photo, completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        let imageURLString = photo.photoURL
        
        //Make a network call with the received photo URL...
        GETMethodForURLString(imageURLString, completionHandler: {
            result, error in
            
            //...if error happens, save error message to the photo managed object.
            // This allows a placeholder image to be displayed instead of a black hole.
            if let error = error {
                
                photo.imageFilePath = "error"
                
                completionHandler(success: false, error: error)
            } else {
                
                //If we get a result...
                if let result = result {
                    
                    //...make a fileURL for it...
                    let fileName = imageURLString.lastPathComponent //Already includes ".jpg" suffix.
                    let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
                    let pathArray = [dirPath, fileName]
                    let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
                    
                    //...save it...
                    NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: result, attributes: nil)
                    
                    //...then update the Photo managed object with the file path.
                    photo.imageFilePath = fileURL.path
                    
                    completionHandler(success: true, error: nil)
                }
            }
        })
    }
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        
        return CoreDataStackManager.sharedInstance.managedObjectContext!
    }


}
