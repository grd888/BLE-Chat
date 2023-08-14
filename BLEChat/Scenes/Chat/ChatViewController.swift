//
//  ChatViewController.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/14/23.
//

import UIKit
import MessageKit
import InputBarAccessoryView

class ChatViewController: MessagesViewController {
    private var viewModel: ChatViewModel
    private var currentDeviceSender: Sender
    private var contact: Contact
    // All of the messages in this chat session
    private var messages = [Message]()
    
    init(viewModel: ChatViewModel, contact: Contact, currentDeviceName: String) {
        self.viewModel = viewModel
        self.contact = contact
        self.currentDeviceSender = Sender(senderId: "{self}", displayName: currentDeviceName)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        title = viewModel.contactName
        
        viewModel.onNewMessage = { message in
            print("Got new message: \(message)")
            let sender = Sender(senderId: self.contact.id.uuidString, displayName: self.contact.name)
            let message = Message(sender: sender, message: message)
            self.appendNewMessage(message)
        }
    }
    
    private func appendNewMessage(_ message: Message) {
        messages.append(message)
        messagesCollectionView.insertSections([messages.count - 1])
        messagesCollectionView.scrollToLastItem()
    }
}

extension ChatViewController: MessagesDataSource {
    
    var currentSender: MessageKit.SenderType {
        return currentDeviceSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        viewModel.send(message: text)
        inputBar.inputTextView.text = nil
        let message = Message(sender: currentDeviceSender, message: text)
        appendNewMessage(message)
    }
}

extension ChatViewController: MessagesDisplayDelegate, MessagesLayoutDelegate {}
