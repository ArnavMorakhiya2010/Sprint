import AVFoundation

enum Soundscape: String, CaseIterable, Identifiable {
    case off
    case rain
    case chillBeats
    case coffeeShop

    var id: String { rawValue }

    var label: String {
        switch self {
        case .off: return "Off"
        case .rain: return "Rain"
        case .chillBeats: return "Chill Beats"
        case .coffeeShop: return "Coffee Shop"
        }
    }

    var systemImage: String {
        switch self {
        case .off: return "speaker.slash.fill"
        case .rain: return "cloud.rain.fill"
        case .chillBeats: return "music.note"
        case .coffeeShop: return "cup.and.saucer.fill"
        }
    }
}

/// The `AVAudioSourceNode` render callback below runs on a realtime audio thread, not the
/// main actor — it can't touch `SoundscapePlayer`'s (MainActor-isolated) state directly.
/// This plain, non-isolated box is the bridge: the main actor writes `value`, the audio
/// thread reads it. `@unchecked Sendable` because a single `Float` read/write race here is
/// a stale sample at worst, not a memory-safety issue.
private final class VolumeBox: @unchecked Sendable {
    var value: Float = 0.5
}

/// A built-in ambient soundscape so a session never requires leaving the app to open a
/// music player. `.rain` is synthesized on-device (filtered white noise via
/// `AVAudioEngine`) — no asset needed. `.chillBeats` and `.coffeeShop` play a bundled loop
/// if one has been added to the app target (see README); without a matching file they
/// silently no-op rather than crash, since this app ships no audio assets of its own.
@MainActor
final class SoundscapePlayer: ObservableObject {
    @Published var current: Soundscape = .off {
        didSet { apply() }
    }
    @Published var volume: Float = 0.5 {
        didSet {
            bundledPlayer?.volume = volume
            volumeBox.value = volume
        }
    }

    private var bundledPlayer: AVAudioPlayer?

    private let noiseEngine = AVAudioEngine()
    private var noiseSourceNode: AVAudioSourceNode?
    private var noiseEQNode: AVAudioUnitEQ?
    private let volumeBox = VolumeBox()
    private var isNoiseRunning = false

    private func apply() {
        stopBundled()
        stopNoise()

        switch current {
        case .off:
            break
        case .rain:
            startRainNoise()
        case .chillBeats:
            playBundled(named: "chill_beats")
        case .coffeeShop:
            playBundled(named: "coffee_shop")
        }
    }

    private func playBundled(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.numberOfLoops = -1
        player.volume = volume
        player.play()
        bundledPlayer = player
    }

    private func stopBundled() {
        bundledPlayer?.stop()
        bundledPlayer = nil
    }

    /// Rain, approximated as low-passed white noise — no bundled audio required.
    private func startRainNoise() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else { return }

        let eq = AVAudioUnitEQ(numberOfBands: 1)
        eq.bands[0].filterType = .lowPass
        eq.bands[0].frequency = 1800
        eq.bands[0].bypass = false

        let volumeBox = volumeBox
        let sourceNode = AVAudioSourceNode { [volumeBox] _, _, frameCount, audioBufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let level = volumeBox.value
            for frame in 0..<Int(frameCount) {
                let sample = Float.random(in: -1...1) * 0.2 * level
                for buffer in buffers {
                    let data = UnsafeMutableBufferPointer<Float>(buffer)
                    data[frame] = sample
                }
            }
            return noErr
        }

        noiseEngine.attach(sourceNode)
        noiseEngine.attach(eq)
        noiseEngine.connect(sourceNode, to: eq, format: format)
        noiseEngine.connect(eq, to: noiseEngine.mainMixerNode, format: format)
        noiseSourceNode = sourceNode
        noiseEQNode = eq

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        guard (try? noiseEngine.start()) != nil else { return }
        isNoiseRunning = true
    }

    private func stopNoise() {
        guard isNoiseRunning else { return }
        noiseEngine.stop()
        if let noiseSourceNode {
            noiseEngine.detach(noiseSourceNode)
        }
        if let noiseEQNode {
            noiseEngine.detach(noiseEQNode)
        }
        noiseSourceNode = nil
        noiseEQNode = nil
        isNoiseRunning = false
    }
}
