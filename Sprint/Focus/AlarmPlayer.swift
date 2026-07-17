import AVFoundation

/// A short, synthesized alarm — four sine-wave beeps — fired the moment a session
/// completes, alongside `HapticsManager.success()`. Generated in code rather than a
/// bundled sound file, so "time's up" always has an audible signal with zero asset
/// dependency.
enum AlarmPlayer {
    @MainActor private static var engine: AVAudioEngine?
    @MainActor private static var player: AVAudioPlayerNode?

    @MainActor
    static func playCompletionAlarm() {
        let sampleRate: Double = 44100
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }

        let beepDuration = 0.15
        let gapDuration = 0.1
        let beepCount = 4
        let frequency = 880.0

        let beepFrames = Int(beepDuration * sampleRate)
        let gapFrames = Int(gapDuration * sampleRate)
        let totalFrames = beepCount * (beepFrames + gapFrames)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames)),
              let channel = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = AVAudioFrameCount(totalFrames)

        var frame = 0
        for _ in 0..<beepCount {
            for i in 0..<beepFrames {
                let t = Double(i) / sampleRate
                // Fade each beep's edges in/out so it clicks less and reads as a tone.
                let fadeFrames = 200
                let envelope = min(1.0, Double(min(i, beepFrames - i)) / Double(fadeFrames))
                channel[frame] = Float(sin(2 * .pi * frequency * t) * 0.5 * envelope)
                frame += 1
            }
            for _ in 0..<gapFrames {
                channel[frame] = 0
                frame += 1
            }
        }

        let newEngine = AVAudioEngine()
        let newPlayer = AVAudioPlayerNode()
        newEngine.attach(newPlayer)
        newEngine.connect(newPlayer, to: newEngine.mainMixerNode, format: format)

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        guard (try? newEngine.start()) != nil else { return }

        // Held statically so the engine isn't deallocated mid-playback.
        engine = newEngine
        player = newPlayer

        newPlayer.scheduleBuffer(buffer, at: nil, options: [], completionCallbackType: .dataPlayedBack) { _ in
            Task { @MainActor in
                newEngine.stop()
                if player === newPlayer {
                    engine = nil
                    player = nil
                }
            }
        }
        newPlayer.play()
    }
}
