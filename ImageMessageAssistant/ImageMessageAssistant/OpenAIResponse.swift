//
//  OpenAIResponse.swift
//  ImageMessageAssistant
//
//  Created by Nicholas Arner on 12/20/23.
//

import Foundation

struct OpenAIResponse: Decodable {
    let choices: [Choice]
    let created: Int
    let id: String
    let model: String
    let object: String
}

struct Choice: Decodable {
    let finishReason: String
    let index: Int
    let message: Message

    enum CodingKeys: String, CodingKey {
        case finishReason = "finish_reason"
        case index
        case message
    }
}

struct Message: Decodable {
    let content: String
    let role: String
}
