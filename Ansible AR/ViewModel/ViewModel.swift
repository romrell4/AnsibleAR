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
    
    private (set) var widgets: [Widget] = []
    
    var detectedWidgets: [Widget] { widgets.filter { $0.detected } }
    
    //MARK: - Mutators
    
    func changePosition(to position: SCNVector3, at index: Int) {
        self.widgets[index].scnNode.position = position
    }
    
    func detectWidget(with imageId: Int) -> Widget {
        guard let index = self.widgets.firstIndex(where: { $0.photoId == imageId }) else {
            return Widget.unknown(photoId: imageId)
        }
        self.widgets[index].detected = true
        return self.widgets[index]
    }
    
    func markAsUpdated(widget: Widget) {
        if let index = self.widgets.firstIndex(where: { $0.id == widget.id }) {
            self.widgets[index].needsUpdate = false
        }
    }
    
    func load() {
        func docToWidget(doc: QueryDocumentSnapshot) -> Widget {
            Widget(
                id: doc.documentID,
                name: doc.data()["name"] as? String ?? "",
                photoId: doc.data()["photo_id"] as? Int ?? 0,
                children: doc.data()["dependencies"] as? [String] ?? []
            )
        }
        
        db.collection("systems").addSnapshotListener { (snapshot, error) in
            snapshot?.documents.filter { $0.data()["type"] as? String != "server" }.forEach { doc in
                let docWidget = docToWidget(doc: doc)
                if let existingWidgetIndex = self.widgets.firstIndex(where: { $0.id == docWidget.id }) {
                    // See if widget updated
                    if self.widgets[existingWidgetIndex].changed(other: docWidget) {
                        self.widgets[existingWidgetIndex].name = docWidget.name
                        self.widgets[existingWidgetIndex].children = docWidget.children
                        self.widgets[existingWidgetIndex].needsUpdate = true
                    }
                } else {
                    self.widgets.append(docWidget)
                }
            }
        }
        db.collection("event_flows").addSnapshotListener { (snapshot, error) in
            snapshot?.documents.forEach {
                let data = $0.data()
                //Only process events sent within the last ten seconds
                if let timestamp = data["timestamp"] as? Double, timestamp > Date().timeIntervalSince1970 - 10,
                   let senderId = data["sender"] as? String,
                   let senderIndex = self.widgets.firstIndex(where: { $0.id == senderId }),
                   let receiverId = data["receiver"] as? String {
                    
                    self.widgets[senderIndex].sendingEventsTo.append(receiverId)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                        self.widgets[senderIndex].sendingEventsTo.removeAll { $0 == receiverId }
                    }
                }
                
                //Delete each event after processing it
                $0.reference.delete()
            }
        }
    }
}
