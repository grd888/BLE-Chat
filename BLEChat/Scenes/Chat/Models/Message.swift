//
//  Message.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/14/23.
//

import Foundation
import MessageKit

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    init(sender: Sender, message: String) {
        self.sender = sender
        self.messageId = UUID().uuidString
        self.sentDate = Date()
        self.kind = .text(message)
    }
}
