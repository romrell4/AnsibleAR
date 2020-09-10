//
//  ARView.swift
//  Ansible AR
//
//  Created by Gavin Jensen on 8/10/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

import SwiftUI

enum ActiveSheet {
    case listSheet, infoSheet
}

struct ARView: View {
    
    @EnvironmentObject var viewModel: ViewModel
    
    @State var activeSheet: ActiveSheet = .infoSheet
    @State private var isPresented = false
    @State private var closeUpMode = true
    
    
    var body: some View {
        ZStack {
            ARViewRepresentable(viewModel: viewModel, closeUpMode: $closeUpMode)
            ui
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: self.$isPresented) {
            self.sheet
        }
    }
    
    var sheet: some View {

        switch self.activeSheet {
        case .listSheet:
            return AnyView(WidgetList().environmentObject(viewModel))
        case .infoSheet:
            return AnyView(InfoView())
        }
    }
    
    var ui: some View {
        GeometryReader { geo in
            VStack {
                HStack {
                    Button(action: {
                        self.activeSheet = .infoSheet
                        self.isPresented = true
                        
                    }) {
                        ZStack {
                            Circle()
                                .frame(width: 56, height: 56)
                                .foregroundColor(.white)
                                .opacity(0.5)
                            Image(systemName: "info")
                                .foregroundColor(.black)
                        }
                    }
                    
                    Spacer()
					
					Button(action: {
                        self.activeSheet = .listSheet
                        self.isPresented = true
                    }) {
                        ZStack {
                            Circle()
                                .frame(width: 56, height: 56)
                                .foregroundColor(.white)
                                .opacity(0.5)
                            Image(systemName: "list.bullet")
                                .foregroundColor(.black)
                        }
                    }
				}
                
                Spacer()
                
                HStack {
                    
                    RoundedRectangle(cornerRadius: 100)
                        .frame(width: 172, height: 56)
                        .foregroundColor(.white)
                        .overlay(
                            HStack {
                                
                                Toggle(isOn: self.$closeUpMode) {
                                    Text("Close Up")
                                }
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal)
                    )
                    

                    
                    Spacer()
                }
            }
            .padding(.vertical, 48)
            .padding(.horizontal, geo.size.height > geo.size.width ? 16 : 48)
        }
    }
}

//This is a representable. It enables an integration between SwiftUI and UIKit
struct ARViewRepresentable: UIViewControllerRepresentable {
    
    var viewModel: ViewModel
    @Binding var closeUpMode: Bool
    
    func makeUIViewController(context: Context) -> ARViewController {
        let view = ARViewController()
        view.viewModel = viewModel
        return view
    }
    
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {
        uiViewController.changeSize(to: closeUpMode)
    }
}


