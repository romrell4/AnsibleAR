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
    
	var widgets: [Widget] = []
	
	var detectedWidgets: [Widget] { widgets.filter { $0.detected } }
    
    //MARK: - Mutators
    
    func changePosition(to position: SCNVector3, at index: Int) {
		self.widgets[index].scnNode.position = position
    }
	
	func detectWidget(with imageId: Int) -> Widget? {
		guard let index = self.widgets.firstIndex(where: { $0.photoId == imageId }) else { return nil }
		self.widgets[index].detected = true
		return self.widgets[index]
	}
    
    func load() {
		//This is making the obtuse assumption that widget names will always be "widget<id>"
		func idFromName(_ name: String) -> Int? {
			return Int(name.replacingOccurrences(of: "widget", with: ""))
		}
		
		db.collection("systems").addSnapshotListener { (snapshot, error) in
			self.widgets = snapshot?.documents.filter { $0.data()["type"] as? String != "server" }.map {
				Widget(
					id: $0.documentID,
					name: $0.data()["name"] as? String ?? "",
					photoId: $0.data()["photo_id"] as? Int ?? 0,
					children: $0.data()["dependencies"] as? [String] ?? []
				)
			} ?? []
		}
    }
}
