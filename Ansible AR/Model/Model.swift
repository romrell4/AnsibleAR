//
//  BerryModel.swift
//  BerryPlus
//
//  Created by Gavin Jensen on 7/30/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

public class Model {
    
//    var widgets: [WidgetIdentifier] = []
    
    struct WidgetIdentifier: Codable, Identifiable, Hashable {
        static func == (lhs: Model.WidgetIdentifier, rhs: Model.WidgetIdentifier) -> Bool {
            return lhs.id == rhs.id && lhs.name == rhs.name
        }
        
        let id: Int
        let name: String
        var children: [Child]
        var detected: Bool = false
        
		init(id: Int, name: String, children: [Child]) {
            self.id = id
            self.name = name
			self.children = children
        }
    }
    
    struct Child: Codable, Identifiable, Hashable {
        static func == (lhs: Model.Child, rhs: Model.Child) -> Bool {
            return lhs.id == rhs.id
        }
        let id: Int
    }
}
