//
//  ViewModel.swift
//  WidgetPlus
//
//  Created by Gavin Jensen on 8/1/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

import SceneKit
import Firebase

private let totalWidgets = 12

class ViewModel: ObservableObject, Identifiable {
    
	private let db = Firestore.firestore()
    
    @Published var widgets = [Model.WidgetIdentifier]()
    
    var scnNodes: [SCNNode] = Array(repeating: SCNNode(), count: totalWidgets)
    
    //MARK: - Mutators
    
    func changePosition(to position: SCNVector3, at index: Int) {
        scnNodes[index].position = position
    }
    
    func changeNode(to node: SCNNode, at index: Int) {
        scnNodes[index] = node
    }
    
    func changeDetected(to detected: Bool = true, at index: Int) {
        self.widgets[index].detected = detected
    }
    
    func load() {
		//This is making the obtuse assumption that widget names will always be "widget<id>"
		func idFromName(_ name: String) -> Int? {
			return Int(name.replacingOccurrences(of: "widget", with: ""))
		}
		
		db.collection("systems").document("dependencies").addSnapshotListener { (snapshot, error) in
			if let snapshot = snapshot, let dependencies = snapshot.data() as? [String: [String]] {
				//Turn the dependencies map into a list of widgets for use in the app
				self.widgets = dependencies.compactMap { (widgetName, childNames) -> Model.WidgetIdentifier? in
					guard let id = idFromName(widgetName) else { return nil }
					
					var widget = Model.WidgetIdentifier(id: id, name: widgetName, widgetType: 0)
					widget.children = childNames.compactMap {
						guard let id = idFromName($0) else { return nil }
						return Model.Child(id: id)
					}
					return widget
				}.sorted(by: { (lhs, rhs) -> Bool in
					lhs.name < rhs.name
				})
			} else {
				print("Error getting widget dependencies: \(error?.localizedDescription ?? "")")
			}
		}
    }
}
