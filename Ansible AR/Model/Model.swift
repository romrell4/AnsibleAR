//
//  BerryModel.swift
//  BerryPlus
//
//  Created by Gavin Jensen on 7/30/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//
import SceneKit

struct Widget: Identifiable, Hashable {
	let id: String
	let name: String
	let photoId: Int
	var children: [String]
	var detected: Bool = false
	var scnNode: SCNNode
	
	init(id: String, name: String, photoId: Int, children: [String]) {
		self.id = id
		self.name = name
		self.photoId = photoId
		self.children = children
		self.scnNode = SCNNode()
	}
	
	static func == (lhs: Widget, rhs: Widget) -> Bool {
		return lhs.id == rhs.id && lhs.name == rhs.name
	}
}
