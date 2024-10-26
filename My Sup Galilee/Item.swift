//
//  Item.swift
//  My Sup Galilee
//
//  Created by Ethan Nicolas on 26/10/2024.
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
