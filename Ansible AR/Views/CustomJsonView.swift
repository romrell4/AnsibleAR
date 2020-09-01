//
//  CustomJsonView.swift
//  BerryPlus
//
//  Created by Gavin Jensen on 8/6/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

import SwiftUI

struct CustomJsonView: View {
    
    @EnvironmentObject var viewModel: ViewModel
    @State var urlString = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Use the text field below to enter a link to your own json data. Your json data must be an array of objects with an id (Int), name (String), widgetType(0 for image and 1 for NFC), and children (Array of child object with an id)")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding()
                
                Form {
                    TextField("URL", text: $urlString)
                }
                Button(action: load) {
                    HStack {
                        Spacer()
                        Text("Load new JSON")
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
                    .padding()
                }
            }
            .navigationBarTitle("Load external JSON", displayMode: .inline)
            
        }
    }
    
    func load() {
        viewModel.load(from: urlString)
    }
}
