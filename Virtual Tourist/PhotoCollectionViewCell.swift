//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Abdallah ElMenoufy on 8/22/15.
//  Copyright (c) 2015 Abdallah ElMenoufy. All rights reserved.
//

import Foundation
import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    //MARK: - Properties
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
        
        if imageView.image == nil {
            
            activityIndicatorView.startAnimating()
        }
    }
}
