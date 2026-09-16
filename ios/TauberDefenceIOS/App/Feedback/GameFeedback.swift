import AVFoundation
import TauberDefenceCore
import UIKit

@MainActor
final class GameFeedback {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private let isEnabled: Bool
    private var isReady = false

    init(enabled: Bool = true) {
        isEnabled = enabled
        guard enabled else { return }
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func handle(_ events: [GameEvent]) {
        guard isEnabled else { return }
        for event in events {
            switch event {
            case .waveStarted:
                play(.waveStart)
                impact(.medium)

            case let .defenseFired(_, type, _):
                switch type {
                case .plasticOwl: play(.owl)
                case .sprinkler: play(.sprinkler)
                case .falconer: play(.falcon)
                case .windowCD, .flutterTape: play(.owl)
                case .broomOfficer, .paperwork: play(.coin)
                case .speaker, .decoy: play(.sprinkler)
                }

            case .pigeonFled:
                play(.panic)
                impact(.light)

            case .shooCombo:
                play(.coin)
                impact(.rigid)

            case .pigeonReachedTarget:
                notification(.warning)

            case .waveCompleted:
                play(.waveComplete)
                notification(.success)

            case .victory:
                play(.victory)
                notification(.success)

            case .defeat:
                play(.defeat)
                notification(.error)

            case .pigeonSpawned,
                 .pigeonStateChanged,
                 .defensePurchased,
                 .falconLaunched,
                 .pressureApplied,
                 .slowApplied,
                 .pigeonRemoved,
                 .moneyChanged,
                 .cleanlinessChanged,
                 .phaseChanged,
                 .pauseChanged,
                 .sessionReset:
                break
            }
        }
    }

    private func play(_ sound: ProceduralSound) {
        prepareAudioIfNeeded()
        guard isReady, let buffer = makeBuffer(for: sound) else { return }
        player.scheduleBuffer(buffer)
        if !player.isPlaying {
            player.play()
        }
    }

    private func prepareAudioIfNeeded() {
        guard !isReady else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            try engine.start()
            isReady = true
        } catch {
            isReady = false
        }
    }

    private func makeBuffer(for sound: ProceduralSound) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            return nil
        }
        let frameCount = AVAudioFrameCount(sound.duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else {
            return nil
        }
        buffer.frameLength = frameCount

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let progress = time / sound.duration
            let frequency = sound.startFrequency
                + ((sound.endFrequency - sound.startFrequency) * progress)
            let attack = min(progress / 0.08, 1)
            let release = min((1 - progress) / 0.18, 1)
            let envelope = Float(max(0, min(attack, release)))
            let fundamental = sin(2 * Double.pi * frequency * time)
            let overtone = sin(2 * Double.pi * frequency * sound.overtone * time) * 0.28
            let wobble = 1 + (0.018 * sin(2 * Double.pi * sound.wobble * time))
            samples[frame] = Float((fundamental + overtone) * wobble) * envelope * sound.amplitude
        }
        return buffer
    }

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

private enum ProceduralSound {
    case owl
    case sprinkler
    case falcon
    case panic
    case coin
    case waveStart
    case waveComplete
    case victory
    case defeat

    var duration: Double {
        switch self {
        case .sprinkler: 0.16
        case .victory: 0.52
        case .waveStart, .waveComplete: 0.3
        default: 0.2
        }
    }

    var startFrequency: Double {
        switch self {
        case .owl: 180
        case .sprinkler: 720
        case .falcon: 980
        case .panic: 510
        case .coin: 880
        case .waveStart: 330
        case .waveComplete: 520
        case .victory: 440
        case .defeat: 260
        }
    }

    var endFrequency: Double {
        switch self {
        case .owl: 125
        case .sprinkler: 420
        case .falcon: 340
        case .panic: 820
        case .coin: 1_320
        case .waveStart: 660
        case .waveComplete: 1_040
        case .victory: 1_100
        case .defeat: 120
        }
    }

    var amplitude: Float {
        switch self {
        case .sprinkler, .owl: 0.075
        default: 0.1
        }
    }

    var overtone: Double {
        switch self {
        case .sprinkler: 3.7
        case .owl: 1.5
        default: 2
        }
    }

    var wobble: Double {
        switch self {
        case .panic: 18
        case .sprinkler: 31
        default: 7
        }
    }
}
