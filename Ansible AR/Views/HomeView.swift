//
//  ContentView.swift
//  BerryPlus
//
//  Created by
//  Gavin Jensen on 7/27/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject var viewModel: ViewModel
    @State var isActive = false
    
    var body: some View {
        NavigationView {

            VStack(spacing: 0) {
                
                Spacer()
                
                Text("Ansible AR")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Use this app to superimpose a virtual directed graph on widgets in your environment using image identifiers.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()

                Spacer()
                Spacer()
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: { self.load(); self.isActive = true } ) {
                        HStack {
                            Spacer()
                            
                            Text("Get Started")
                                .padding(.vertical)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .background(Color("gray90"))
                        .cornerRadius(8)
                    }
                }
                .padding(.bottom)
                NavigationLink(destination: ARView(), isActive: $isActive) { EmptyView() }
            }
                
            .padding()
            .onAppear {
                self.load()
            }
        }
        .darkModeFix()
        .statusBar(hidden: true)
    }
    
    func load() {
        print("loading onAppear")
        viewModel.load()
    }
}
