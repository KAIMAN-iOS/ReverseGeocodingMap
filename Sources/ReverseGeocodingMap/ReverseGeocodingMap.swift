import MapKit
import UIKit
import HGCircularSlider
import CoreLocation
import LocationExtension
import Contacts
import UIViewExtension
import LabelExtension
import FontExtension
import ActionButton
import ATAConfiguration
import SwiftLocation

public protocol ReverseGeocodingMapDelegate: class {
    func geocodingComplete(_: Result<CLPlacemark, Error>)
    func search()
    func didChoose(_ placemark: CLPlacemark)
}

public class ReverseGeocodingMap: UIViewController {
    public var placemarkIcon: UIImage = UIImage(named: "map center", in: .module, compatibleWith: nil)!  {
        didSet {
            guard centerImage != nil else { return }
            centerImage.image = placemarkIcon
        }
    }

    static var configuration: ATAConfiguration!
    public static func create(delegate: ReverseGeocodingMapDelegate, centerCoordinates: CLLocationCoordinate2D? = nil, conf: ATAConfiguration) -> ReverseGeocodingMap {
        ReverseGeocodingMap.configuration = conf
        let ctrl = UIStoryboard(name: "Map", bundle: .module).instantiateInitialViewController() as! ReverseGeocodingMap
        ctrl.delegate = delegate
        ctrl.centerCoordinates = centerCoordinates
        return ctrl
    }
    weak var delegate: ReverseGeocodingMapDelegate!
    public var centerCoordinates: CLLocationCoordinate2D?  {
        didSet {
            guard let coord = centerCoordinates, map != nil else { return }
            map.setCenter(coord, animated: false)
        }
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
    @IBOutlet weak var searchLoader: UIActivityIndicatorView!  {
        didSet {
            searchLoader.isHidden = true
        }
    }

    @IBOutlet weak var locatioButton: UIButton!  {
        didSet {
            locatioButton.backgroundColor = ReverseGeocodingMap.configuration.palette.background
            locatioButton.addShadow()
        }
    }
    @IBOutlet weak var card: UIView!
    @IBOutlet weak var chooseDestinationLabel: UILabel!  {
        didSet {
            chooseDestinationLabel.set(text: NSLocalizedString("Choose destination", bundle: .module, comment: "Choose destination"), for: .title3, textColor: #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1))
        }
    }
    @IBOutlet weak var validDestinationLabel: UILabel! {
        didSet {
            validDestinationLabel.set(text: NSLocalizedString("Enter valid destination", bundle: .module, comment: "Choose destination"), for: .body, textColor: #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1))
        }
    }
    @IBOutlet weak var validDestinationButton: ActionButton!  {
        didSet {
            validDestinationButton.actionButtonType = .primary
            validDestinationButton.setTitle(NSLocalizedString("set destination", bundle: .module, comment: "set destination").uppercased(), for: .normal)
        }
    }

    public var tintColor: UIColor = ReverseGeocodingMap.configuration.palette.primary  {
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
    public var countdownValue: CGFloat = 2
    public var showSearchButton: Bool = true
    
    @IBAction func centerOnUser() {
        zoomOnUser()
    }
    
    @IBAction func validatePlacemark() {
        guard let placemark = placemark else { return }
        delegate.didChoose(placemark)
    }
    
    let locationManager = CLLocationManager()
    fileprivate func checkAuthorization() {
        locationManager.delegate = self
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: locatioButton.isHidden = false
        default: locatioButton.isHidden = true
        }
        map.showsUserLocation = false
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        card.round(corners: [.topLeft, .topRight], radius: 20.0)
        card.addShadow(roundCorners: false, shadowOffset: CGSize(width: -5, height: 0))
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        centerImage.image = placemarkIcon
        checkAuthorization()
        handleSearch()
        customize()
        
        if let coord = centerCoordinates {
            map.centerCoordinate = coord
        }
        
        locatioButton.tintColor = tintColor
        centerImage.tintColor = tintColor
    }
    
    internal func zoomOnUser(location: CLLocationCoordinate2D? = nil) {
        guard CLLocationManager.authorizationStatus() == .authorizedWhenInUse else { return }
        let coordinates = location ?? (SwiftLocation.lastKnownGPSLocation?.coordinate ?? map.userLocation.coordinate)
        if CLLocationCoordinate2DIsValid(coordinates) {
            map.setRegion(MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)), animated: true)
        }
    }
    
    func customize() {
    }
    
    func handleSearch() {
        if showSearchButton {
            let button = UIBarButtonItem(image: UIImage(named: "search", in: .module, compatibleWith: nil), style: .plain, target: self, action: #selector(search))
            navigationItem.rightBarButtonItem = button
        }
    }
    
    @objc func search() {
        delegate.search()
    }
    
    deinit {
        print("💀 DEINIT \(URL(fileURLWithPath: #file).lastPathComponent)")
    }
    
    private func startCountdown() {
        searchAddressForCurrentLocation()
    }
    
    let geocoder = CLGeocoder()
    var searchComplete: Bool = false
    var placemark: CLPlacemark?  {
        didSet {
            validDestinationButton.isEnabled = placemark?.inlandWater?.isEmpty ?? true == true && placemark?.ocean?.isEmpty ?? true == true
            guard let place = placemark,
                  place.formattedAddress?.isEmpty ?? true == false  else {
                validDestinationLabel.set(text: NSLocalizedString("Enter valid destination", bundle: .module, comment: "Choose destination"),
                                          for: .body,
                                          textColor: ReverseGeocodingMap.configuration.palette.mainTexts)
                return
            }
            validDestinationLabel.set(text: place.formattedAddress, for: .body, fontScale: 0.8, textColor: ReverseGeocodingMap.configuration.palette.secondaryTexts)
        }
    }

    func searchAddressForCurrentLocation() {
        geocoder.reverseGeocodeLocation(map.centerCoordinate.asLocation) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            guard error == nil,
                  let placemark = placemarks?.first else {
                self.delegate.geocodingComplete(Result.failure(error!))
                return
            }
            self.delegate.geocodingComplete(.success(placemark))
            self.placemark = placemark
            self.searchComplete = true
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
    }
}

extension CLPlacemark {
    var formattedAddress: String? {
        guard let postalAddress = postalAddress else {
            return nil
        }
        let formatter = CNPostalAddressFormatter()
        return formatter.string(from: postalAddress).replacingOccurrences(of: "\n", with: ", ")
    }
}

extension ReverseGeocodingMap: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            zoomOnUser()
            locatioButton.isHidden = false
            
        default:
            locatioButton.isHidden = true
        }
    }
}

extension ReverseGeocodingMap: MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
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
