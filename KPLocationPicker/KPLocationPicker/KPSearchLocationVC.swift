//
//  KPSearchLocationVC.swift
//  KPLocationPicker
//
//  Created by Yudiz on 1/2/17.
//  Copyright © 2017 Yudiz. All rights reserved.
//

import UIKit
import MapKit

struct FullAddress{
    var lat: Double = 0.0
    var long: Double = 0.0
    var address: String = ""
    
    init(){
    }
    
    init(addObj: Address) {
        lat = addObj.lat
        long = addObj.long
        address = addObj.name
    }
}

class Address: NSObject{
    var name: String!
    var refCode: String!
    var lat: Double = 0.0
    var long: Double = 0.0
    
    init(googleData: NSDictionary) {
        name = googleData.getStringValue(key: "description")
        refCode = googleData.getStringValue(key: "reference")
        super.init()
    }
    
    init(geoCodeData: CLPlacemark) {
        refCode = ""
        name = ""
        if let addr = geoCodeData.addressDictionary{
            if let arr = addr["FormattedAddressLines"] as? NSArray{
                name = arr.componentsJoined(by: ",")
            }
        }
        
        if let loc = geoCodeData.location{
            lat = loc.coordinate.latitude
            long = loc.coordinate.longitude
        }
        super.init()
    }
}

class addressCell: UITableViewCell {
    @IBOutlet var lblName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

enum ResponceType:Int{
    case noneType = 0
    case loading
    case noResult
    case netWorkError
}

class KPSearchLocationVC: UIViewController{
    
    // IBOutlet
    @IBOutlet var tfSerach: UITextField!
    @IBOutlet var tblView: UITableView!
    
    // Variable
    var isLoading: Bool = false
    var isNoResult: Bool = false
    var sessionDataTask: URLSessionDataTask!
    var arrData :[Address] = []
    var loadType : ResponceType!
    var selectionBlock: ((_ add: FullAddress) -> Void)!
    
    // Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        loadType = .noneType
        tblView.rowHeight = UITableViewAutomaticDimension
        tblView.tableFooterView = UIView()
        tfSerach.addTarget(self, action: #selector(KPSearchLocationVC.searchTextDidChange), for: .editingChanged)
        initSerchBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tfSerach.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - Action Method
extension KPSearchLocationVC{
   
    @IBAction func cancelBtnTap(sender: UIButton){
        self.dismiss(animated: false, completion: nil)
    }
}

// MARK: - Other method
extension KPSearchLocationVC{

    /// Add search icon and clear button in textfield search
    func initSerchBar(){
        // Add search icon
        let imgView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: tfSerach.frame.size.height))
        imgView.image = UIImage(named: "searchIcon.png")
        imgView.contentMode = .center
        tfSerach.leftView = imgView
        tfSerach.leftViewMode = .always
        
        // Add clear button
        let btnClear = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: tfSerach.frame.size.height))
        btnClear.setImage(UIImage(named: "cancelIcon.png"), for: .normal)
        btnClear.addTarget(self, action: #selector(KPSearchLocationVC.textFieldClear), for: .touchUpInside)
        tfSerach.rightView = btnClear
        tfSerach.rightViewMode = .always
        
        
        // Add attributed place holder text
        let attrDic : [String : AnyObject] = [NSFontAttributeName : UIFont(name: "Avenir", size: 15)!,
                                              NSForegroundColorAttributeName : UIColor.lightGray]
        let attriStr = NSAttributedString(string: "Search Text",attributes:attrDic)
        tfSerach.attributedPlaceholder = attriStr
        tfSerach.font = UIFont(name: "Avenir", size: 15)
        tfSerach.frame = CGRect(x: 50, y: 0, width: 320, height: 320)

    }
}

//MARK:- search and textfield
extension KPSearchLocationVC: UITextFieldDelegate{
    
    func textFieldClear(sender: UIButton){
        tfSerach.text = ""
        self.searchTextDidChange(textField: tfSerach)
    }
    
    func searchTextDidChange(textField: UITextField){
        if sessionDataTask != nil{
            sessionDataTask.cancel()
        }
        
        self.arrData = []
        loadType = .loading
        self.tblView.reloadData()
        
        let str = textField.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if str!.characters.count > 0{
            if isGooleKeyFound{
                sessionDataTask = KPAPICalls.shared.getReferenceFromSearchText(text: str!, block: { (addresses, resType) in
                    self.loadType = resType
                    self.arrData = addresses
                    self.tblView.reloadData()
                })
            }else{
                KPAPICalls.shared.searchAddressBygeocode(str: str!, block: { (adds, restype) in
                    self.loadType = restype
                    self.arrData = adds
                    self.tblView.reloadData()
                })
            }
        }else{
            self.loadType = .noneType
            self.arrData = []
            self.tblView.reloadData()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        tfSerach.resignFirstResponder()
        return true
    }
}

// MARK: - Tableview methods
extension KPSearchLocationVC: UITableViewDelegate,UITableViewDataSource{
   
    func numberOfRowsInSection(section: Int) -> Int{
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrData.count + 1
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        if indexPath.row == 0{
            cell.selectionStyle = .none
            if loadType == ResponceType.loading{
                cell.textLabel?.text = "Loading..."
            }else if loadType == ResponceType.noResult{
                cell.textLabel?.text = "No result found"
            }else{
                cell.textLabel?.text = "Please try again"
            }
        }else{
            cell.selectionStyle = .default
            cell.textLabel?.text = arrData[indexPath.row - 1].name
        }
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont(name: "Avenir-Book", size: 15.0)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0{
            if loadType == ResponceType.noneType {
                return 0.0
            }else{
                return 44.0
            }
        }else{
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0{
            return 0.0
        }else{
            return 44.0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row != 0{
            if isGooleKeyFound{
                KPAPICalls.shared.getLocationFromReference(ref: arrData[indexPath.row - 1].refCode, block: { (address, error) in
                    if error == nil{
                        self.selectionBlock(address!)
                        self.dismiss(animated: false, completion: nil)
                    }
                })
            }else{
                let fullAdd = FullAddress(addObj: arrData[indexPath.row - 1])
                self.selectionBlock(fullAdd)
                self.dismiss(animated: false, completion: nil)
            }
            tblView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableCell(withIdentifier: "headerCell") as! addressCell
        view.lblName.text = "Search result"
        return view
    }
}
