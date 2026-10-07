import AppKit
import AVFoundation

/// The rubber-duck squeaks. `AVAudioPlayer` in a tiny round-robin pool keeps the
/// latency low and lets rapid pokes overlap, the same reason the Android app used
/// `SoundPool` instead of `MediaPlayer`.
@MainActor
final class DuckSound {
    static let shared = DuckSound()

    private var players: [AVAudioPlayer] = []
    private var nextPlayer = 0
    private var prepared = false
    private var lastPlayTime: CFTimeInterval = 0

    private init() {}

    func prepare() {
        guard !prepared else { return }
        prepared = true
        for name in ["duck1", "duck2", "duck3"] {
            for _ in 0..<2 {
                guard let url = Bundle.module.url(forResource: name, withExtension: "wav"),
                      let player = try? AVAudioPlayer(contentsOf: url) else { continue }
                player.prepareToPlay()
                players.append(player)
            }
        }
    }

    var isAvailable: Bool { !players.isEmpty }

    /// One squeak, at most one every 60 ms so a click storm doesn't turn into noise.
    func squeak() {
        prepare()
        guard !players.isEmpty else { return }
        let now = CACurrentMediaTime()
        guard now - lastPlayTime > 0.06 else { return }
        lastPlayTime = now
        let player = players[nextPlayer % players.count]
        nextPlayer += 1
        player.currentTime = 0
        player.play()
    }
}
