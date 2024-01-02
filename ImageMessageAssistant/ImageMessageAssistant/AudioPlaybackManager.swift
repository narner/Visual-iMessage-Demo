//
//  AudioPlaybackManager.swift
//  ImageMessageAssistant
//
//  Created by Nicholas Arner on 12/23/23.
//

import AVFoundation

class AudioPlaybackManager: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioPlaybackManager()
    private var audioPlayer: AVAudioPlayer?
    private var playbackQueue: [AudioPlaybackTask] = []
    private var isPlaying: Bool = false
    var audioPlaybackStatusChanged: ((Bool) -> Void)?
    
    struct AudioPlaybackTask {
        let url: URL
        let completion: () -> Void
    }
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func playAudio(from url: URL, completion: @escaping () -> Void) {
        let task = AudioPlaybackTask(url: url, completion: completion)
        playbackQueue.append(task)
        if !isPlaying {
            processNextTask()
        }
    }
    
    private func processNextTask() {
        guard !isPlaying, let nextTask = playbackQueue.first else { return }
        isPlaying = true
        audioPlaybackStatusChanged?(true) // Notify that audio playback is starting
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: nextTask.url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("Playing audio from URL: \(nextTask.url)")
        } catch {
            print("Error: Could not play audio - \(error)")
            completeCurrentTask()
        }
    }
    
    private func completeCurrentTask() {
        audioPlayer?.stop()
        audioPlayer = nil
        if !playbackQueue.isEmpty {
            let completedTask = playbackQueue.removeFirst()
            completedTask.completion()
        }
        isPlaying = false
        if !playbackQueue.isEmpty {
            processNextTask() // Process the next task after the current one is completed
        } else {
            audioPlaybackStatusChanged?(false) // Notify that audio playback has finished
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Audio playback finished successfully: \(flag)")
        completeCurrentTask() // Call completeCurrentTask when audio playback finishes
    }
}
