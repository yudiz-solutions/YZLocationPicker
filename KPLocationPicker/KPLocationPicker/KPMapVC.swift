//
//  KPMapVC.swift
//  KPLocationPicker
//
//  Created by Yudiz on 1/2/17.
//  Copyright © 2017 Yudiz. All rights reserved.
//

import UIKit
import MapKit

class KPMapVC: UIViewController,UISearchBarDelegate {
    
    // IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var imgPin: UIImageView!
    @IBOutlet var lblSelectedAddress: UILabel!
    
    // Variables
    var pinAnimation: CABasicAnimation!
    var selectedAddress: FullAddress!
    var callBackBlock: ((_ add: FullAddress) -> Void)!
    
    // View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initAnimation()
        self.addLableShadow()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.fetchUserLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "locationPickerSegue"{
            let searchCon = segue.destination as! KPSearchLocationVC
            searchCon.selectionBlock = {[unowned self](add) -> () in
                self.setMapResion(lat: add.lat, long: add.long)
                self.lblSelectedAddress.text = add.address
                self.selectedAddress = add
            }
        }
    }
}


// MARK: - Actions
extension KPMapVC{
    
    @IBAction func getUserCurrentLocation(sender: UIButton){
        self.fetchUserLocation()
    }
    
    @IBAction func dismissKPPicker(sender: UIButton){
        if selectedAddress != nil{
            callBackBlock(selectedAddress)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnSearchAddTap(sender: UIButton){
        self.performSegue(withIdentifier: "locationPickerSegue", sender: nil)
    }
}

// MARK: - Other methods
extension KPMapVC{

    /// Init pin rotation animation
    func initAnimation(){
        pinAnimation = CABasicAnimation(keyPath: "transform.rotation.y")
        pinAnimation.toValue = (M_PI * 2.0 * 0.2)
        pinAnimation.duration = 0.2
        pinAnimation.isCumulative = true
        pinAnimation.repeatCount = Float.infinity
    }
    
    /// Add Shadow in address lable
    func addLableShadow(){
        lblSelectedAddress.layer.shadowColor = UIColor.black.cgColor
        lblSelectedAddress.layer.shadowRadius = 4.0
        lblSelectedAddress.layer.shadowOpacity = 0.7
        lblSelectedAddress.layer.shadowOffset = CGSize(width: 0, height: 0)
    }
    
    /// Start pin rotation animation
    func startPinAnimation(){
        self.imgPin.layer.add(self.pinAnimation, forKey: "rotationAnimation")
    }
    
    /// Stop pin rotation animation
    func stopPinAnimation(){
        self.imgPin.layer.removeAllAnimations()
    }
    
    /// Fetch user current location with formatted address.
    func fetchUserLocation() {
        self.startPinAnimation()
        UserLocation.sharedInstance.fetchUserLocationForOnce(controller: self) { (location, error) in
            if let _ = location{
                if isGooleKeyFound{
                    KPAPICalls.shared.getAddressFromLatLong(lat: "\(location!.coordinate.latitude)", long: "\(location!.coordinate.longitude)", block: { (str) in
                        self.stopPinAnimation()
                        self.lblSelectedAddress.text = str
                        self.mapView.userLocation.title = str
                        self.setMapResion(lat: location!.coordinate.latitude, long: location!.coordinate.longitude)
                        self.selectedAddress = FullAddress(lati: location!.coordinate.latitude, longi: location!.coordinate.longitude, add: str)
                    })
                }else{
                    KPAPICalls.shared.addressFromlocation(location: location!, block: { (str) in
                        self.stopPinAnimation()
                        if let _ = str{
                            self.lblSelectedAddress.text = str
                            self.mapView.userLocation.title = str
                            self.setMapResion(lat: location!.coordinate.latitude, long: location!.coordinate.longitude)
                            self.selectedAddress = FullAddress(lati: location!.coordinate.latitude, longi: location!.coordinate.longitude, add: str!)
                        }
                    })
                }
            }else{
                self.stopPinAnimation()
            }
        }
    }
}

// MARK: - MapView Delegate and fetch address.
extension KPMapVC: MKMapViewDelegate{
    
    /// Fetch new address on map grag by user.
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool){
        if !animated{
            self.startPinAnimation()
            let cord = mapView.centerCoordinate
            if isGooleKeyFound{
                KPAPICalls.shared.getAddressFromLatLong(lat: "\(cord.latitude)", long: "\(cord.longitude)", block: { (str) in
                    self.stopPinAnimation()
                    self.lblSelectedAddress.text = str
                    self.selectedAddress = FullAddress(lati: cord.latitude, longi: cord.longitude, add: str)
                })
            }else{
                let loc = CLLocation(latitude: cord.latitude, longitude: cord.longitude)
                KPAPICalls.shared.addressFromlocation(location: loc, block: { (str) in
                    self.stopPinAnimation()
                    if let _ = str{
                        self.lblSelectedAddress.text = str
                        self.selectedAddress = FullAddress(lati: cord.latitude, longi: cord.longitude, add: str!)
                    }
                })
            }
        }
    }
    
    
    /// Set resion on map with selected loaction
    func setMapResion(lat: Double, long: Double){
        var loc = CLLocationCoordinate2D()
        loc.latitude = lat
        loc.longitude = long
        
        var span = MKCoordinateSpan()
        span.latitudeDelta = 0.05
        span.longitudeDelta = 0.05
        
        var myResion = MKCoordinateRegion()
        myResion.center = loc
        myResion.span = span
        self.mapView.setRegion(myResion, animated: true)
    }
}
