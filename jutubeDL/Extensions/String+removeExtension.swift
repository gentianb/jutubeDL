//
//  String+removeExtension.swift
//  jutubeDL
//
//  Created by Gentian Barileva on 10/5/18.
//  Copyright © 2018 Gentian Barileva. All rights reserved.
//

import Foundation

extension String{
    func removeExtension() -> String{
        return String(self.dropLast(4))
    }
}
