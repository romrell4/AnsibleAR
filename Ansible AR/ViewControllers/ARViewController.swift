//
//  ViewController.swift
//  ImageDetection
//
//  Created by Gavin Jensen on 6/20/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import GLKit

class ARViewController: UIViewController, ARSCNViewDelegate {
    
    //MARK: - Properties
    var viewModel = ViewModel()
    
    var arView: ARSCNView {
        return self.view as! ARSCNView
    }
    override func loadView() {
        self.view = ARSCNView(frame: .zero)
    }
    
    var sphereIdentifierRadius: CGFloat = 0.004
    var lineWidthRadius: CGFloat = 0.00075
    var flowSphereRadius: CGFloat = 0.001
    var yOffset: Float = 0.00
    var speed: Float = 0.060
    var opacity: CGFloat = 0.75
    var lineOpacity: CGFloat = 0.4
    
    //MARK: - Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.load()
        self.arView.delegate = self
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = ARReferenceImage.referenceImages(inGroupNamed: "widgetIdentifiers", bundle: nil)
        configuration.maximumNumberOfTrackedImages = configuration.detectionImages.count
        configuration.planeDetection = [.horizontal, .vertical]
        self.arView.session.run(configuration)
        
        initiateStreamAnimation()
    }
    
    //MARK: - Renderers
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            if self.viewModel.widgets.count < 2 { return }
            
            self.drawLinesBetweenNodes()
            
            //TODO: Update photo ID as well?
            self.viewModel.widgets.filter { $0.needsUpdate }.forEach {
                self.addTextNode(to: $0)
                self.viewModel.markAsUpdated(widget: $0)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }
        
        let node = initializeNode(for: imageAnchor)
        return node
    }
    
    func initializeNode(for imageAnchor: ARImageAnchor) -> SCNNode {
        let scaleFactor: CGFloat = 0.22
        
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width * scaleFactor, height: imageAnchor.referenceImage.physicalSize.height * scaleFactor)
        plane.firstMaterial?.diffuse.contents = UIColor.black
        plane.cornerRadius = 100
        
        let planeNode = SCNNode()
        planeNode.geometry = plane
        planeNode.opacity = 0.9
        let ninetyDegrees = GLKMathDegreesToRadians(-90)
        planeNode.eulerAngles = SCNVector3(ninetyDegrees, 0, 0)
        
        if let imageId = Int(imageAnchor.referenceImage.name ?? "Name not found") {
            let widget = viewModel.detectWidget(with: imageId)
            addTextNode(to: widget)
            addSphere(to: widget)
            
            let node = widget.scnNode
            node.addChildNode(planeNode)
            return node
        } else {
            return SCNNode()
        }
    }
    
    //MARK: - Geometry
    
    func drawLinesBetweenNodes() {
        arView.scene.rootNode.removeAllNodex(named: "line")
        
        for widget1 in viewModel.detectedWidgets {
            for widget2 in viewModel.detectedWidgets {
                if widget1.children.contains(widget2.id) {
                    let pos1 = widget1.scnNode.position
                    let pos2 = widget2.scnNode.position
                    createLine(from: pos1, to: pos2)
                }
            }
        }
    }
    
    func animateStream() {
        for widget1 in viewModel.detectedWidgets {
            for widget2 in viewModel.detectedWidgets {
                if widget1.children.contains(widget2.id) {
                    createAnimatingNode(from: widget1, to: widget2)
                }
            }
        }
    }
    
    
    func addTextNode(to widget: Widget) {
        widget.scnNode.removeAllNodex(named: "plane")
        
        print("Making Text Node")
        let textScaleFactor: Float = 0.00075
        let textFont = "Avenir-Next-Bold"
        let textSize: CGFloat = 0.2
        let textDepth: CGFloat = 0.02
        let yOffset: Float = 0.025
        let zOffset: Float = 0.001
        let padding: CGFloat = 0.0075
        
        let text = SCNText(string: widget.name, extrusionDepth: textDepth)
        text.font = UIFont(name: textFont, size: textSize)
        text.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        text.firstMaterial?.diffuse.contents = UIColor.white
        text.firstMaterial?.isDoubleSided = true
        text.flatness = 0.1
        
        let (minBound, maxBound) = text.boundingBox
        
        let textNode = SCNNode(geometry: text)
        
        textNode.scale = SCNVector3(textScaleFactor, textScaleFactor, textScaleFactor)
        textNode.position.z += zOffset
        textNode.opacity = 1
        textNode.name = widget.name
        textNode.pivot = SCNMatrix4MakeTranslation((maxBound.x - minBound.x) / 2, (maxBound.y - minBound.y) / 2 + 2, 0)
        
        let (min, max) = textNode.boundingBox
        let bkgPlane = SCNPlane(width: CGFloat(max.x - min.x) * CGFloat(textScaleFactor) + padding, height: CGFloat(max.y - min.y) * CGFloat(textScaleFactor) + padding)
        bkgPlane.firstMaterial?.diffuse.contents = UIColor.black
        bkgPlane.cornerRadius = 1
        
        let planeNode = SCNNode(geometry: bkgPlane)
        planeNode.name = "plane"
        planeNode.opacity = 0.8
        planeNode.position.y += yOffset
        planeNode.addChildNode(textNode)
        
        let billboardConstraint = SCNBillboardConstraint()
        planeNode.constraints = [billboardConstraint]
        
        let scnNode = widget.scnNode
        scnNode.addChildNode(planeNode)
    }
    
    func createLine(from node1: SCNVector3, to node2: SCNVector3)  {
        let twoPointsNode1 = SCNNode()
        twoPointsNode1.name = "line"
        arView.scene.rootNode.addChildNode(
            twoPointsNode1.buildLineInTwoPointsWithRotation(
                from: node1,
                to: node2,
                radius: lineWidthRadius,
                opacity: lineOpacity,
                color: .green,
                yOffset: yOffset
            )
        )
    }
    
    func addSphere(to widget: Widget) {
        //If a widget is passed in, use it's scnNode. Otherwise, just add to the root
        let scnNode = widget.scnNode
        scnNode.enumerateChildNodes { (node, _) in
            if node.name == "sphere" {
                node.removeFromParentNode()
            }
        }
        
        let sphereNode = SCNNode()
        sphereNode.geometry = SCNSphere(radius: sphereIdentifierRadius)
        sphereNode.geometry?.firstMaterial?.diffuse.contents = widget.isUnknown ? UIColor.red : UIColor.green
        sphereNode.opacity = opacity
        sphereNode.name = "sphere"
        sphereNode.position.y += yOffset
        
        scnNode.addChildNode(sphereNode)
    }
    
    func initiateStreamAnimation() {
        _ = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            self.animateStream()
        }
    }
    
    func createAnimatingNode(from startWidget: Widget, to endWidget: Widget) {
        let start = startWidget.scnNode.position
        let end = endWidget.scnNode.position
        
        let newStart = SCNVector3(start.x, start.y + yOffset, start.z)
        let newEnd = SCNVector3(end.x, end.y + yOffset, end.z)
        
        let distance = GLKVector3Distance(SCNVector3ToGLKVector3(start), SCNVector3ToGLKVector3(end))
        let duration = TimeInterval(distance/speed)
        
        let node = SCNNode()
        node.geometry = SCNSphere(radius: flowSphereRadius)
        node.geometry?.firstMaterial?.diffuse.contents = startWidget.sendingEventsTo.contains(endWidget.id) ? UIColor.red : UIColor.green
        node.opacity = 1
        node.position = newStart
        node.name = "animatingSphere"
        
        let action = SCNAction.move(to: newEnd, duration: duration)
        action.timingMode = .easeInEaseOut
        action.duration = duration
        let removeSelf = SCNAction.removeFromParentNode()
        let sequence = SCNAction.sequence([action, removeSelf]) // will be executed one by one
        node.runAction(sequence, completionHandler:nil)
        
        arView.scene.rootNode.addChildNode(node)
    }
}

extension SCNNode {
    func removeAllNodex(named name: String) {
        self.enumerateChildNodes { (node, _) in
            if node.name == name {
                node.removeFromParentNode()
            }
        }
    }
}
