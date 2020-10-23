//
//  ViewController.swift
//  iOS-Example
//
//  Created by GG on 22/10/2020.
//

import UIKit
import ReverseGeocodingMap
import CoreLocation
import MapKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    lazy var map = ReverseGeocodingMap.create(delegate: self)
    @IBAction func show(_ sender: Any) {
        map.countdownValue = 1
        navigationController?.pushViewController(map, animated: true)
    }
}

extension ViewController: ReverseGeocodingMapDelegate {
    func geocodingComplete(_ res: Result<CLPlacemark, Error>) {
        print("🎃 \(res)")
    }
    
    func search() {
        
    }
    
    func didChoose(_ placemark: CLPlacemark) {
        
    }
}

