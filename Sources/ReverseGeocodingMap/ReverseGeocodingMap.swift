import MapKit
import UIKit

class ReverseGeocodingMap: UIViewController {
    @IBOutlet weak var map: MKMapView!  {
        didSet {
            map.delegate = self
        }
    }

    @IBOutlet weak var centerImage: UIImageView!
}

extension ReverseGeocodingMap: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
    }
}
