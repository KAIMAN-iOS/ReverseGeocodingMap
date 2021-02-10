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
import ATAConfiguration
import Ampersand
import ActionButton

class Configuration: ATAConfiguration {
    var logo: UIImage? { nil }
    var palette: Palettable { Palette() }
}

class Palette: Palettable {
    var primary: UIColor { #colorLiteral(red: 0.8604696393, green: 0, blue: 0.1966537535, alpha: 1) }
    var secondary: UIColor { #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1) }
    var mainTexts: UIColor { #colorLiteral(red: 0.1879811585, green: 0.1879865527, blue: 0.1879836619, alpha: 1) }
    var secondaryTexts: UIColor { #colorLiteral(red: 0.3137255013, green: 0.4039215744, blue: 0.5333333611, alpha: 1) }
    var textOnPrimary: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    var inactive: UIColor { #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1) }
    var placeholder: UIColor { #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1) }
    var lightGray: UIColor { #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1) }
}
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let configurationURL = Bundle.main.url(forResource: "Poppins", withExtension: "json")!
        UIFont.registerApplicationFont(withConfigurationAt: configurationURL)
        ActionButton.primaryColor = #colorLiteral(red: 0.8604696393, green: 0, blue: 0.1966537535, alpha: 1)
    }

    lazy var map = ReverseGeocodingMap.create(delegate: self, conf: Configuration())
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

