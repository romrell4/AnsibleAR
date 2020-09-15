//
//  ViewModel.swift
//  WidgetPlus
//
//  Created by Gavin Jensen on 8/1/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

import SceneKit
import FirebaseFirestore

private let totalWidgets = 12

class ViewModel: ObservableObject, Identifiable {
    
	private let db = Firestore.firestore()
    
	@Published var widgets = (0..<totalWidgets).map {
		Model.WidgetIdentifier(id: $0, name: "widget\($0)", children: [])
	}
	
	var detectedWidgets: [Model.WidgetIdentifier] { widgets.filter { $0.detected } }
    
    var scnNodes: [SCNNode] = Array(repeating: SCNNode(), count: totalWidgets)
    
    //MARK: - Mutators
    
    func changePosition(to position: SCNVector3, at index: Int) {
        scnNodes[index].position = position
    }
    
    func changeNode(to node: SCNNode, at index: Int) {
        scnNodes[index] = node
    }
    
    func changeDetected(to detected: Bool = true, at index: Int) {
		DispatchQueue.main.async {
			self.widgets[index].detected = detected
		}
    }
    
    func load() {
		//This is making the obtuse assumption that widget names will always be "widget<id>"
		func idFromName(_ name: String) -> Int? {
			return Int(name.replacingOccurrences(of: "widget", with: ""))
		}
		
		db.collection("dependencies").document("dependencies").addSnapshotListener { (snapshot, error) in
			if let snapshot = snapshot, let dependencies = snapshot.data() as? [String: [String]] {
				DispatchQueue.main.async {
					//Update children of widgets based on dependency list
					dependencies.compactMap { (widgetName, childNames) -> (Int, [Int])? in
						//Turn the names into ids
						guard let id = idFromName(widgetName) else { return nil }
						
						return (id, childNames.compactMap { idFromName($0) })
					}.forEach { widgetId, childIds in
						if let index = self.widgets.firstIndex(where: { $0.id == widgetId }) {
							print("Setting \(widgetId)'s children to \(childIds)")
							self.widgets[index].children = childIds.map { Model.Child(id: $0) }
						}
					}
				}
			} else {
				print("Error getting widget dependencies: \(error?.localizedDescription ?? "")")
			}
		}
    }
}
