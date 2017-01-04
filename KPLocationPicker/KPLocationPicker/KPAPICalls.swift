//
//  KPAPICalls.swift
//  LoactionPicker
//
//  Created by Yudiz on 1/2/17.
//  Copyright © 2017 Yudiz Solutions Pvt.Ltd. All rights reserved.
//

import Foundation
import MapKit

class KPAPICalls: NSObject{
    
    static let shared = KPAPICalls()
    let geoLocation = CLGeocoder()
    
    // Google API
    /// Search location by name and returns custom address with reference code
    ///
    /// - Parameters:
    ///   - text: Search Text
    ///   - block: Returns search addresses and responce type enum like(noResult, network error)
    /// - Returns: URLSessionDataTask for cancel previous request
    func getReferenceFromSearchText(text: String, block:@escaping (([Address],ResponceType)->())) -> URLSessionDataTask{
        let str = text.addingPercentEncoding(withAllowedCharacters: CharacterSet.letters)
        let url = URL(string: "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(str!)&sensor=false&key=\(googleKey)")!
        let req = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: req, completionHandler: { (dataObj, urlRes, err) in
            var resType = ResponceType.success
            var arrAddress: [Address] = []
            if let res = urlRes as? HTTPURLResponse, dataObj != nil{
                if res.statusCode == 200{
                    let objJson = try! JSONSerialization.jsonObject(with: dataObj!, options: JSONSerialization.ReadingOptions.allowFragments)
                    let json = objJson as! NSDictionary
                    if json["status"] as! String == "OK"{
                        if let data = json["predictions"] as? NSDictionary{
                            let add = Address(googleData: data)
                            arrAddress.append(add)
                        }else if let dataArr = json["predictions"] as? [NSDictionary]{
                            for data in dataArr{
                                let add = Address(googleData: data)
                                arrAddress.append(add)
                            }
                        }
                        resType = .success
                    }else if json["status"] as! String == "ZERO_RESULTS"{
                        resType = .noResult
                    }else{
                        resType = .success
                    }
                }else{
                    resType = .netWorkError
                }
            }else{
                if (err as! NSError).code != -999{
                    resType = .netWorkError
                }
            }
            
            DispatchQueue.main.async {
                block(arrAddress, resType)
            }
        })
        task.resume()
        return task
    }
    
    // Google API
    /// Get Location with lat, logn and formatted address.
    ///
    /// - Parameters:
    ///   - ref: reference id of location
    ///   - block: return fullAddress structure and error.
    func getLocationFromReference(ref: String, block:@escaping ((FullAddress?, NSError?)->())){
        let url = URL(string: "https://maps.googleapis.com/maps/api/place/details/json?reference=\(ref)&sensor=false&key=\(googleKey)")
        let req = URLRequest(url: url!)
        URLSession.shared.dataTask(with: req) { (data, resObj, error) in
            if let res = resObj as? HTTPURLResponse, data != nil{
                if res.statusCode == 200{
                    var tmpAddress = FullAddress()
                    let jsonObj = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
                    let json = jsonObj as! NSDictionary
                    if let data = json["result"] as? NSDictionary{
                        tmpAddress.address = data.getStringValue(key: "formatted_address")
                        if let cordinate = data["geometry"] as? NSDictionary{
                            if let loc = cordinate["location"] as? NSDictionary{
                                tmpAddress.lat =  loc.getDoubleValue(key: "lat")
                                tmpAddress.long = loc.getDoubleValue(key: "lng")
                            }
                        }
                    }else if let data = json["result"] as? [NSDictionary]{
                        tmpAddress.address = data[0].getStringValue(key: "formatted_address")
                        if let cordinate = data[0]["geometry"] as? NSDictionary{
                            if let loc = cordinate["location"] as? NSDictionary{
                                tmpAddress.lat =  loc.getDoubleValue(key: "lat")
                                tmpAddress.long = loc.getDoubleValue(key: "lng")
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        block(tmpAddress, error as NSError?)
                    }
                }else{
                    DispatchQueue.main.async {
                        block(nil, error as NSError?)
                    }
                }
            }else{
                DispatchQueue.main.async {
                    block(nil, error as NSError?)
                }
            }
            }.resume()
    }
    
    // // Google API
    /// Fetch address from lat, long
    ///
    /// - Parameters:
    ///   - lat: latitite
    ///   - long: longitute
    ///   - block: return formatted address string
    func getAddressFromLatLong(lat: String, long: String, block:@escaping ((String)->())){
        let url = URL(string: "http://maps.googleapis.com/maps/api/geocode/json?latlng=\(lat),\(long)&sensor=true")
        let req = URLRequest(url: url!)
        URLSession.shared.dataTask(with: req) { (data, resObj, error) in
            if let res = resObj as? HTTPURLResponse, data != nil{
                if res.statusCode == 200{
                    var tmpAddress = FullAddress()
                    let jsonObj = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
                    let json = jsonObj as! NSDictionary
                    if json["status"] as! String == "OK"{
                        if let data = json["results"] as? NSDictionary{
                            tmpAddress.address = data.getStringValue(key: "formatted_address")
                        }else if let data = json["results"] as? [NSDictionary]{
                            tmpAddress.address = data[0].getStringValue(key: "formatted_address")
                        }
                    }
                    DispatchQueue.main.async {
                        block(tmpAddress.address)
                    }
                }else{
                    DispatchQueue.main.async {
                       block("")
                    }
                }
            }else{
                DispatchQueue.main.async {
                    block("")
                }
            }
            }.resume()
    }
    
    
    // Geo Code
    /// address from CLLocation
    ///
    /// - Parameters:
    ///   - location: CLLocation object
    ///   - block: return formatted address string
    func addressFromlocation(location: CLLocation, block: @escaping (String?)->()){
        geoLocation.cancelGeocode()
        geoLocation.reverseGeocodeLocation(location, completionHandler: { (placeMarks, error) -> Void in
            if let pmark = placeMarks, pmark.count > 0 {
                let place :CLPlacemark = pmark.last! as CLPlacemark
                if let addr = place.addressDictionary {
                    var str = ""
                    if let arr = addr["FormattedAddressLines"] as? NSArray{
                        str = arr.componentsJoined(by: ",")
                    }
                    
                    DispatchQueue.main.async {
                        block(str)
                    }
                }
            }else{
                DispatchQueue.main.async {
                    block(nil)
                }
            }
        })
    }

    // Geocode
    /// Search address with geocode
    ///
    /// - Parameters:
    ///   - str: Search string
    ///   - block: Returns search addresses and responce type enum like(noResult, network error)
    func searchAddressBygeocode(str: String, block:@escaping (([Address],ResponceType)->())){
        geoLocation.cancelGeocode()
        geoLocation.geocodeAddressString(str) { (placeMarks, error) in
            if let pmark = placeMarks, pmark.count > 0 {
                var arrPlace:[Address] = []
                for place in pmark{
                    let add = Address(geoCodeData: place)
                    arrPlace.append(add)
                }
                
                DispatchQueue.main.async {
                    block(arrPlace, ResponceType.success)
                }
            }else{
                if let err = error as? NSError{
                    if err.code != 10{
                        DispatchQueue.main.async {
                            block([], ResponceType.noResult)
                        }
                    }
                }else{
                    DispatchQueue.main.async {
                        block([], ResponceType.netWorkError)
                    }
                }
            }
        }
    }
}

// MARK: - Dictionaty extention for coversion.
extension NSDictionary{
    func getDoubleValue(key: String) -> Double{
        if let any: Any = self[key]{
            if let number = any as? NSNumber{
                return number.doubleValue
            }else if let str = any as? NSString{
                return str.doubleValue
            }
        }
        return 0
    }
    func getStringValue(key: String) -> String{
        if let any: Any = self[key]{
            if let number = any as? NSNumber{
                return number.stringValue
            }else if let str = any as? String{
                return str
            }
        }
        return ""
    }
}
