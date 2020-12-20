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
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var weatherLabel: UILabel!
    
    @IBAction func mapViewTap(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        getCityInformation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    var locationManager:CLLocationManager!
    
    lazy var geoCoder: CLGeocoder = {
        return CLGeocoder()
    }()
    
    var currentAnnotation:MyAnnotation?
    var currentAdcode:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
    }
    
    override func viewDidAppear(_ animated: Bool) {
        initLocation()
    }
    
    func initLocation(){
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
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.75, longitudeDelta: 0.75))
        mapView.setRegion(region, animated: true)
        
        getCityInformation(latitude: latitude, longitude: longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error.localizedDescription = \(error.localizedDescription)")
    }
    
    let SCHEME_AND_HOST = "https://restapi.amap.com"
    let PATH_CITY_INFORMATION = "/v3/geocode/regeo"
    let PATH_WEATHER_INFORMATION = "/v3/weather/weatherInfo"
    let PARAM_KEY = "key=9fd87874bd0d22ba54679a8571db1974"
    let PARAM_EXTENSIONS = "extensions=all"
    
    func getCityInformation(latitude:Double, longitude:Double){
        let url = URL(string: "\(SCHEME_AND_HOST)\(PATH_CITY_INFORMATION)?\(PARAM_KEY)&location=\(longitude),\(latitude)")!
        let task = URLSession.shared.dataTask(with: url){ (data,response,error) in
            if data == nil {
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String:Any]
            let info = json?["info"] as? String
            
            if info == "OK"{
                let regeocode = json!["regeocode"] as! [String:Any]
                let addressComponent = regeocode["addressComponent"] as! [String:Any]
                let provice = addressComponent["province"] as! String
                let city = addressComponent["city"] as? String
                let district = addressComponent["district"] as? String
                let adcode = addressComponent["adcode"] as! String
                
                var realCity = city
                if city == nil {
                    realCity = provice
                }
                
                self.updateCityLabelInMainThread(city: realCity!)
                self.updataAnnotationInMainThread(
                    coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                    city: realCity!,
                    district: district ?? ""
                )
                
                if adcode != self.currentAdcode{
                    self.getWeatherInformation(adcode: adcode)
                    self.currentAdcode = adcode
                }
            }else{
                self.httpError()
            }
        }
        task.resume()
        setLoading(label: cityLabel)
    }
    
    func getWeatherInformation(adcode:String){
        let url = URL(string: "\(SCHEME_AND_HOST)\(PATH_WEATHER_INFORMATION)?\(PARAM_KEY)&\(PARAM_EXTENSIONS)&city=\(adcode)")!
        
        let task = URLSession.shared.dataTask(with: url){ (data,response,error) in
            if data == nil {
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String:Any]
            
            let infocode = json!["infocode"] as? String
            if infocode == "10000" {
                let forecasts = json!["forecasts"] as? NSArray
                let casts = (forecasts?[0] as? [String:Any])?["casts"] as? NSArray
                if casts != nil && casts!.count >= 1 {
                    let tomorrowWeather = casts?[1] as? [String:Any]
                    let tomorrowDayWeather = tomorrowWeather?["dayweather"]
                    
                    self.updateWeatherLabelInMainThread(weather: "\(tomorrowDayWeather!)")
                }
            }else{
                self.httpError()
            }
        }
        task.resume()
        setLoading(label: weatherLabel)
    }
    
    func updateCityLabelInMainThread(city:String){
        DispatchQueue.main.async(execute: {
            self.cityLabel.text = city
        })
    }
    
    func updateWeatherLabelInMainThread(weather:String)  {
        DispatchQueue.main.async {
            self.weatherLabel.text = weather
        }
    }
    
    func updataAnnotationInMainThread(coordinate:CLLocationCoordinate2D ,city:String, district:String){
        DispatchQueue.main.async {
            let annotation = MyAnnotation(coordinate,city,district)
            self.mapView.addAnnotation(annotation)
            if self.currentAnnotation != nil {
                self.mapView.removeAnnotation(self.currentAnnotation!)
            }
            self.currentAnnotation = annotation
        }
    }
    
    let errorMsg = "网络错误，请稍后重试"
    func httpError(){
        DispatchQueue.main.async {
            self.cityLabel.text = self.errorMsg
            self.weatherLabel.text = self.errorMsg
        }
    }
    
    let loadingMsg = "加载中..."
    func setLoading(label:UILabel){
        DispatchQueue.main.async {
            label.text = self.loadingMsg
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
