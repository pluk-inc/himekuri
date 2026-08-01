//
//  TearSound.swift
//  himekuri
//
//  Procedurally synthesized paper sounds — no audio assets. A rip is a dense
//  train of fibrous micro-transients that swells mid-tear; crackles are the
//  small protests the paper makes while you pull.
//

import AVFoundation
import AppKit

final class TearSound {
    static let shared = TearSound()

    private let engine = AVAudioEngine()
    private let ripPlayer = AVAudioPlayerNode()
    private let cracklePlayer = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private lazy var ripBuffer = Self.renderRip(in: format)
    private lazy var crackleBuffers: [AVAudioPCMBuffer] = (0..<4).map {
        Self.renderCrackle(in: format, seed: 0xBEEF &+ UInt64($0) &* 7919)
    }

    private init() {
        engine.attach(ripPlayer)
        engine.attach(cracklePlayer)
        engine.connect(ripPlayer, to: engine.mainMixerNode, format: format)
        engine.connect(cracklePlayer, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.9
        engine.prepare()
    }

    private func ensureRunning() -> Bool {
        if engine.isRunning { return true }
        do { try engine.start() } catch { return false }
        return true
    }

    func playRip() {
        guard ensureRunning() else { return }
        ripPlayer.stop()
        ripPlayer.scheduleBuffer(ripBuffer, at: nil)
        ripPlayer.play()
    }

    /// The faint graze of fingers landing on the sheet.
    func playRustle() {
        guard ensureRunning(), let buffer = crackleBuffers.randomElement() else { return }
        cracklePlayer.volume = 0.10
        cracklePlayer.scheduleBuffer(buffer, at: nil)
        cracklePlayer.play()
    }

    func playCrackle(intensity: Float) {
        guard ensureRunning(), let buffer = crackleBuffers.randomElement() else { return }
        cracklePlayer.volume = 0.25 + 0.6 * min(max(intensity, 0), 1)
        cracklePlayer.scheduleBuffer(buffer, at: nil)
        cracklePlayer.play()
    }

    // MARK: - Synthesis

    private static func renderRip(in format: AVAudioFormat) -> AVAudioPCMBuffer {
        let sr = Float(format.sampleRate)
        let n = Int(sr * 0.6)
        var samples = [Float](repeating: 0, count: n)
        var rng = SeededRandom(seed: 0x7EA51DE)

        var t = 0
        while t < n - 64 {
            let prog = Float(t) / Float(n)
            let swell = 0.45 + 0.75 * sinf(prog * .pi) // loudest mid-tear
            let len = Int(rng.range(50...420))
            let amp = rng.range(0.25...1.0) * swell
            var lp: Float = 0
            var i = 0
            while i < len && t + i < n {
                let white = rng.range(-1...1)
                lp += 0.42 * (white - lp)
                let env = expf(-Float(i) / (Float(len) * 0.28))
                samples[t + i] += (0.45 * white + 0.85 * lp) * env * amp
                i += 1
            }
            // Gaps shrink mid-rip: the tear accelerates, then eases out.
            t += max(10, Int(rng.range(18...220) * (1.5 - sinf(prog * .pi))))
        }
        return makeBuffer(from: papery(samples), format: format)
    }

    private static func renderCrackle(in format: AVAudioFormat, seed: UInt64) -> AVAudioPCMBuffer {
        let sr = Float(format.sampleRate)
        let n = Int(sr * 0.07)
        var samples = [Float](repeating: 0, count: n)
        var rng = SeededRandom(seed: seed)

        for _ in 0..<Int(rng.range(3...5)) {
            let start = Int(rng.range(0...Float(n - 200)))
            let len = Int(rng.range(60...240))
            let amp = rng.range(0.3...0.8)
            var lp: Float = 0
            for i in 0..<len where start + i < n {
                let white = rng.range(-1...1)
                lp += 0.45 * (white - lp)
                let env = expf(-Float(i) / (Float(len) * 0.3))
                samples[start + i] += (0.5 * white + 0.8 * lp) * env * amp
            }
        }
        return makeBuffer(from: papery(samples), format: format)
    }

    /// High-pass emphasis for a dry, fibrous timbre, then normalize + edge fades.
    private static func papery(_ input: [Float]) -> [Float] {
        var out = [Float](repeating: 0, count: input.count)
        var prevX: Float = 0
        var prevY: Float = 0
        for i in input.indices {
            let hp = 0.9 * (prevY + input[i] - prevX)
            prevX = input[i]
            prevY = hp
            out[i] = hp * 0.85 + input[i] * 0.3
        }
        let peak = max(out.map(abs).max() ?? 1, 0.0001)
        let gain = 0.85 / peak
        let fade = min(300, out.count / 4)
        for i in out.indices {
            var v = out[i] * gain
            if i < fade { v *= Float(i) / Float(fade) }
            if i >= out.count - fade { v *= Float(out.count - 1 - i) / Float(fade) }
            out[i] = v
        }
        return out
    }

    private static func makeBuffer(from samples: [Float], format: AVAudioFormat) -> AVAudioPCMBuffer {
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { src in
            buffer.floatChannelData![0].update(from: src.baseAddress!, count: samples.count)
        }
        return buffer
    }
}
