//
//  KPConstant.swift
//  KPLocationPicker
//
//  Created by Yudiz on 1/3/17.
//  Copyright © 2017 Yudiz. All rights reserved.
//

import Foundation

let googleKey = ""

/// If google key is empty than location fetch via goecode.
var isGooleKeyFound : Bool = {
    return !googleKey.isEmpty
}()
