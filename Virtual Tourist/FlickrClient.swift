//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Abdallah ElMenoufy on 8/7/15.
//  Copyright (c) 2015 Abdallah ElMenoufy. All rights reserved.
//

import Foundation

class FlickrClient {
    
    //MARK: - Shared Instance
    
    //Single line shared instance declaration as in http://krakendev.io/blog/the-right-way-to-write-a-singleton
    
    static let sharedInstance = FlickrClient()
    
    //MARK: - Properties
    
    var session: NSURLSession
    
    //MARK: - Initialiser
    
    private init() {
        
        session = NSURLSession.sharedSession()
    }
    
    
    //MARK: - GET method
    
    func GETMethod(parameters: [String : AnyObject],
        completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
            
            // Build the URL and URL request
            let urlString = Constants.BaseFlickrURL + FlickrClient.escapedParameters(parameters)
            var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            
            // Make the request
            let task = session.dataTaskWithRequest(request) {
                data, response, downloadError in
                
                // Parse the received data
                if let error = downloadError {
                    
                    let newError = FlickrClient.errorForData(data, response: response, error: error)
                    completionHandler(result: nil, error: newError)
                } else {
                    
                    FlickrClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
                }
            }
            
        task.resume()
    }
    
    
    func GETMethodForURLString(urlString: String,
        completionHandler: (result: NSData?, error: NSError?) -> Void) {
            
            // Create the request
            var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            
            // Make the request
            let task = session.dataTaskWithRequest(request) {
                data, response, downloadError in
                
                if let error = downloadError {
                    
                    let newError = FlickrClient.errorForData(data, response: response, error: error)
                    completionHandler(result: nil, error: newError)
                } else {
                    
                    completionHandler(result: data, error: nil)
                }
            }
            
            task.resume()
    }
    
    
// ====================================================================================================
    
    /* Helper function: Given a dictionary of parameters, convert it to a string for a url */
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }

    
    //Check to see if there is a received error, if not, return the original local error.
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if let parsedResult = NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments, error: nil) as? [String : AnyObject] {
            
            if let status = parsedResult[JSONResponseKeys.Status]  as? String,
                message = parsedResult[JSONResponseKeys.Message] as? String {
                    
                    if status == JSONResponseValues.Failure {
                        
                        let userInfo = [NSLocalizedDescriptionKey: message]
                        
                        return NSError(domain: "Virtual Tourist Error", code: 1, userInfo: userInfo)
                    }
            }
        }
        return error
    }
    
    //Parse the received JSON data and pass it to the completion handler.
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsingError: NSError?
        let parsedResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &parsingError)
        
        if let error = parsingError {
            
            completionHandler(result: nil, error: error)
        } else {
            
            completionHandler(result: parsedResult, error: nil)
        }
    }

    
    
}