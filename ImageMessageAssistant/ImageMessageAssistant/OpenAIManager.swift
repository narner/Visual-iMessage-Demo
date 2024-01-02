//
//  OpenAIManager.swift
//  ImageMessageAssistant
//
//  Created by Nicholas Arner on 12/23/23.
//

import Alamofire

class OpenAIManager {
    func postToOpenAI(apiKey: String, base64Image: String, completion: @escaping (String?) -> Void) {
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        
        let parameters: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "What’s in this image? In your answer, be succinct but accurate. Start it off with 'Joseph sent an image of...', and then the description of the image."
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 300
        ]
        
        AF.request("https://api.openai.com/v1/chat/completions", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseDecodable(of: OpenAIResponse.self) { response in
            switch response.result {
            case .success(let value):
                if let content = value.choices.first?.message.content {
                    completion(content)
                } else {
                    print("No content available in the response.")
                    completion(nil)
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
}
