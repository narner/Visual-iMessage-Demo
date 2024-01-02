//
//  MessageManager.swift
//  ImageMessageAssistant
//
//  Created by Nicholas Arner on 12/23/23.
//

import SwiftUI
import MessageKit
import Alamofire
import AVFoundation

struct ContentView: View {
    @State private var isLoading = false
    @State private var isPlayingAudio = false
    let openAIManager = OpenAIManager()
    @ObservedObject var messageManager = MessageManager()
    @State private var waveAnimation = false
    @State private var shouldScrollToBottom = false
    
    var body: some View {
        ZStack {
            Image("iMessageHeader")
                .resizable()
                .scaledToFit()
            
            if isLoading {
                ProgressView()
                    .padding(.leading, 120)
                    .padding(.top, 40)
                    .foregroundColor(.white)
            }
            
            if isPlayingAudio {
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .frame(width: 5, height: CGFloat.random(in: 10...30))
                            .scaleEffect(y: waveAnimation ? 1.0 : 0.35, anchor: .bottom)
                            .animation(Animation.easeInOut(duration: 0.6).repeatForever().delay(0.1 * Double(index)), value: waveAnimation)
                            .foregroundColor(.white)
                    }
                }
                .padding([.top], 40)
                .padding(.leading, 140)
                .onAppear {
                    waveAnimation = true
                }
                .onDisappear {
                    waveAnimation = false
                }
            }
        }
                
        MessagesView(messages: $messageManager.messages, shouldScrollToBottom: $shouldScrollToBottom)
            .onChange(of: messageManager.messages.count) { _ in
                shouldScrollToBottom = true
            }
        
            .onAppear {
                messageManager.initializeMockMessages()
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    isLoading = true
                    if let photoMessage = messageManager.createImageMessage(image: "Corn") {
                        messageManager.messages.append(photoMessage)
                        handleAudioForImageMessage(photoMessage)
                    }
                }
            }
            .statusBar(hidden: true)
    }
    
    func handleAudioForImageMessage(_ message: MockMessage) {
        AudioPlaybackManager.shared.audioPlaybackStatusChanged = { isPlaying in
            isPlayingAudio = isPlaying
        }
        
        if case .photo(let mediaItem) = message.kind, let image = mediaItem.image, let base64Image = convertImageToBase64String(image) {
            let openAIDispatchGroup = DispatchGroup()
            var speechQuery: String?
            
            openAIDispatchGroup.enter()
            openAIManager.postToOpenAI(apiKey: openAIAPIKey, base64Image: base64Image) { response in
                speechQuery = response
                openAIDispatchGroup.leave()
            }
            
            openAIDispatchGroup.notify(queue: .main) {
                guard let speechQuery = speechQuery else {
                    return
                }
                
                RimeTTSManager.shared.requestRimeTTS(rimeKey: rimeAPIKey, text: speechQuery, speaker: "young_female_latina-4") { audioURL in
                    isLoading = false
                    AudioPlaybackManager.shared.playAudio(from: audioURL) {
                        processAudioPlaybackForImage(mediaItem)
                    }
                }
            }
        } else {
            print("Error: Message does not contain a valid image.")
        }
    }
    
    func processAudioPlaybackForImage(_ mediaItem: MediaItem) {
        if mediaItem.image == UIImage(named: "Corn") {
            sendResponseAfterAudio(message: "That corn looks great! See any trains lately?", sender: messageManager.currentUser) {
                sendTrainPhotoMessageAfterDelay()
            }
        } else if mediaItem.image == UIImage(named: "Train") {
            sendResponseAfterAudio(message: "Nice! Btw, how's Roboflow been doing?", sender: messageManager.currentUser) {
                sendResponseAfterAudio(message: "Great; gearing up for Shipmas!", sender: messageManager.otherUser) {
                    sendRoboflowScreenshotAfterDelay()
                }
            }
        }
    }
    
    func sendResponseAfterAudio(message: String, sender: Sender, completion: @escaping () -> Void) {
        let responseMessage = MockMessage(text: message, sender: sender, messageId: UUID().uuidString, date: Date())
        messageManager.messages.append(responseMessage)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: completion)
    }
    
    func sendTrainPhotoMessageAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let trainPhotoMessage = messageManager.createImageMessage(image: "Train") {
                isLoading = true
                messageManager.messages.append(trainPhotoMessage)
                handleAudioForImageMessage(trainPhotoMessage)
            }
        }
    }
    
    func sendRoboflowScreenshotAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let screenshot = messageManager.createImageMessage(image: "RoboflowScreenshot") {
                messageManager.messages.append(screenshot)
                handleAudioForImageMessage(screenshot)
                isLoading = true
            }
        }
    }
    
    func convertImageToBase64String(_ img: UIImage) -> String? {
        guard let imageData = img.jpegData(compressionQuality: 1.0) else { return nil }
        return imageData.base64EncodedString(options: .lineLength64Characters)
    }
}
