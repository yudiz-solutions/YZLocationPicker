# YZLocationPicker
YZLocation Picker allow to search location by name or set it manually on map drag. also provide option to search location by google api or geocode.

## Screen
![Alt text](/../ScreenShots/screen.gif?raw=true "Optional Title")

## Usages
+ Set google api key in `YZConstant` file if you want to search location with goole API. if you set `googleKey` empty then default search by Geocode.
```
let googleKey = "<google API key>"
```

+ Init `YZMapVC` from `YZLocation` storyboard and push or present this controller, it return selected address in completion block
```
let mapVc = UIStoryboard.init(name: "YZLocation", bundle: nil).instantiateInitialViewController() as! YZMapVC
mapVc.callBackBlock = {[weak self] address in
    self?.lblAddress.text = address.address
}
self.present(mapVc, animated: true, completion: nil)
```

## API Description
If you want to add your custom UI then following API’s will help you to find address.

### Search with google
+ Search your address with search text and it retuns custom Address array for related addresses in block which contains name and place `referenceID` of place. after that you can fill your UI according, you can also cancel previous request by using sessionDataTask. Also this method return one enum in block for `netWorkError`, `loading`, `noResult` and `success`.

```
func searchTextDidChange(textField: UITextField){
    if sessionDataTask != nil{
        sessionDataTask.cancel()
    }

    let str = textField.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    sessionDataTask = YZAPICalls.shared.getReferenceFromSearchText(text: str!, block: { (addresses, resType) in
       // Your code
    })
}
```

+ After search term you need fulladdress, latitute and longitute of place. for this you need to call `getLocationFromReference` with place `refId` and it returns address structure with address, lat and long.

```
YZAPICalls.shared.getLocationFromReference(ref: arrData[indexPath.row - 1].refCode, block: { (address, error) in
    if error == nil{
        // Your Code
    }
})
```

+ Get Address from latitute and longitute and it's return's formatted address string in block.
```
YZAPICalls.shared.getAddressFromLatLong(lat: "72.000", long: "19.0000", block: { (str) in
    // Your Code
})
```

### Search with Geocode
+ Search your address with search text and it retuns custom Address array for related addresses in block of place. after that you can fill your UI according. Also this method return one enum in block for `netWorkError`, `loading`, `noResult` and `success`.
```
YZAPICalls.shared.searchAddressBygeocode(str: str!, block: { (adds, restype) in
    // Your Code
})
```

+ Get formatted address from `CLLocation`.
```
YZAPICalls.shared.addressFromlocation(location: location!, block: { (str) in
    // Your Code
})
```

