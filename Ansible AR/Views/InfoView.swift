//
//  InfoView.swift
//  Ansible AR
//
//  Created by Gavin Jensen on 8/10/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

import SwiftUI

struct InfoView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image("ExampleImage")
                    .resizable()
                    .scaledToFit()
                
                
                Group {
                    Text("Ansible AR")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                        .multilineTextAlignment(.center)
                    
                    Text("Use this app to superimpose a virtual directed graph on widgetsin your environment using images or NFC tags.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        UIApplication.shared.open(URL(string: "apple.com")!)
                    }) {
                        Text("Github")
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                
                Spacer()
            }

            .navigationBarTitle("Info", displayMode: .inline)
        }
    }
}
