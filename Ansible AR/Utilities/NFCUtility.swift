//
//  NFCUtility.swift
//  IOTVisualizer
//
//  Created by Gavin Jensen on 7/19/20.
//  Copyright © 2020 Gavin Jensen. All rights reserved.
//

import CoreNFC

typealias NFCReadingCompletion = (Result<NFCNDEFMessage?, Error>) -> Void
typealias WidgetReadingCompletion = (Result<Model.WidgetIdentifier, Error>) -> Void

enum NFCError: LocalizedError {
    case unavailable
    case invalidated(message: String)
    case invalidPayloadSize
    
    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "NFC Reader Not Available"
        case let .invalidated(message):
            return message
        case .invalidPayloadSize:
            return "NDEF payload size exceeds the tag limit"
        }
    }
}

class NFCUtility: NSObject {
    
    private static let shared = NFCUtility()
    
    private var action: NFCAction = .readWidget
    private var session: NFCNDEFReaderSession?
    private var completion: WidgetReadingCompletion?
    
    enum NFCAction {
        case readWidget
        case setupWidget(widgetID: Int, widgetName: String)
        case addChild(childName: String)
        
        var alertMessage: String {
            switch self {
            case .readWidget:
                return "Place tag near iPhone to read Widget."
            case .setupWidget( _, let widgetName):
                return "Place tag near iPhone to setup \(widgetName)"
            case .addChild(let childName):
                return "Place tag near iPhone to add \(childName)"
            }
        }
    }
    
    static func performAction(_ action: NFCAction, completion: WidgetReadingCompletion? = nil) {
        
        //Make sure device supports NFC, otherwise present error
        guard NFCNDEFReaderSession.readingAvailable else {
            completion?(.failure(NFCError.unavailable))
            print("NFC is not available on this device")
            return
        }
        
        shared.action = action
        shared.completion = completion
        
        shared.session = NFCNDEFReaderSession(delegate: shared.self, queue: nil, invalidateAfterFirstRead: false)
        
        shared.session?.alertMessage = action.alertMessage
        //Start the reading session. When called, a modal will present to the user with any instructions you set in the previous step.
        shared.session?.begin()
    }
}

// MARK: - NFC NDEF Reader Session Delegate
extension NFCUtility: NFCNDEFReaderSessionDelegate {
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Not used
    }
    
    private func handleError(_ error: Error) {
        session?.alertMessage = error.localizedDescription
        session?.invalidate()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        
        if let error = error as? NFCReaderError,
            error.code != .readerSessionInvalidationErrorFirstNDEFTagRead &&
                error.code != .readerSessionInvalidationErrorUserCanceled {
            completion?(.failure(NFCError.invalidated(message:
                error.localizedDescription)))
        }
        
        self.session = nil
        completion = nil
    }
    
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        
        
        guard let tag = tags.first, tags.count == 1 else {
            
            //Handling multiple tag detections at once
            session.alertMessage = """
            There are too many tags present. Remove all and then try again.
            """
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500)) {
                session.restartPolling()
            }
            return
        }
        
        session.connect(to: tag) { error in
            if let error = error {
                self.handleError(error)
                return
            }
            
            tag.queryNDEFStatus { status, _, error in
                if let error = error {
                    self.handleError(error)
                    return
                }
                
                switch (status, self.action) {
                    
                case (.notSupported, _):
                    session.alertMessage = "Unsupported tag."
                    session.invalidate()
                    
                case (.readOnly, _):
                    session.alertMessage = "Unable to write to tag."
                    session.invalidate()
                    
                case (.readWrite, .setupWidget(let widgetID, let widgetName)):
                    self.createWidget(Model.WidgetIdentifier(id: widgetID, name: widgetName, widgetType: 1), tag: tag)
                    
                case (.readWrite, .readWidget):
                    self.read(tag: tag)
                    
                default:
                    return
                }
            }
        }
    }
}

// MARK: - Utilities
extension NFCUtility {

    private func createWidget(_ widget: Model.WidgetIdentifier, tag: NFCNDEFTag) {
        read(tag: tag) { _ in
            self.updateWidget(widget, tag: tag)
        }
    }
    
    private func updateWidget(_ widget: Model.WidgetIdentifier, withChild child: Int? = nil, tag: NFCNDEFTag) {
        
        // Create a default alert message and temporary location.
        let alertMessage = "Successfully setup widget."
        let tempWidget = widget
        
        // Encode the Widget struct passed in to the function.
        
        let jsonEncoder = JSONEncoder()
        guard let customData = try? jsonEncoder.encode(tempWidget) else {
            self.handleError(NFCError.invalidated(message: "Bad data"))
            return
        }
        
        // Create a payload that can handle your data. However, you now use unknown as the format. When doing this, you must set the type and identifier to empty Data, while the payload argument hosts the actual decoded model.
        let payload = NFCNDEFPayload(format: .unknown,
                                     type: Data(),
                                     identifier: Data(),
                                     payload: customData)
        // Add the payload to a newly-created message.
        let message = NFCNDEFMessage(records: [payload])
        
        tag.queryNDEFStatus { _, capacity, _ in
            // Makes sure the device has enough storage to to store the location.
            guard message.length <= capacity else {
                self.handleError(NFCError.invalidPayloadSize)
                return
            }
            
            // Write the message to the tag.
            tag.writeNDEF(message) { error in
                if let error = error {
                    self.handleError(error)
                    return
                }
                
                if self.completion != nil {
                    self.read(tag: tag, alertMessage: alertMessage)
                }
            }
        }
    }
    
    func readWidget(from tag: NFCNDEFTag) {
        // 1
        tag.readNDEF { message, error in
            if let error = error {
                self.handleError(error)
                return
            }
            // 2
            guard let message = message, let location = Model.WidgetIdentifier(message: message) else {
                self.session?.alertMessage = "Could not read tag data."
                self.session?.invalidate()
                return
            }
            self.completion?(.success(location))
            self.session?.alertMessage = "Read tag."
            self.session?.invalidate()
        }
    }
    
    private func read(tag: NFCNDEFTag, alertMessage: String = "Tag Read", readCompletion: NFCReadingCompletion? = nil) {
        tag.readNDEF { message, error in
            if let error = error {
                self.handleError(error)
                return
            }
            
            // 1
            if let readCompletion = readCompletion,
                let message = message {
                readCompletion(.success(message))
            } else if
                let message = message, let record = message.records.first, let widget = try? JSONDecoder().decode(Model.WidgetIdentifier.self, from: record.payload) {
                
                // 2
                self.completion?(.success(widget))
                self.session?.alertMessage = alertMessage
                self.session?.invalidate()
            } else {
                self.session?.alertMessage = "Could not decode tag data."
                self.session?.invalidate()
            }
        }
    }
}
