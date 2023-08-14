//
//  ChatViewModel.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/14/23.
//

import Foundation

class ChatViewModel {
    var contactName: String {
        return contact.name
    }
    var onNewMessage: ((String) -> Void)?
    private var contact: Contact
    private var service: ChatService
    
    
    init(contact: Contact, service: ChatService) {
        self.contact = contact
        self.service = service
        
        setupChatService()
    }
    
    func setupChatService() {
        service.messageReceivedHandler = { [unowned self] message in
            self.onNewMessage?(message)
        }
    }
    
    func send(message: String) {
        service.send(message: message)
    }
}
