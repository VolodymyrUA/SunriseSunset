
import UIKit
import Alamofire
import SwiftyJSON
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let basePathForSunriseRequest = "https://api.sunrise-sunset.org/json?"
    let basePathForTimezoneRequest = "https://maps.googleapis.com/maps/api/timezone/json?location="
    let apiKeyForTimezoneRequest = "AIzaSyD_iKl-I9FVlNaPVA9gMgk72Ne1AeNPuLc"
    let timestamp = Int(NSDate().timeIntervalSince1970)
    let locationManager = CLLocationManager()
    var timezoneData: DataForTimezoneRequest?
    var weather : Weather?
    let secondsInHour = 3600
    var curentDateAndTime = String()
    
    //MARK:-@IBOutlet & @IBAction
    //search city
    @IBAction func searchButtonClicked(_ sender: UIButton) {
        if let locationString = cityNameTextField.text, !locationString.isEmpty {
            updateSearchedLocation(location: locationString)
        }
    }
    @IBOutlet weak var sunriseLabel: UITextField!
    @IBOutlet weak var sunsetLabel: UITextField!
    @IBOutlet weak var cityNameTextField: UITextField!
    //current city
    @IBOutlet weak var suriseCurrentLabel: UITextField!
    @IBOutlet weak var sunsetCurrentLabel: UITextField!
    @IBOutlet weak var localDateAndTimeLabel: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localDataAndTime()
        locationManagerSetUp()
    }
    
    //MARK:- local Data and Time
    func localDataAndTime()  {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm "
        let currentLocalDate = dateFormatter.string(from: NSDate() as Date)
        self.curentDateAndTime = currentLocalDate
    }
    
    //MARK:- Location Manager
    func  locationManagerSetUp()  {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        updateSearchedLocation(location: userLocation.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error \(error)")
    }
    
    //MARK: SunriseRequest
    func sunriseRequest (withLocation location: CLLocationCoordinate2D) {
        let url = basePathForSunriseRequest + "lat=\(location.latitude)&lng=\(location.longitude)"
        let urlRequest = URLRequest(url: URL(string: url)!)
        
        Alamofire.request( urlRequest).validate(statusCode: 200..<300).response { response  in
            
            guard response.error == nil else {
                NSLog("Error:\(String(describing: response.error))")
                return
            }
            
            guard let data = response.data else {
                NSLog("No data \(String(describing: response.error))")
                return
            }
            do {
                let json = try JSON.init(data: data)
                
                let sunriseUTCTime = json["results","sunrise"].string
                let sunsetUTCTime  = json["results","sunset"].string
                
                let sunriseConvertedTime = self.calcuateTimeConsiderTimezone(sunriseUTCTimeOptional: sunriseUTCTime, sunsetUTCTimeOptional: sunsetUTCTime).0
                let sunsetConvertedTime = self.calcuateTimeConsiderTimezone(sunriseUTCTimeOptional: sunriseUTCTime, sunsetUTCTimeOptional: sunsetUTCTime).1
                
                self.weather = Weather(sunrise: sunriseConvertedTime, sunset: sunsetConvertedTime)
                
                if self.cityNameTextField.text == ""  {
                    self.setLabelsForCurrentTimeZone()
                }
                
                if self.cityNameTextField.text != "" {
                    self.setLabelsForFoundCity()
                }
                
            } catch {
                NSLog("==Error: \(error)")
            }
        }
    }
    
    //MARK: timezoneRequest
    func timezoneRequest (withLocation location: CLLocationCoordinate2D) {
        let url = basePathForTimezoneRequest + "\(location.latitude),\(location.longitude)&timestamp=\(timestamp)&key=" + apiKeyForTimezoneRequest
        let urlRequest = URLRequest(url: URL(string: url)!)
        
        Alamofire.request( urlRequest).validate(statusCode: 200..<300).response { response  in
            guard response.error == nil else {
                NSLog("Error@@@@@@@@:\(String(describing: response.error))")
                return
            }
            
            guard let data = response.data else {
                NSLog("No data \(String(describing: response.error))")
                return
            }
            do {
                let json = try JSON.init(data: data)
                
                
                let rawOffset = json["rawOffset"].int
                let dstOffset  = json["dstOffset"].int
                
                if let dstOffset = dstOffset, let rawOffset = rawOffset  {
                    let summerTime = dstOffset / self.secondsInHour
                    let numberOfTimeZone = rawOffset / self.secondsInHour
                    
                    self.timezoneData = DataForTimezoneRequest(summerTime: summerTime , numberOfTimeZone: numberOfTimeZone)
                    
                }
            } catch {
                NSLog("!!!!!Error: \(error)")
            }
        }
    }
    
    func dateConvertTo24Format(sunriseUTCTimeOptional: String?, sunsetUTCTimeOptional:String?) -> (String, String) {
        
        var sunriseUTC24Format = String()
        var sunsetUTC24Format = String()
        
        if let sunriseUTCTime = sunriseUTCTimeOptional, let sunsetUTCTime = sunsetUTCTimeOptional {
            
            let sunriseDateFormatter = DateFormatter()
            sunriseDateFormatter.dateFormat = "h:mm:ss a"
            
            let dateSunrise = sunriseDateFormatter.date(from: sunriseUTCTime)
            sunriseDateFormatter.dateFormat = "HH:mm"
            
            if let dateSunrise = dateSunrise {
                sunriseUTC24Format = sunriseDateFormatter.string(from: dateSunrise)
            }
            // sunset convert to 24 Hours Format
            let sunsetDateFormatter = DateFormatter()
            sunsetDateFormatter.dateFormat = "h:mm:ss a"
            
            let dateSunset = sunsetDateFormatter.date(from: sunsetUTCTime)
            sunsetDateFormatter.dateFormat = "HH:mm"
            
            if let dateSunset = dateSunset {
                sunsetUTC24Format  = sunsetDateFormatter.string(from: dateSunset)
            }
            
        }
        return( sunriseUTC24Format, sunsetUTC24Format)
    }
    
    //MARK:- Calculate local time of Sunrise/Sunset consider timeZone
    func calcuateTimeConsiderTimezone(sunriseUTCTimeOptional: String?, sunsetUTCTimeOptional :String?) -> (String, String) {
        
        let sunriseUTCTime =  dateConvertTo24Format(sunriseUTCTimeOptional: sunriseUTCTimeOptional, sunsetUTCTimeOptional: sunsetUTCTimeOptional).0
        let sunsetUTCTime = dateConvertTo24Format(sunriseUTCTimeOptional: sunriseUTCTimeOptional, sunsetUTCTimeOptional: sunsetUTCTimeOptional).1

        var sunriseHour = Int()
        var sunsetHour  = Int()
        
        var sunriseUTCHour = Int()
        var sunsetUTCHour = Int()
        
        var  sunriseUTCHourCharArray = [Character]()
        var  sunsetUTCHourCharArray = [Character]()

        // calculete geting 2 first numbers
        for i in sunriseUTCTime {
            if i == ":" {
                sunriseUTCHour = Int(String(sunriseUTCHourCharArray)) ?? 0
                break
            }
            sunriseUTCHourCharArray += [i]
        }
        
        for i in sunsetUTCTime {
            if i == ":" {
                sunsetUTCHour = Int(String(sunsetUTCHourCharArray)) ?? 0
                break
            }
            sunsetUTCHourCharArray += [i]
        }
       
        //MARK:-  сhecking if hour is correct
        sunriseHour =  sunriseUTCHour + self.timezoneData!.numberOfTimeZonerawOffset + self.timezoneData!.summerTimedstOffset
        
        if sunriseHour < 0 {
            sunriseHour = sunriseHour + 24
        } else if sunriseHour > 24 {
            sunriseHour = sunriseHour - 24
        }
        
        sunsetHour =  sunsetUTCHour + self.timezoneData!.numberOfTimeZonerawOffset + self.timezoneData!.summerTimedstOffset
        
        if sunsetHour < 0 {
            sunsetHour = sunsetHour + 24
        } else if sunsetHour > 24 {
            sunsetHour = sunsetHour - 24
        }
        
        var sunriseConvertedTime = String()
        var sunsetConvertedTime = String()
        
        sunriseConvertedTime = sunriseUTCTime
        sunsetConvertedTime = sunsetUTCTime
        
        for i in sunriseConvertedTime {
            if i == ":" {
                break
            }
            sunriseConvertedTime.remove(at: sunriseConvertedTime.startIndex )
        }
        
        for i in sunsetConvertedTime {
            if i == ":" {
                break
            }
            sunsetConvertedTime.remove(at: sunsetConvertedTime.startIndex)
        }
        
        let tempSunrise = String(sunriseHour)
        let tempArraySunrise = Array(tempSunrise)
        let reversedArraySunrise : [String.Element] = tempArraySunrise.reversed()
        
        for i in reversedArraySunrise {
            sunriseConvertedTime.insert(i, at: sunriseConvertedTime.startIndex)
        }
        
        //MARK:- replacing on correct hour consider timeZone for sunrise
        let tempSunset = String(sunsetHour)
        let arrayOfCharSunset = Array(tempSunset)
        let reversedSunsetArray : [String.Element] = arrayOfCharSunset.reversed()
        
        for i in reversedSunsetArray {
            sunsetConvertedTime.insert(i, at: sunsetConvertedTime.startIndex)
        }
        return ( sunriseConvertedTime, sunsetConvertedTime)
    }
    
    //MARK: - Updating Searched Location
    func updateSearchedLocation (location: String) {
        CLGeocoder().geocodeAddressString(location) { (placemarks:[CLPlacemark]?, error:Error?) in
            if error == nil {
                if let location = placemarks?.first?.location {
                    self.sunriseRequest ( withLocation: location.coordinate)
                    self.timezoneRequest(withLocation: location.coordinate)
                }
            }
        }
    }
    
    func updateSearchedLocation (location: CLLocationCoordinate2D) {
        self.sunriseRequest ( withLocation: location)
        self.timezoneRequest(withLocation: location)
    }
    
    //MARK: - Seting Labels 
    // for current local timezone
    func setLabelsForCurrentTimeZone() {
        if let sunrise = weather?.sunrise { suriseCurrentLabel.text = sunrise }
        if let sunset  = weather?.sunset  { sunsetCurrentLabel.text  = sunset  }
        localDateAndTimeLabel.text = self.curentDateAndTime
    }
    // for fonund city
    func setLabelsForFoundCity() {
        if let sunrise = weather?.sunrise { sunriseLabel.text = sunrise }
        if let sunset  = weather?.sunset  { sunsetLabel.text  = sunset  }
    }
}

