//
//  SetNFCs.swift
//  WidgetPlus
//
//  Created by Gavin Jensen on 8/5/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

import SwiftUI

struct NFCWriteView: View {
    
    struct TempWidget: Identifiable {
        var id: Int
        var name: String
        var children: [Child]
    }
    
    struct Child: Identifiable {
        var id: Int
    }
    
    @EnvironmentObject var viewModel: ViewModel
    
    @State private var tempModel: TempWidget = TempWidget(id: 0, name: "temp", children: [])
    @State private var widgetName = ""
    @State private var tempChildId: String = ""
    
    var body: some View {
        
        NavigationView {
            VStack(spacing: 0) {
                
                Image("NFCTag")
                    .resizable()
                    .scaledToFit()
                
                Form {
                    Text("Widget ID: \(self.viewModel.widgets.count)")
                        .foregroundColor(.gray)
                    
                    TextField("Enter Widget Name", text: $widgetName)
                    
                    Section(header: Text("Add children as child id (one at a time)"),
                            footer: VStack(alignment: .leading) {
                                Text("Children added:")
                                
                                ForEach(tempModel.children) { child in
                                    Text("\(child.id)")
                                }
                        })
                    {
                        HStack {
                            TextField("Add child", text: $tempChildId)
                                .keyboardType(.numberPad)
                            
                            Spacer()
                            Button(action: { self.addChild(id: self.tempChildId) } ) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                            }
                        }
                    }
                }
                
                Button(action: self.writeToNFC ) {
                    HStack {
                        Spacer()
                        Text("Create widget")
                            .padding()
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .background(widgetName.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(8)
                    .padding()
                    
                }
                .disabled(widgetName.isEmpty)
                
                Spacer()
            }
            .navigationBarTitle("Write to NFC Tag", displayMode: .inline)
        }
    }
    
    func writeToNFC() {
        NFCUtility.performAction(.setupWidget(widgetID: self.viewModel.widgets.count, widgetName: self.widgetName)) { _ in
            self.widgetName = "" }
        
        var widget = Model.WidgetIdentifier(id: self.viewModel.widgets.count, name: widgetName, widgetType: 1)
        
        for child in tempModel.children {
            let widgetChild = Model.Child(id: child.id)
            widget.children.append(widgetChild)
        }
        
        print("Widget:", widget)
        viewModel.addWidget(widget: widget)
        
        resetTempModel()
    }
    
    func resetTempModel() {
        tempModel = TempWidget(id: 0, name: "temp", children: [])
        widgetName = ""
        tempChildId = ""
    }
    
    func addChild(id: String) {
        
        if id == "" {
            return
        }
        
        let id = Int(id)
        
        for child in tempModel.children {
            if child.id == id {
                return
            }
        }
        
        tempModel.children.append(Child(id: id!))
        
        hideKeyboard()
        tempChildId = ""
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
