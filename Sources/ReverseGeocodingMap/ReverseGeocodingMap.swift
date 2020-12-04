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

public protocol ReverseGeocodingMapDelegate: class {
    func geocodingComplete(_: Result<CLPlacemark, Error>)
    func search()
    func didChoose(_ placemark: CLPlacemark)
}

public class ReverseGeocodingMap: UIViewController {
    static var configuration: ATAConfiguration!
    public static func create(delegate: ReverseGeocodingMapDelegate, centerCoordinates: CLLocationCoordinate2D? = nil, conf: ATAConfiguration) -> ReverseGeocodingMap {
        ReverseGeocodingMap.configuration = conf
        let ctrl = UIStoryboard(name: "Map", bundle: .module).instantiateInitialViewController() as! ReverseGeocodingMap
        ctrl.delegate = delegate
        ctrl.centerCoordinates = centerCoordinates
        return ctrl
    }
    weak var delegate: ReverseGeocodingMapDelegate!
    var centerCoordinates: CLLocationCoordinate2D?
    
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
    @IBOutlet weak var card: UIView!

    @IBOutlet weak var chooseDestinationLabel: UILabel!  {
        didSet {
            chooseDestinationLabel.set(text: NSLocalizedString("Choose destination", bundle: .module, comment: "Choose destination"), for: .title2, textColor: #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1))
        }
    }

    @IBOutlet weak var validDestinationLabel: UILabel! {
        didSet {
            validDestinationLabel.set(text: NSLocalizedString("Enter valid destination", bundle: .module, comment: "Choose destination"), for: .footnote, textColor: #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1))
        }
    }

    @IBOutlet weak var validDestinationButton: ActionButton!  {
        didSet {
            validDestinationButton.actionButtonType = .primary
            validDestinationButton.layer.cornerRadius = 5.0
            validDestinationButton.setTitle(NSLocalizedString("set destination", bundle: .module, comment: "set destination").uppercased(), for: .normal)
            validDestinationButton.shape = .rounded(value: 5.0)
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
    public var showProgressView: Bool = true  {
        didSet {
            guard countdown != nil else { return }
            countdown.isHidden = showProgressView == false
        }
    }
    public var countdownValue: CGFloat = 2
    public var showSearchButton: Bool = true
    
    @IBAction func centerOnUser() {
        map.setCenter(map.userLocation.coordinate, animated: true)
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
        checkAuthorization()
        handleSearch()
        customize()
        
        if let coord = centerCoordinates {
            map.centerCoordinate = coord
        }
        
        countdown.isHidden = true
        locatioButton.tintColor = tintColor
        centerImage.tintColor = tintColor
        countdown.trackFillColor = tintColor
    }
    
    func customize() {
        ActionButton.primaryColor = ReverseGeocodingMap.configuration.palette.primary
        ActionButton.loadingColor = ReverseGeocodingMap.configuration.palette.primary.withAlphaComponent(0.7)
        ActionButton.separatorColor = ReverseGeocodingMap.configuration.palette.inactive
        ActionButton.mainTextsColor = ReverseGeocodingMap.configuration.palette.mainTexts
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
    
    var countdownTimer: Timer?
    private func loadTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
            guard self?.countdown.endPointValue ?? 0 < 1 else {
                timer.invalidate()
                if self?.searchComplete ?? true == false {
                    self?.searchLoader.isHidden = false
                }
                guard let placemark = self?.placemark else { return }
                self?.countdown.isHidden = true
                self?.centerImage.isHidden = true
                if self?.showCalloutOnCompletion ?? false == true {
                    self?.showAnnotation(placemark)
                }
                if placemark.name?.isEmpty ?? true == false {
                    
                } else {
                    
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
            stopTimer()
        }
    }

    var placemark: CLPlacemark?  {
        didSet {
            validDestinationButton.isEnabled = placemark?.formattedAddress?.isEmpty ?? true == false
            guard let place = placemark,
                  place.formattedAddress?.isEmpty ?? true == false  else {
                validDestinationLabel.set(text: NSLocalizedString("Enter valid destination", bundle: .module, comment: "Choose destination"), for: .footnote, textColor: ReverseGeocodingMap.configuration.palette.mainTexts)
                return
            }
            validDestinationLabel.set(text: place.formattedAddress, for: .footnote, textColor: ReverseGeocodingMap.configuration.palette.mainTexts)
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
