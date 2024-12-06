//
//  SwiftUIView.swift
//  SoundCollective
//
//  Created by Jackson Myers on 11/16/24.
//

import SwiftUI
import AVFoundation

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var recordingTime: Double = 0.0
    @Published var recordedFileURL: URL? = nil
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var startTime: Date?
    
    func startRecording() {
        // Request permission
        AVAudioApplication.requestRecordPermission() { [weak self] granted in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if granted {
                    self.setupAndStartRecording()
                } else {
                    print("Microphone access not granted")
                }
            }
        }
    }
    
    private func setupAndStartRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up AVAudioSession: \(error)")
            return
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("tempRecording.flac")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: 192000
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            isRecording = true
            recordedFileURL = nil
            startTime = Date()
            startTimer()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        stopTimer()
        
        if let url = audioRecorder?.url {
            recordedFileURL = url
        }
        
        // Deactivate session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false)
        } catch {
            print("Unable to deactivate session: \(error)")
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.recordingTime = Date().timeIntervalSince(start)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    
    func playAudio(from url: URL) {
        stopAudio()
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}

struct RecordAudio: View {
    @StateObject private var recorder = AudioRecorder()
    @StateObject private var player = AudioPlayer()
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                if recorder.isRecording {
                    // Stop recording
                    recorder.stopRecording()
                } else {
                    // Start recording
                    recorder.startRecording()
                }
            }) {
                Text(recorder.isRecording ? "Stop Recording" : "Start Recording")
                    .foregroundColor(.white)
                    .padding()
                    .background(recorder.isRecording ? Color.red : Color.green)
                    .cornerRadius(8)
            }
            
            Text(String(format: "%.1f seconds", recorder.recordingTime))
                .font(.headline)
                .foregroundColor(.primary)
            
            if let fileURL = recorder.recordedFileURL, !recorder.isRecording {
                Button(action: {
                    if player.isPlaying {
                        player.stopAudio()
                    } else {
                        player.playAudio(from: fileURL)
                    }
                }) {
                    Text(player.isPlaying ? "Stop Playback" : "Play Recording")
                        .foregroundColor(.white)
                        .padding()
                        .background(player.isPlaying ? Color.orange : Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}

#Preview {
    RecordAudio()
}
