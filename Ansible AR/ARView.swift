//
//  ARView.swift
//  WidgetPlus
//
//  Created by Gavin Jensen on 8/7/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

import SwiftUI


final class ActiveSheet: ObservableObject {
    enum Kind {
        case listSheet, infoSheet, jsonSheet
        case none
    }
    @Published var kind: Kind = .none {
        didSet { showSheet = kind != .none }
    }
    @Published var showSheet: Bool = false
}

struct ARView: View {
    
    //    enum ActiveSheet {
    //       case listSheet, infoSheet, jsonSheet
    //    }
    
    var viewModel: ViewModel
    
    @ObservedObject var activeSheet: ActiveSheet = ActiveSheet()
    @State private var widgetModel: Model.WidgetIdentifier?
    //    @State private var isPresented = false
    //    @State private var isPresentedList = false
    //    @State private var isPresentedInfo = false
    //    @State private var isPresentedJson = false
    //    @State private var activeSheet: ActiveSheet = .infoSheet
    
    private var sheet: some View {
        switch activeSheet.kind {
        case .none: return AnyView(EmptyView())
        case .listSheet: return AnyView(WidgetList(viewModel: viewModel))
        case .infoSheet: return AnyView(Text("Info"))
        case .jsonSheet: return AnyView(CustomJsonView(viewModel: viewModel))
        }
    }
    
    var body: some View {
        
        ZStack {
            ARViewRepresentable(viewModel: viewModel, widgetModel: $widgetModel)
            ui
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
    
    var ui: some View {
        VStack {
            HStack {
                Button(action: {
                    self.activeSheet.showSheet = true
                    self.activeSheet.kind = .infoSheet
                    //                    self.activeSheet = .infoSheet
                    //                    self.isPresented = true
                    //                    self.isPresentedInfo = true
                }) {
                    Circle()
                        .frame(width: 56, height: 56)
                        .foregroundColor(.white)
                        .opacity(0.5)
                        .overlay(Image(systemName: "info")
                            .foregroundColor(.black))
                }
                
                Spacer()
                
                widgetModel.map { widget in
                    Text("Detected: \(widget.name)")
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(100)
                }
                .padding(.top, 48)
                
                Spacer()
                
                Button(action: {
                    //                    self.activeSheet = .jsonSheet
                    //                    self.isPresented = true
                    //                    self.isPresentedJson = true
                }) {
                    Circle()
                        .frame(width: 56, height: 56)
                        .foregroundColor(.white)
                        .opacity(0.5)
                        .overlay(Image(systemName: "square.and.arrow.down.fill")
                            .foregroundColor(.black))
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button(action: {
                    //                    self.activeSheet = .listSheet
                    //                    self.isPresented = true
                    //                    self.isPresentedList = true
                }) {
                    Circle()
                        .frame(width: 56, height: 56)
                        .foregroundColor(.white)
                        .opacity(0.5)
                        .overlay(Image(systemName: "list.bullet")
                            .foregroundColor(.black))
                }
            }
        }
        .padding(.top, 176)
        .padding(.bottom, 64)
        .padding(.horizontal)
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: self.$activeSheet.showSheet, content: { self.sheet })
    }
    
    
    
    
    func scanWidget() {
        //This changes the model which is detected by ARViewRepresentable which then gets the position from the ViewController
        NFCUtility.performAction(.readWidget) { widget in
            self.widgetModel = try? widget.get()
        }
    }
}

//This is a representable. It enables an integration between SwiftUI and UIKit
struct ARViewRepresentable: UIViewControllerRepresentable {
    
    var viewModel: ViewModel
    @Binding var widgetModel: Model.WidgetIdentifier?
    
    func makeUIViewController(context: Context) -> ARViewController {
        let view = ARViewController()
        view.viewModel = viewModel
        return view
    }
    
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {
        if let widget = widgetModel {
            uiViewController.getPositionForNFCScan(widget: widget)
        } else {
            print("Could not get widget information")
        }
    }
}


