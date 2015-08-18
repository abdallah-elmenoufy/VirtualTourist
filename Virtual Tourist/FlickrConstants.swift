//
//  FlickrConstants.swift
//  Virtual Tourist
//
//  Created by Abdallah ElMenoufy on 8/7/15.
//  Copyright (c) 2015 Abdallah ElMenoufy. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    //MARK: - Constants
    
    struct Constants {
        
        //MARK: API Keys
        static let FlickrAPIKey  = "ca42f25535cc225439931816a770217d"
        
        //MARK: URLs
        static let BaseFlickrURL = "https://api.flickr.com/services/rest/"
    }
    
    //MARK: - Methods
    
    struct Methods {
        
        static let Search = "flickr.photos.search"
    }
    
    //MARK: - URL Keys
    
    struct URLKeys {
        
        static let APIKey         = "api_key"
        static let BoundingBox    = "bbox"
        static let DataFormat     = "format"
        static let Extras         = "extras"
        static let Latitude       = "lat"
        static let Longitude      = "lon"
        static let Method         = "method"
        static let NoJSONCallback = "nojsoncallback"
        static let Page           = "page"
        static let PerPage        = "per_page"
    }
    
    //MARK: - URL Values
    
    struct URLValues {
        
        static let JSONDataFormat = "json"
        static let MediumPhotoURL = "url_m"
    }
    
    //MARK: - JSON Response Keys
    
    struct JSONResponseKeys {
        
        static let Status  = "stat"
        static let Code    = "code"
        static let Message = "message"
        static let Pages   = "pages"
        static let Photos  = "photos"
        static let Photo   = "photo"
    }
    
    //MARK: - JSON Response Values
    
    struct JSONResponseValues {
        
        static let Failure = "fail"
        static let Success = "ok"
    }
    
}