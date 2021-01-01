//
//  Tile.swift
//  Notes app
//
//  Created by Finn Zink on 12/29/20.
//

import Foundation

struct Tile: Identifiable {
    var id = UUID()
    var name: String
}

let TestData = [
    Tile(name: "A"),
    Tile(name: "B"),
    Tile(name: "C"),
]
