//
//  Mock.swift
//  OBDVlink
//
//  Created by Dosi Dimitrov on 21.01.24.
//

import Foundation

protocol Mock {}

extension Mock {
    var className: String {
        return String(describing: type(of: self))
    }
    
    func log(_ message: String? = nil) {
        print("Mocked -", className, message ?? "")
    }
}
