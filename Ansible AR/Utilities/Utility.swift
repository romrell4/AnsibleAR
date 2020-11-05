//
//  Utility.swift
//  BerryPlus
//
//  Created by Gavin Jensen on 8/6/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

import SwiftUI
import SceneKit

public struct DarkView<Content> : View where Content : View {
    var darkContent: Content
    var on: Bool
    public init(_ on: Bool, @ViewBuilder content: () -> Content) {
        self.darkContent = content()
        self.on = on
    }
    
    public var body: some View {
        ZStack {
            if on {
                Spacer()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .background(Color.black)
                    .edgesIgnoringSafeArea(.all)
                darkContent.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity).background(Color.black).colorScheme(.dark)
            } else {
                darkContent
            }
        }
    }
}

extension View {
    public func darkModeFix(_ on: Bool = true) -> DarkView<Self> {
        DarkView(on) {
            self
        }
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
}

func normalizeVector(_ iv: SCNVector3) -> SCNVector3 {
    let length = sqrt(iv.x * iv.x + iv.y * iv.y + iv.z * iv.z)
    if length == 0 {
        return SCNVector3(0.0, 0.0, 0.0)
    }
    
    return SCNVector3( iv.x / length, iv.y / length, iv.z / length)
}

extension SCNNode {
    
    func buildLineInTwoPointsWithRotation(from startPoint: SCNVector3, to endPoint: SCNVector3, radius: CGFloat, opacity: CGFloat, color: UIColor, yOffset: Float) -> SCNNode {
        
        let newStartPoint = SCNVector3(startPoint.x, startPoint.y + yOffset, startPoint.z)
        let newEndPoint = SCNVector3(endPoint.x, endPoint.y + yOffset, endPoint.z)
        
        let w = SCNVector3(x: newEndPoint.x - newStartPoint.x,
                           y: newEndPoint.y - newStartPoint.y,
                           z: newEndPoint.z - newStartPoint.z)
        let l = CGFloat(sqrt(w.x * w.x + w.y * w.y + w.z * w.z))
        
        if l == 0.0 {
            // two points together.
            let sphere = SCNSphere(radius: radius)
            sphere.firstMaterial?.diffuse.contents = color
            self.geometry = sphere
            self.position = newStartPoint
            return self
        }
        
        let cyl = SCNCylinder(radius: radius, height: l)
        cyl.firstMaterial?.diffuse.contents = color
        
        self.geometry = cyl
        
        //original vector of cylinder above 0,0,0
        let ov = SCNVector3(0, l/2.0,0)
        //target vector, in new coordination
        let nv = SCNVector3((newEndPoint.x - newStartPoint.x)/2.0, (newEndPoint.y - newStartPoint.y)/2.0,
                            (newEndPoint.z - newStartPoint.z)/2.0)
        
        // axis between two vector
        let av = SCNVector3( (ov.x + nv.x)/2.0, (ov.y+nv.y)/2.0, (ov.z+nv.z)/2.0)
        
        //normalized axis vector
        let av_normalized = normalizeVector(av)
        let q0 = Float(0.0) //cos(angel/2), angle is always 180 or M_PI
        let q1 = Float(av_normalized.x) // x' * sin(angle/2)
        let q2 = Float(av_normalized.y) // y' * sin(angle/2)
        let q3 = Float(av_normalized.z) // z' * sin(angle/2)
        
        let r_m11 = q0 * q0 + q1 * q1 - q2 * q2 - q3 * q3
        let r_m12 = 2 * q1 * q2 + 2 * q0 * q3
        let r_m13 = 2 * q1 * q3 - 2 * q0 * q2
        let r_m21 = 2 * q1 * q2 - 2 * q0 * q3
        let r_m22 = q0 * q0 - q1 * q1 + q2 * q2 - q3 * q3
        let r_m23 = 2 * q2 * q3 + 2 * q0 * q1
        let r_m31 = 2 * q1 * q3 + 2 * q0 * q2
        let r_m32 = 2 * q2 * q3 - 2 * q0 * q1
        let r_m33 = q0 * q0 - q1 * q1 - q2 * q2 + q3 * q3
        
        self.transform.m11 = r_m11
        self.transform.m12 = r_m12
        self.transform.m13 = r_m13
        self.transform.m14 = 0.0
        
        self.transform.m21 = r_m21
        self.transform.m22 = r_m22
        self.transform.m23 = r_m23
        self.transform.m24 = 0.0
        
        self.transform.m31 = r_m31
        self.transform.m32 = r_m32
        self.transform.m33 = r_m33
        self.transform.m34 = 0.0
        
        self.transform.m41 = (newStartPoint.x + newEndPoint.x) / 2.0
        self.transform.m42 = (newStartPoint.y + newEndPoint.y) / 2.0
        self.transform.m43 = (newStartPoint.z + newEndPoint.z) / 2.0
        self.transform.m44 = 1.0
        
        self.opacity = opacity
        return self
    }
}

extension Array where Element: Identifiable {
    func firstIndex(matching: Element) -> Int {
        for index in 0..<self.count {
            if self[index].id == matching.id {
                return index
            }
        }
        return -1
    }
}

//final class OrientationInfo: ObservableObject {
//    enum Orientation {
//        case portrait
//        case landscape
//    }
//
//    @Published var orientation: Orientation
//
//    private var _observer: NSObjectProtocol?
//
//    init() {
//        // fairly arbitrary starting value for 'flat' orientations
//        if UIDevice.current.orientation.isLandscape {
//            self.orientation = .landscape
//        }
//        else {
//            self.orientation = .portrait
//        }
//
//        // unowned self because we unregister before self becomes invalid
//        _observer = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [unowned self] note in
//            guard let device = note.object as? UIDevice else {
//                return
//            }
//            if device.orientation.isPortrait {
//                self.orientation = .portrait
//            }
//            else if device.orientation.isLandscape {
//                self.orientation = .landscape
//            }
//        }
//    }
//
//    deinit {
//        if let observer = _observer {
//            NotificationCenter.default.removeObserver(observer)
//        }
//    }
//}
