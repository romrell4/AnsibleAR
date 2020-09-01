//
//  BerryModel.swift
//  BerryPlus
//
//  Created by Gavin Jensen on 7/30/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

import CoreNFC

public class Model {
    
//    var widgets: [WidgetIdentifier] = []
    
    struct WidgetIdentifier: Codable, Identifiable, Hashable {
        static func == (lhs: Model.WidgetIdentifier, rhs: Model.WidgetIdentifier) -> Bool {
            return lhs.id == rhs.id && lhs.name == rhs.name
        }
        
        let id: Int
        let name: String
        let widgetType: Int
        var children: [Child]
        var detected: Bool? = false
        
        init(id: Int, name: String, widgetType: Int) {
            self.id = id
            self.name = name
            self.widgetType = widgetType
            children = []
        }
        
        init?(message: NFCNDEFMessage) {
            guard
                let locationRecord = message.records.first,
                let widgetName = locationRecord.wellKnownTypeTextPayload().0
                else {
                    return nil
            }
            
            self.id = -1
            self.name = widgetName
            self.detected = true
            self.widgetType = 1
            self.children = []
        }
    }
    
    struct Child: Codable, Identifiable, Hashable {
        static func == (lhs: Model.Child, rhs: Model.Child) -> Bool {
            return lhs.id == rhs.id
        }
        let id: Int
    }
}
