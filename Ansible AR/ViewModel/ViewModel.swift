//
//  ViewModel.swift
//  WidgetPlus
//
//  Created by Gavin Jensen on 8/1/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

import SceneKit

class ViewModel: ObservableObject, Identifiable {
    
//    private var model = Model()
//
//    var widgets: [Model.WidgetIdentifier] {
//        return model.widgets
//    }
    
    @Published var widgets = [Model.WidgetIdentifier]()
    
    var defaultURLString: String = "https://api.jsonbin.io/b/5f2db9b86f8e4e3faf2d8d8c/7"
    var urlString: String = ""
    
    static var totalWidgets = 12
    
    var scnNodes: [SCNNode] = makePositions()
    
    //MARK: - Mutators
    
    func addWidget(widget: Model.WidgetIdentifier) {
        self.widgets.append(widget)
        scnNodes.append(SCNNode())
    }
    
    func changePosition(to position: SCNVector3, at index: Int) {
        scnNodes[index].position = position
    }
    
    func changeNode(to node: SCNNode, at index: Int) {
        scnNodes[index] = node
    }
    
    func changeDetected(to detected: Bool = true, at index: Int) {
        self.widgets[index].detected = detected
    }
    
    func load(from urlString: String) {
        self.urlString = urlString
        let url = URL(string: urlString)!
        
        print("Load")
        load(from: url)
    }
    
    func load() {
        if urlString.isEmpty {
            print("Is Empty")
            let url = URL(string: defaultURLString)!
            load(from: url)
            urlString = "-1"
        }
    }
    
    func load(from url: URL) {
        URLSession.shared.dataTask(with: url) {(data, response, error) in
                   do {
                       if let d = data {
                           let decodedData = try JSONDecoder().decode([Model.WidgetIdentifier].self, from: d)
                           DispatchQueue.main.async {
                               self.widgets = decodedData
                               print("Done Fetching")
                           }
                       }else {
                           print("No Data")
                       }
                   } catch {
                       print ("Error:", error)
                   }
                   
               }.resume()
    }
    
    static func makePositions() -> [SCNNode] {
                
        var nodes = [SCNNode]()
        
        for _ in 0..<totalWidgets {
            nodes.append(SCNNode())
        }
        return nodes
    }
}
