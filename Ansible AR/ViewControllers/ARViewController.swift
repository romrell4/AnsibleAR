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
    
    let configuration = ARWorldTrackingConfiguration()
    
    var tempNode = SCNNode()
    
    var tempLocation = SCNVector3()
    var tempOrientation = SCNVector3()
    var tempPosition = SCNVector3()
    
    var sphereIdentifierRadius: CGFloat = 0.004
    var lineWidthRadius: CGFloat = 0.00075
    var flowSphereRadius: CGFloat = 0.00075
    var yOffset: Float = 0.01
    var speed: Float = 0.075
    var opacity: CGFloat = 0.75
    var lineOpacity: CGFloat = 0.4
    
    let color: UIColor = .green
    
    
    //MARK: - Live Update Functions
    
    func changeSize(to closeUpMode: Bool) {
        
        let scale: CGFloat = 5
        
        if closeUpMode {
//            sphereIdentifierRadius = 0.0025
            lineWidthRadius = 0.00075
            flowSphereRadius = 0.00075
            speed = 0.075
            opacity = 0.75
            lineOpacity = 0.4
        } else {
//            sphereIdentifierRadius *= scale
            lineWidthRadius *= scale
            flowSphereRadius *= scale
            speed *= Float(scale)
            opacity = 0.95
            lineOpacity = 0.6

        }
//        scaleNodesInFrustrum(to: closeUpMode ? 1/3 : 3)
        removeAllNodes(named: "animatingSphere")
        drawLinesBetweenNodes()
    }
    
    func scaleNodesInFrustrum(to scale: Float) {
        if let pointOfView = self.arView.pointOfView {
            for index in arView.nodesInsideFrustum(of: pointOfView).indices {
                arView.nodesInsideFrustum(of: pointOfView)[index].scale = SCNVector3(arView.nodesInsideFrustum(of: pointOfView)[index].scale.x * scale,
                                                                                     arView.nodesInsideFrustum(of: pointOfView)[index].scale.y * scale,
                                                                                     arView.nodesInsideFrustum(of: pointOfView)[index].scale.z * scale)
            }
        }
    }
    
    
    //MARK: - Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTapGesture()
        setupARView()
        setupImageDetection()
        
        configuration.planeDetection = [.horizontal, .vertical]
        self.arView.session.run(self.configuration)
        
        initiateStreamAnimation()
    }
    
    func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
        
    }
    @objc func handleTap() {
        
    }
    
    func setupARView() {
        self.arView.delegate = self
        //           self.arView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
    }
    
    func setupImageDetection() {
        guard let storedImages = ARReferenceImage.referenceImages(inGroupNamed: "widgetIdentifiers", bundle: nil) else {
            fatalError("Missing AR Resources images")
        }
        
        self.configuration.detectionImages = storedImages
        self.configuration.maximumNumberOfTrackedImages = storedImages.count
    }
    
    //MARK: - Renderers
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            
            if self.viewModel.widgets.count < 2 { return }
            
            for index in self.viewModel.widgets.indices {
                let pos1 = SCNVector3ToGLKVector3(self.viewModel.scnNodes[index].position)
                self.viewModel.changePosition(to: SCNVector3(pos1.x, pos1.y, pos1.z), at: index)
            }
            
            self.drawLinesBetweenNodes()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }
        
        let node = initializeNode(for: imageAnchor)
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        DispatchQueue.main.async {
            guard let pointOfView = self.arView.pointOfView else { return }
            
            let transform = pointOfView.transform
            self.tempOrientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
            self.tempLocation = SCNVector3(transform.m41, transform.m42, transform.m43)
            self.tempPosition = self.tempOrientation + self.tempLocation
            
            self.tempNode.position = self.tempPosition
        }
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
        
        let node = SCNNode()
        
        if let id = Int(imageAnchor.referenceImage.name ?? "Name not found") {
            detectAndAssign(int: id, node: node)
            addTextNode(to: node, name: viewModel.widgets[id].name)
            addSphere(to: id)
        }
        
        node.addChildNode(planeNode)
        
        return node
    }
    
    func detectAndAssign(int: Int, node: SCNNode) {
        viewModel.changeNode(to: node, at: int)
        viewModel.changeDetected(at: int)
    }
    
    //MARK: - Geometry
    
    func drawLinesBetweenNodes() {
        
        removeAllNodes(named: "line")
        
        for widget1 in viewModel.detectedWidgets {
            for widget2 in viewModel.detectedWidgets {
				if isAncestor(parent: widget1, child: widget2) {
                    let pos1 = viewModel.scnNodes[widget1.id].position
                    let pos2 = viewModel.scnNodes[widget2.id].position
                    createLine(from: pos1, to: pos2)
                }
            }
        }
    }
	
    func animateStream() {
        for widget1 in viewModel.detectedWidgets {
            for widget2 in viewModel.detectedWidgets {
                if isAncestor(parent: widget1, child: widget2) {
                    let start = viewModel.scnNodes[widget1.id].position
                    let end = viewModel.scnNodes[widget2.id].position
                    createAnimatingNode(from: start, to: end)
                }
            }
        }
    }

    
    func addTextNode(to node: SCNNode, name: String) {
        print("Making Text Nodes")
        let textScaleFactor: Float = 0.00075
        let textFont = "Avenir-Next-Bold"
        let textSize: CGFloat = 0.2
        let textDepth: CGFloat = 0.02
        let yOffset: Float = 0.025
        let zOffset: Float = 0.001
        let padding: CGFloat = 0.0075
        
        let text = SCNText(string: name, extrusionDepth: textDepth)
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
        textNode.name = name
        textNode.pivot = SCNMatrix4MakeTranslation((maxBound.x - minBound.x) / 2, (maxBound.y - minBound.y) / 2 + 2, 0)
        
        let (min, max) = textNode.boundingBox
        let bkgPlane = SCNPlane(width: CGFloat(max.x - min.x) * CGFloat(textScaleFactor) + padding, height: CGFloat(max.y - min.y) * CGFloat(textScaleFactor) + padding)
        bkgPlane.firstMaterial?.diffuse.contents = UIColor.black
        bkgPlane.cornerRadius = 1
        
        let planeNode = SCNNode(geometry: bkgPlane)
        planeNode.opacity = 0.8
        planeNode.position.y += yOffset
        planeNode.addChildNode(textNode)
        
        let billboardConstraint = SCNBillboardConstraint()
        planeNode.constraints = [billboardConstraint]
        
        node.addChildNode(planeNode)
    }
    
    func createLine(from node1: SCNVector3, to node2: SCNVector3)  {
        let twoPointsNode1 = SCNNode()
        twoPointsNode1.name = "line"
        arView.scene.rootNode.addChildNode(
            twoPointsNode1.buildLineInTwoPointsWithRotation(from: node1,
                                                            to: node2,
                                                            radius: lineWidthRadius,
                                                            opacity: lineOpacity,
                                                            color: color,
                                                            yOffset: yOffset))
    }
    
    func addSphere(to id: Int) {
        
        viewModel.scnNodes[id].enumerateChildNodes { (node, _) in
                   if node.name == "sphere" {
                       node.removeFromParentNode()
                   }
               }
        
        let sphereNode = SCNNode()
        sphereNode.geometry = SCNSphere(radius: sphereIdentifierRadius)
        sphereNode.geometry?.firstMaterial?.diffuse.contents = color
        sphereNode.opacity = opacity
        sphereNode.name = "sphere"
        sphereNode.position.y += yOffset
       
        viewModel.scnNodes[id].addChildNode(sphereNode)
    }
        
    func initiateStreamAnimation() {
        _ = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            self.animateStream()
        }
    }
	
    func createAnimatingNode(from start: SCNVector3, to end: SCNVector3) {
        
        let newStart = SCNVector3(start.x, start.y + yOffset, start.z)
        let newEnd = SCNVector3(end.x, end.y + yOffset, end.z)
        
        let distance = GLKVector3Distance(SCNVector3ToGLKVector3(start), SCNVector3ToGLKVector3(end))
        let duration = TimeInterval(distance/speed)
        
        let node = SCNNode()
        node.geometry = SCNSphere(radius: flowSphereRadius)
        node.geometry?.firstMaterial?.diffuse.contents = color
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
    
    //MARK: - Utility Functions
    func removeAllNodes(named name: String) {
        arView.scene.rootNode.enumerateChildNodes { (node, _) in
            
            if node.name == name {
                node.removeFromParentNode()
            }
        }
    }
    
    func isAncestor(parent: Model.WidgetIdentifier, child: Model.WidgetIdentifier) -> Bool {
		return parent.children.contains { $0.id == child.id }
    }
}


