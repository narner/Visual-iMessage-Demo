//
//  RimeTTSManager.swift
//  ImageMessageAssistant
//
//  Created by Nicholas Arner on 12/23/23.
//

import Foundation
import Alamofire

class RimeTTSManager {
    static let shared = RimeTTSManager()

    func requestRimeTTS(rimeKey: String, text: String, speaker: String, completion: @escaping (URL) -> Void) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(rimeKey)"
        ]

        let parameters: [String: Any] = [
            "text": text,
            "speaker": speaker
        ]

        AF.request("https://users.rime.ai/v1/rime-tts", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).response { [self] response in
            switch response.result {
            case .success(let value):
                if let data = value {
                    do {
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let audioContent = jsonResponse["audioContent"] as? String {
                            guard let fileURL = base64StringToAudioFile(base64String: audioContent, fileName: "test.wav") else {
                                print("Error: Could not create audio file from base64 string.")
                                return
                            }
                            completion(fileURL)
                        } else {
                            print("Error: Could not parse JSON or find 'audioContent'.")
                        }
                    } catch {
                        print("Error: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    private func base64StringToAudioFile(base64String: String, fileName: String) -> URL? {
        guard let audioData = Data(base64Encoded: base64String) else {
            print("Error: Could not decode base64 string.")
            return nil
        }

        let fileManager = FileManager.default
        let temporaryDirectoryURL = fileManager.temporaryDirectory
        let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)

        do {
            try audioData.write(to: fileURL)
            print("Audio file saved to: \(fileURL)")
            return fileURL
        } catch {
            print("Error: Could not write audio data to file - \(error)")
            return nil
        }
    }
}
