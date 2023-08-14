//
//  ChatService.swift
//  BLEChat
//
//  Created by Gregorio Delgado III on 8/14/23.
//

import Foundation

protocol ChatService {
    var messageReceivedHandler: ((String) -> Void)? { get set }
    func send(message: String)
}
