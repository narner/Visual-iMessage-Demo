//
//  MessageManager.swift
//  ImageMessageAssistant
//
//  Created by Nicholas Arner on 12/20/23.
//

import SwiftUI
import Combine
import MessageKit

class MessageManager: ObservableObject {
    @Published var messages: [MockMessage] = []
    let currentUser = Sender(senderId: "123", displayName: "Nick")
    let otherUser = Sender(senderId: "456", displayName: "Joseph")
    let rimeTTSManager = RimeTTSManager()

    func initializeMockMessages() {
        DispatchQueue.main.async {
            let message1 = MockMessage(text: "Hey mate!", sender: self.currentUser, messageId: UUID().uuidString, date: Date())
            self.messages.append(message1)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                let message2 = MockMessage(text: "How's it going?", sender: self.currentUser, messageId: UUID().uuidString, date: Date().addingTimeInterval(-86400))
                self.messages.append(message2)
                print("Second message added")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                let message3 = MockMessage(text: "Great! Check out this harvest!!", sender: self.otherUser, messageId: UUID().uuidString, date: Date().addingTimeInterval(-86400))
                self.messages.append(message3)
                self.handleAudioForTextMessage(message3)
                print("Third message added")
            }
        }
    }
    
    func handleAudioForTextMessage(_ message: MockMessage) {
        if case .text(let text) = message.kind {
            rimeTTSManager.requestRimeTTS(rimeKey: rimeAPIKey, text: text, speaker: "young_female_latina-4") { audioURL in
                AudioPlaybackManager.shared.playAudio(from: audioURL) {
                    print("Text message audio playback completed.")
                }
            }
        } else {
            print("Error: Message does not contain text.")
        }
    }
    
    func createImageMessage(image: String) -> MockMessage? {
        if let image = UIImage(named: image) {
            let photoMessage = MockMessage(text: "Here's an image!", sender: otherUser, messageId: UUID().uuidString, date: Date(), image: image)
            return photoMessage
        } else {
            print("Error: Image not found.")
            return nil
        }
    }
    
    func createResponseMessage(sender: Sender) -> MockMessage {
        let responseMessage = MockMessage(text: "Hi, there!", sender: sender, messageId: UUID().uuidString, date: Date())
        return responseMessage
    }
}
