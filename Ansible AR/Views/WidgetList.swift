//
//  BerryList.swift
//  BerryPlus
//
//  Created by Gavin Jensen on 8/7/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

import SwiftUI

struct WidgetList: View {
    
    @EnvironmentObject var viewModel: ViewModel
    
    let firstColumnWidth: CGFloat = 68
    let secondColumnWidth: CGFloat = 120
    
    var body: some View {
        NavigationView {
            Form {
//
//                NavigationLink(destination: NFCWriteView()) {
//                    Text("Write new data to NFC tags")
//                }
                
                Section(header: Text("Loaded from JSON").padding(.top) ) {
                    ForEach(viewModel.widgets) { widget in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(widget.name)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .padding(.bottom, 8)
                                
                                Group {
                                    
                                    HStack {
                                        HStack {
                                            Text("ID:")
                                            Spacer()
                                        }
                                        .frame(width: self.firstColumnWidth)
                                        
                                        HStack {
                                            Text("\(widget.id)")
                                            Spacer()
                                        }
                                        .frame(width: self.secondColumnWidth)
                                    }
                                    
                                    HStack {
                                        HStack {
                                            Text("Type:")
                                            Spacer()
                                        }
                                        .frame(width: self.firstColumnWidth)
                                        
                                        HStack {
                                            Text(widget.widgetType == 0 ? "Image Detection" : "NFC Detection")
                                            Spacer()
                                        }
                                        .frame(width: self.secondColumnWidth)
                                    }
                                    
                                    HStack {
                                        HStack {
                                            Text("Children:")
                                            Spacer()
                                        }
                                        .frame(width: self.firstColumnWidth)
                                        
                                        Text("[")
                                        List(widget.children) { child in
                                            Text("\(child.id)")
                                        }
                                        Text("]")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image("\(widget.id)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 80)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationBarTitle("Widget List", displayMode: .inline)
        }
    }
}
