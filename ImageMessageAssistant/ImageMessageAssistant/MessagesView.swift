//
//  MessagesView.swift
//  ImageMessageAssistant
//
//  Created by Nicholas Arner on 12/23/23.
//

import SwiftUI
import MessageKit

struct MessagesView: UIViewControllerRepresentable {
    @Binding var messages: [MockMessage]
    @Binding var shouldScrollToBottom: Bool
    
    func makeUIViewController(context: Context) -> MessagesViewController {
        let messagesViewController = MessagesViewController()
        let layout = messagesViewController.messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.setMessageOutgoingAvatarSize(.zero)
        layout?.setMessageIncomingAvatarSize(.zero)
        
        messagesViewController.messagesCollectionView.messagesDataSource = context.coordinator
        messagesViewController.messagesCollectionView.messagesLayoutDelegate = context.coordinator
        messagesViewController.messagesCollectionView.messagesDisplayDelegate = context.coordinator
        messagesViewController.messagesCollectionView.messageCellDelegate = context.coordinator
        return messagesViewController
    }
    
    func updateUIViewController(_ uiViewController: MessagesViewController, context: Context) {
        context.coordinator.messages = messages
        let flowLayout = uiViewController.messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        flowLayout?.attributedTextMessageSizeCalculator.outgoingAvatarSize = .zero
        flowLayout?.attributedTextMessageSizeCalculator.incomingAvatarSize = .zero
        uiViewController.messagesCollectionView.reloadData()
        if shouldScrollToBottom {
            DispatchQueue.main.async {
                if !messages.isEmpty {
                    uiViewController.messagesCollectionView.scrollToItem(at: IndexPath(item: 0, section: messages.count - 1), at: .bottom, animated: false)
                }
                shouldScrollToBottom = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, MessageCellDelegate {
        var currentSender: SenderType = Sender(senderId: "123", displayName: "John Doe")
        
        var parent: MessagesView
        var messages: [MockMessage] = []
        
        init(_ parent: MessagesView) {
            self.parent = parent
        }
        
        func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
            let tail: MessageStyle.TailCorner = (message.sender.senderId == currentSender.senderId) ? .bottomRight : .bottomLeft
            return .bubbleTail(tail, .curved)
        }
        
        func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
            return message.sender.senderId == currentSender.senderId ? .systemBlue : .darkGray
        }
        
        func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
            return .white
        }
        
        func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
            return messages[indexPath.section]
        }
        
        func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
            return messages.count
        }
    }
}

struct Sender: SenderType {
    var senderId: String
    var displayName: String
}

struct MockMessage: MessageType {
    var messageId: String
    var sender: SenderType
    var sentDate: Date
    var kind: MessageKind
    
    init(text: String, sender: SenderType, messageId: String, date: Date, image: UIImage? = nil) {
        self.messageId = messageId
        self.sender = sender
        self.sentDate = date
        if let image = image {
            let mediaItem = MockMediaItem(image: image)
            self.kind = .photo(mediaItem)
        } else {
            self.kind = .text(text)
        }
    }
}

struct MockMediaItem: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(image: UIImage) {
        self.image = image
        self.placeholderImage = UIImage()
        self.size = CGSize(width: 240, height: 240)
    }
}
