//
//  VirtualTouristMap.swift
//  Virtual Tourist
//
//  Created by Abdallah ElMenoufy on 8/5/15.
//  Copyright (c) 2015 Abdallah ElMenoufy. All rights reserved.
//

import UIKit
import MapKit

class VirtualTouristMap: UIViewController, MKMapViewDelegate {

    // Declearing the mapView outlet
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the mapView delegate to be (self)
        mapView.delegate = self
    }




}

