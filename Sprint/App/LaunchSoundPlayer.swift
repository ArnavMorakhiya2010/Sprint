import AVFoundation

/// A short "riser into a resolving chord" — the same precomputed-buffer +
/// `AVAudioPlayerNode` pattern as `AlarmPlayer`, just with different waveform math: a
/// rising sine sweep building tension, landing on a four-note chord with a sharp attack
/// and decay. Meant to give the splash reveal a satisfying "impact" moment, Netflix-style,
/// without needing a bundled audio file.
enum LaunchSoundPlayer {
    @MainActor private static var engine: AVAudioEngine?
    @MainActor private static var player: AVAudioPlayerNode?

    @MainActor
    static func playLaunchSound() {
        let sampleRate: Double = 44100
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }

        let riserDuration = 0.55
        let impactDuration = 0.9
        let riserFrames = Int(riserDuration * sampleRate)
        let impactFrames = Int(impactDuration * sampleRate)
        let totalFrames = riserFrames + impactFrames

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames)),
              let channel = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = AVAudioFrameCount(totalFrames)

        // Riser: a sweep from 180Hz up to 680Hz, fading and growing in as it climbs.
        var phase = 0.0
        for i in 0..<riserFrames {
            let t = Double(i) / Double(riserFrames)
            let frequency = 180 + t * 500
            phase += 2 * .pi * frequency / sampleRate
            let envelope = min(1.0, Double(i) / 400) * (0.3 + 0.5 * t)
            channel[i] = Float(sin(phase) * 0.35 * envelope)
        }

        // Impact: a four-note chord (C4 E4 G4 C5) with a sharp decay.
        let chordFrequencies = [261.63, 329.63, 392.00, 523.25]
        var chordPhases = [Double](repeating: 0, count: chordFrequencies.count)
        for i in 0..<impactFrames {
            let t = Double(i) / sampleRate
            let decay = exp(-t * 2.2)
            var sample = 0.0
            for (index, frequency) in chordFrequencies.enumerated() {
                chordPhases[index] += 2 * .pi * frequency / sampleRate
                sample += sin(chordPhases[index])
            }
            sample = sample / Double(chordFrequencies.count) * 0.5 * decay
            channel[riserFrames + i] = Float(sample)
        }

        let newEngine = AVAudioEngine()
        let newPlayer = AVAudioPlayerNode()
        newEngine.attach(newPlayer)
        newEngine.connect(newPlayer, to: newEngine.mainMixerNode, format: format)

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        guard (try? newEngine.start()) != nil else { return }

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
