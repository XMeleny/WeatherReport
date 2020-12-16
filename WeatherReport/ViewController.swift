//
//  ViewController.swift
//  WeatherReport
//
//  Created by gtk on 2020/12/15.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var weatherLabel: UILabel!
    
    var locationManager:CLLocationManager!
    
    lazy var geoCoder: CLGeocoder = {
        return CLGeocoder()
    }()
    
    var currentAnnotation:MyAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //mapView settings
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
    }
    
    override func viewDidAppear(_ animated: Bool) {
        determineCurrentLocation()
    }
    
    func determineCurrentLocation(){
        locationManager = CLLocationManager()
        locationManager.delegate=self
        locationManager.desiredAccuracy=kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled(){
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0] as CLLocation
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        mapView.setRegion(region, animated: true)
        
        updateCityInLabel(latitude: latitude, longitude: longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error.localizedDescription = \(error.localizedDescription)")
    }
    
    func updateCityInLabel(latitude:CLLocationDegrees, longitude:CLLocationDegrees){
        let location = CLLocation(latitude: latitude, longitude: longitude)
        geoCoder.reverseGeocodeLocation(location) {
            (placemarks, error) -> Void in
            if let placeMark = placemarks {
                self.positionLabel.text=placeMark[0].locality
            }
        }
    }
    
    //todo
    func updateWeather(city:String){
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        let point = touches.first?.location(in: mapView)
        let coordinate = mapView.convert(point!, toCoordinateFrom: mapView)
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location) {
            (pls: [CLPlacemark]?, error: Error?) -> Void in
            if error == nil {
                if let pl = pls?.first {
                    let annotation = MyAnnotation(coordinate,pl.locality,pl.name)
                    self.mapView.addAnnotation(annotation)
                    if self.currentAnnotation != nil{
                        self.mapView.removeAnnotation(self.currentAnnotation!)
                    }
                 
                    self.currentAnnotation = annotation
                    self.positionLabel.text = pl.locality
                }
            }
        }
    }
}

class MyAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(_ coordinate:CLLocationCoordinate2D, _ title:String?, _ subtitle:String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}
