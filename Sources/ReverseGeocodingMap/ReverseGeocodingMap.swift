import MapKit
import UIKit
import HGCircularSlider
import CoreLocation
import LocationExtension
import Contacts

public class ReverseGeocodingMap: UIViewController {
    public static func create() -> ReverseGeocodingMap {
        return UIStoryboard(name: "Map", bundle: .module).instantiateInitialViewController() as! ReverseGeocodingMap
    }
    
    @IBOutlet weak var map: MKMapView!  {
        didSet {
            map.delegate = self
        }
    }
    @IBOutlet weak var centerImage: UIImageView!  {
        didSet {
            centerImage.isUserInteractionEnabled = false
        }
    }

    @IBOutlet weak var searchLoader: UIActivityIndicatorView!
    @IBOutlet weak var locatioButton: UIButton!  {
        didSet {
            locatioButton.layer.cornerRadius = 5.0
        }
    }
    @IBOutlet weak var countdown: CircularSlider!  {
        didSet {
            countdown.minimumValue = 0.0
            countdown.maximumValue = 1.0
            countdown.isUserInteractionEnabled = false
        }
    }


    public var geocodingCompletion:  ((Result<CLPlacemark, Error>) -> Void)?
    public var tintColor: UIColor = #colorLiteral(red: 0.8602173328, green: 0, blue: 0.1972838044, alpha: 1)  {
        didSet {
            guard locatioButton != nil else { return }
            locatioButton.tintColor = tintColor
        }
    }
    public var showLocationButton: Bool = true  {
        didSet {
            guard locatioButton != nil else { return }
            locatioButton.isHidden = showLocationButton == false
        }
    }
    public var showCalloutOnCompletion: Bool = true
    public var showProgressView: Bool = true  {
        didSet {
            guard countdown != nil else { return }
            countdown.isHidden = showProgressView == false
        }
    }
    public var countdownValue: CGFloat = 2
    
    @IBAction func centerOnUser() {
        map.setCenter(map.userLocation.coordinate, animated: true)
    }
    
    let locationManager = CLLocationManager()
    
    fileprivate func checkAuthorization() {
        locationManager.delegate = self
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: map.showsUserLocation = true
        default: locatioButton.isHidden = true
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        checkAuthorization()
        countdown.isHidden = true
        locatioButton.tintColor = tintColor
        centerImage.tintColor = tintColor
        countdown.trackFillColor = tintColor
    }
    
    var countdownTimer: Timer?
    private func loadTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
            guard self?.countdown.endPointValue ?? 0 < 1 else {
                timer.invalidate()
                if self?.searchComplete ?? true == false {
                    self?.searchLoader.isHidden = false
                }
                self?.countdown.isHidden = true
                self?.centerImage.isHidden = true
                if let placemark = self?.placemark {
                    self?.showAnnotation(placemark)
                }
                return
            }
            self?.countdown.endPointValue += 0.01 / (self?.countdownValue ?? 1)
        }
        RunLoop.main.add(timer, forMode: .default)
        countdownTimer = timer
    }
    
    
    deinit {
        print("💀 DEINIT \(URL(fileURLWithPath: #file).lastPathComponent)")
        countdownTimer?.invalidate()
    }
    
    private func startCountdown() {
        guard showProgressView == true else { return }
        countdown.isHidden = false
        countdown.endPointValue = 0
        loadTimer()
        searchAddressForCurrentLocation()
    }
    
    func stopTimer(hideProgress: Bool = true) {
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdown.isHidden = hideProgress
        searchLoader.isHidden = true
    }
    
    let geocoder = CLGeocoder()
    var searchComplete: Bool = false  {
        didSet {
            if searchComplete == true {
                searchLoader.isHidden = true
            }
        }
    }

    var placemark: CLPlacemark?
    func searchAddressForCurrentLocation() {
        geocoder.reverseGeocodeLocation(map.centerCoordinate.asLocation) { [weak self] placemarks, error in
            guard let self = self else { return }
            self.searchComplete = true
            
            guard error == nil,
                  let placemark = placemarks?.first else {
                self.geocodingCompletion?(Result.failure(error!))
                return
            }
            print("\(placemark)")
            self.geocodingCompletion?(.success(placemark))
            
            if self.showCalloutOnCompletion {
                self.placemark = placemark
            }
        }
    }
    
    func showAnnotation(_ placemark: CLPlacemark) {
        map.removeAnnotations(map.annotations)
        let annotation = PlaceAnnotation(placemark: placemark)
        map.addAnnotation(annotation)
        map.selectAnnotation(annotation, animated: true)
    }
}

class PlaceAnnotation:  NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(placemark: CLPlacemark) {
        coordinate = placemark.location?.coordinate ?? kCLLocationCoordinate2DInvalid
        title = placemark.formattedAddress
    }
}

extension CLPlacemark {
    var formattedAddress: String? {
        guard let postalAddress = postalAddress else {
            return nil
        }
        let formatter = CNPostalAddressFormatter()
        return formatter.string(from: postalAddress)
    }
}

extension ReverseGeocodingMap: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            map.showsUserLocation = true
            locatioButton.isHidden = false
            
        default:
            map.showsUserLocation = false
            locatioButton.isHidden = true
        }
    }
}

extension ReverseGeocodingMap: MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        stopTimer()
        centerImage.isHidden = false
        map.removeAnnotations(map.annotations)
        geocoder.cancelGeocode()
    }
    
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        startCountdown()
    }
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "place")
        view.markerTintColor = tintColor
        return view
    }
}
