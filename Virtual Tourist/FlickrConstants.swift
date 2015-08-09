//
//  FlickrConstants.swift
//  Virtual Tourist
//
//  Created by Abdallah ElMenoufy on 8/7/15.
//  Copyright (c) 2015 Abdallah ElMenoufy. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    // Flikcr search method constants, put into separate extension file, into structs for proper coding style
    struct Constants {
    
        static let Apikey = "ca42f25535cc225439931816a770217d"
        static let BaseSecureUrl = "https://api.flickr.com/services/rest/"
        static let PhotoSearchMethod = "flickr.photos.search"
        static let Extras = "url_m"
        static let SafeSearch = "1"
        static let DataFormat = "json"
        static let NoJsonCallBack = "1"
        static let BoundingBoxHalfWidth = 1.0
        static let BoundingBoxHalfHieght = 1.0
        static let LatMin = -90.0
        static let LatMax = 90.0
        static let LonMin = -180.0
        static let LonMax = 180.0
        
    }
    
    
}