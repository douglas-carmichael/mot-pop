import AVFoundation

@MainActor
final class SoundEngine {
    static let shared = SoundEngine()

    var isMuted: Bool = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44100
    private let format: AVAudioFormat

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try? engine.start()
    }

    private func ensureRunning() {
        if !engine.isRunning { try? engine.start() }
    }

    private func play(_ buffer: AVAudioPCMBuffer) {
        guard !isMuted else { return }
        ensureRunning()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    // MARK: - Synthesis

    private struct NoteEvent {
        var startTime: Double
        var duration: Double
        var frequency: Double
        var amplitude: Float
        var harmonics: [(partial: Double, amplitude: Float)] = []
        var decay: Double = 8.0
    }

    private func synthesize(_ events: [NoteEvent]) -> AVAudioPCMBuffer? {
        guard let end = events.map({ $0.startTime + $0.duration }).max() else { return nil }
        let frameCount = AVAudioFrameCount(sampleRate * (end + 0.01))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) { data[i] = 0 }

        for e in events {
            let start = Int(e.startTime * sampleRate)
            let count = Int(e.duration * sampleRate)
            let last = min(start + count, Int(frameCount))
            for i in start..<last {
                let t = Double(i - start) / sampleRate
                let env = Float(exp(-e.decay * t))
                var wave = sin(2.0 * .pi * e.frequency * t)
                for h in e.harmonics {
                    wave += sin(2.0 * .pi * e.frequency * h.partial * t) * Double(h.amplitude)
                }
                data[i] += Float(wave) * e.amplitude * env
            }
        }

        var peak: Float = 0
        for i in 0..<Int(frameCount) { peak = max(peak, abs(data[i])) }
        if peak > 0.9 {
            let scale: Float = 0.9 / peak
            for i in 0..<Int(frameCount) { data[i] *= scale }
        }
        return buffer
    }

    // MARK: - Sound cues

    func countdownTick(final: Bool = false) {
        let freq = final ? 880.0 : 523.25
        let amp: Float = final ? 0.35 : 0.28
        if let buf = synthesize([
            NoteEvent(startTime: 0, duration: 0.15, frequency: freq, amplitude: amp,
                      harmonics: [(2, 0.15)], decay: 14)
        ]) { play(buf) }
    }

    func roundStart() {
        if let buf = synthesize([
            NoteEvent(startTime: 0.0,  duration: 0.2,  frequency: 523.25,  amplitude: 0.20,
                      harmonics: [(2, 0.10)], decay: 10),
            NoteEvent(startTime: 0.07, duration: 0.2,  frequency: 659.25,  amplitude: 0.22,
                      harmonics: [(2, 0.10)], decay: 10),
            NoteEvent(startTime: 0.14, duration: 0.2,  frequency: 783.99,  amplitude: 0.24,
                      harmonics: [(2, 0.10)], decay: 10),
            NoteEvent(startTime: 0.21, duration: 0.35, frequency: 1046.50, amplitude: 0.26,
                      harmonics: [(2, 0.12), (3, 0.06)], decay: 6),
        ]) { play(buf) }
    }

    func answerSubmit() {
        if let buf = synthesize([
            NoteEvent(startTime: 0,    duration: 0.3, frequency: 880.0,   amplitude: 0.25,
                      harmonics: [(2, 0.08), (3, 0.04)], decay: 7),
            NoteEvent(startTime: 0.05, duration: 0.4, frequency: 1318.51, amplitude: 0.20,
                      harmonics: [(2, 0.06)], decay: 5),
        ]) { play(buf) }
    }

    func timerWarning() {
        if let buf = synthesize([
            NoteEvent(startTime: 0, duration: 0.08, frequency: 440.0, amplitude: 0.22,
                      harmonics: [(2, 0.20), (3, 0.10)], decay: 22)
        ]) { play(buf) }
    }

    func resultsReveal() {
        if let buf = synthesize([
            NoteEvent(startTime: 0.0,  duration: 0.25, frequency: 698.46, amplitude: 0.18,
                      harmonics: [(2, 0.12), (3, 0.06)], decay: 8),
            NoteEvent(startTime: 0.06, duration: 0.25, frequency: 880.0,  amplitude: 0.20,
                      harmonics: [(2, 0.12), (3, 0.06)], decay: 8),
            NoteEvent(startTime: 0.12, duration: 0.30, frequency: 1046.5, amplitude: 0.22,
                      harmonics: [(2, 0.10), (3, 0.05)], decay: 6),
        ]) { play(buf) }
    }

    func celebration() {
        if let buf = synthesize([
            NoteEvent(startTime: 0.0,  duration: 0.6, frequency: 523.25,  amplitude: 0.20,
                      harmonics: [(2, 0.10), (3, 0.05)], decay: 3),
            NoteEvent(startTime: 0.08, duration: 0.6, frequency: 659.25,  amplitude: 0.20,
                      harmonics: [(2, 0.10), (3, 0.05)], decay: 3),
            NoteEvent(startTime: 0.16, duration: 0.6, frequency: 783.99,  amplitude: 0.20,
                      harmonics: [(2, 0.10), (3, 0.05)], decay: 3),
            NoteEvent(startTime: 0.24, duration: 0.8, frequency: 1046.50, amplitude: 0.25,
                      harmonics: [(2, 0.12), (3, 0.06)], decay: 2),
            NoteEvent(startTime: 0.50, duration: 0.9, frequency: 1318.51, amplitude: 0.22,
                      harmonics: [(2, 0.08)], decay: 2),
        ]) { play(buf) }
    }
}
