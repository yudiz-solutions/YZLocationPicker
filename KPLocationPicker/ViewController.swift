//
//  ViewController.swift
//  YZLocationPicker
//
//  Created by Yudiz on 1/2/17.
//  Copyright © 2017 Yudiz. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var lblAddress: UILabel!
    
    @IBAction func searchAddress(sender: UIButton){
        let mapVc = UIStoryboard.init(name: "KPLocation", bundle: nil).instantiateInitialViewController() as! YZMapVC
        mapVc.callBackBlock = {[weak self] address in
            self?.lblAddress.text = address.address
        }
        self.present(mapVc, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

