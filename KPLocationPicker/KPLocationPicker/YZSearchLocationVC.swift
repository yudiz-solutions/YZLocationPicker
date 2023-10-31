//
//  YZSearchLocationVC.swift
//  YZLocationPicker
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
    
    init(lati: Double, longi: Double, add: String){
        lat = lati
        long = longi
        address = add
    }
    
    init(addObj: Address) {
        lat = addObj.lat
        long = addObj.long
        address = addObj.name
    }
}

class Address: NSObject{
    
    // For google search
    var name: String!
    var refCode: String!
    
    // For Geocode search
    var lat: Double = 0.0
    var long: Double = 0.0
    
    init(googleData: NSDictionary) {
        name = googleData.getStringValue(key: "description")
        refCode = googleData.getStringValue(key: "reference")
        super.init()
    }
    
    init(geoCodeData: CLPlacemark) {
        refCode = ""
        name = geoCodeData.addressDict()
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
    case success = 0
    case loading
    case noResult
    case netWorkError
}

class YZSearchLocationVC: UIViewController{
    
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
        loadType = .success
        tblView.rowHeight = UITableView.automaticDimension
        tblView.tableFooterView = UIView()
        tfSerach.addTarget(self, action: #selector(YZSearchLocationVC.searchTextDidChange), for: .editingChanged)
        initSerchBar()
        prepareForkeyboardNotification()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tfSerach.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Action Method
extension YZSearchLocationVC{
   
    @IBAction func cancelBtnTap(sender: UIButton){
        self.dismiss(animated: false, completion: nil)
    }
}

// MARK: - Other method
extension YZSearchLocationVC{

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
        btnClear.addTarget(self, action: #selector(YZSearchLocationVC.textFieldClear), for: .touchUpInside)
        tfSerach.rightView = btnClear
        tfSerach.rightViewMode = .always
        
        
        // Add attributed place holder text
        let attrDic = [NSAttributedString.Key.font : UIFont(name: "Avenir", size: 15)!,
                       NSAttributedString.Key.foregroundColor : UIColor.lightGray]
        let attriStr = NSAttributedString(string: "Search Text",attributes:attrDic)
        tfSerach.attributedPlaceholder = attriStr
        tfSerach.font = UIFont(name: "Avenir", size: 15)
        tfSerach.frame = CGRect(x: 50, y: 0, width: 320, height: 320)

    }
}

//MARK:- search and textfield
extension YZSearchLocationVC: UITextFieldDelegate{
    
    @objc func textFieldClear(sender: UIButton){
        tfSerach.text = ""
        self.searchTextDidChange(textField: tfSerach)
    }
    
    @objc func searchTextDidChange(textField: UITextField){
        if sessionDataTask != nil{
            sessionDataTask.cancel()
        }
        
        self.arrData = []
        loadType = .loading
        self.tblView.reloadData()
        
        let str = textField.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if str!.count > 0{
            if isGooleKeyFound{
                sessionDataTask = YZAPICalls.shared.getReferenceFromSearchText(text: str!, block: { (addresses, resType) in
                    self.loadType = resType
                    self.arrData = addresses
                    self.tblView.reloadData()
                })
            }else{
                YZAPICalls.shared.searchAddressBygeocode(str: str!, block: { (adds, restype) in
                    self.loadType = restype
                    self.arrData = adds
                    self.tblView.reloadData()
                })
            }
        }else{
            self.loadType = .success
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
extension YZSearchLocationVC: UITableViewDelegate,UITableViewDataSource{
   
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
            if loadType == ResponceType.success {
                return 0.0
            }else{
                return 44.0
            }
        }else{
            return UITableView.automaticDimension
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
                YZAPICalls.shared.getLocationFromReference(ref: arrData[indexPath.row - 1].refCode, block: { (address, error) in
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

// MARK: - Keyboard Extension
extension YZSearchLocationVC {
    func prepareForkeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(YZSearchLocationVC.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(YZSearchLocationVC.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification){
        if let kbSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            tblView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: kbSize.height, right: 0)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        tblView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
    }
}
