//
//  Item.swift
//  TestApp
//
//  Created by Ethan Hong on 7/19/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
