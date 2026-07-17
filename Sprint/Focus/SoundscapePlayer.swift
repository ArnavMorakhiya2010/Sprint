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

/// The render callbacks below run on a realtime audio thread, not the main actor — they
/// can't touch `SoundscapePlayer`'s (MainActor-isolated) state directly. These plain,
/// non-isolated boxes are the bridge: the main actor writes, the audio thread reads.
/// `@unchecked Sendable` because a stale sample on a race here is inaudible, not a
/// memory-safety issue — nothing but the audio thread ever mutates `Phase`.
private final class VolumeBox: @unchecked Sendable {
    var value: Float = 0.5
}

private final class Phase: @unchecked Sendable {
    var lfo: Float = 0
    var a: Float = 0
    var b: Float = 0
    var c: Float = 0
}

/// A built-in ambient soundscape so a session never requires leaving the app to open a
/// separate music player. All three options are procedurally synthesized on-device via
/// `AVAudioEngine` — no bundled recordings, so nothing here is ever silent because an
/// asset is missing. None of this is real recorded ambience or an actual rhythmic beat —
/// "Chill Beats" is a slowly breathing sustained chord, "Coffee Shop" is amplitude-swelled
/// band-passed noise approximating murmur, "Rain" is low-passed white noise.
@MainActor
final class SoundscapePlayer: ObservableObject {
    @Published var current: Soundscape = .off {
        didSet { apply() }
    }
    @Published var volume: Float = 0.5 {
        didSet { volumeBox.value = volume }
    }

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var eqNode: AVAudioUnitEQ?
    private let volumeBox = VolumeBox()
    private var isRunning = false

    private func apply() {
        stop()
        switch current {
        case .off: break
        case .rain: start(recipe: .noise(lowPassHz: 1800))
        case .coffeeShop: start(recipe: .murmur)
        case .chillBeats: start(recipe: .pad)
        }
    }

    private enum Recipe {
        case noise(lowPassHz: Float)
        case murmur
        case pad
    }

    private func start(recipe: Recipe) {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else { return }
        let sampleRate: Float = 44100
        let volumeBox = volumeBox
        let phase = Phase()

        let source = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let level = volumeBox.value

            for frame in 0..<Int(frameCount) {
                let sample: Float
                switch recipe {
                case .noise:
                    sample = Float.random(in: -1...1) * 0.22 * level

                case .murmur:
                    phase.lfo += 2 * .pi * 0.15 / sampleRate
                    let swell = 0.55 + 0.45 * sin(phase.lfo)
                    sample = Float.random(in: -1...1) * 0.22 * level * swell

                case .pad:
                    // A soft, slowly breathing three-note chord (A3, C#4, E4).
                    phase.a += 2 * .pi * 220.00 / sampleRate
                    phase.b += 2 * .pi * 277.18 / sampleRate
                    phase.c += 2 * .pi * 329.63 / sampleRate
                    phase.lfo += 2 * .pi * 0.08 / sampleRate
                    let breathe = 0.5 + 0.5 * sin(phase.lfo)
                    let chord = (sin(phase.a) + sin(phase.b) + sin(phase.c)) / 3
                    sample = chord * 0.16 * level * breathe
                }

                for buffer in buffers {
                    UnsafeMutableBufferPointer<Float>(buffer)[frame] = sample
                }
            }
            return noErr
        }

        engine.attach(source)

        switch recipe {
        case .noise(let lowPassHz):
            let eq = AVAudioUnitEQ(numberOfBands: 1)
            eq.bands[0].filterType = .lowPass
            eq.bands[0].frequency = lowPassHz
            eq.bands[0].bypass = false
            engine.attach(eq)
            engine.connect(source, to: eq, format: format)
            engine.connect(eq, to: engine.mainMixerNode, format: format)
            eqNode = eq

        case .murmur:
            let eq = AVAudioUnitEQ(numberOfBands: 1)
            eq.bands[0].filterType = .bandPass
            eq.bands[0].frequency = 1200
            eq.bands[0].bandwidth = 2.0
            eq.bands[0].bypass = false
            engine.attach(eq)
            engine.connect(source, to: eq, format: format)
            engine.connect(eq, to: engine.mainMixerNode, format: format)
            eqNode = eq

        case .pad:
            engine.connect(source, to: engine.mainMixerNode, format: format)
        }

        sourceNode = source

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        guard (try? engine.start()) != nil else { return }
        isRunning = true
    }

    private func stop() {
        guard isRunning else { return }
        engine.stop()
        if let sourceNode {
            engine.detach(sourceNode)
        }
        if let eqNode {
            engine.detach(eqNode)
        }
        sourceNode = nil
        eqNode = nil
        isRunning = false
    }
}
