import Foundation
import SwiftUI

struct Player: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isHost: Bool
    var isBot: Bool
    var avatarSeed: Int

    init(id: UUID = UUID(), name: String, isHost: Bool = false, isBot: Bool = false) {
        self.id = id
        self.name = name
        self.isHost = isHost
        self.isBot = isBot
        self.avatarSeed = abs(name.hashValue)
    }
}

struct Question: Codable, Hashable, Identifiable {
    var id: UUID
    var text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}

struct PlayerAnswer: Codable, Hashable, Identifiable {
    var id: UUID
    var playerID: UUID
    var playerName: String
    var questionID: UUID
    var text: String

    init(id: UUID = UUID(), playerID: UUID, playerName: String, questionID: UUID, text: String) {
        self.id = id
        self.playerID = playerID
        self.playerName = playerName
        self.questionID = questionID
        self.text = text
    }
}

struct GameConfig: Codable, Hashable {
    var rounds: Int = 5
    var secondsPerQuestion: Int = 25
    var maxPlayers: Int = 8
}

struct RoundResult: Identifiable, Hashable {
    let id = UUID()
    let round: Int
    let total: Int
    let question: Question
    let answers: [PlayerAnswer]
}

enum SessionPhase: Hashable {
    case menu
    case singlePlayerSetup
    case hostLobby
    case browsing
    case clientLobby
    case countdown
    case playing
    case roundResults
    case finalResults
}

enum SessionMode: Hashable {
    case none
    case singlePlayer
    case host
    case client
}

struct DiscoveredHost: Identifiable, Hashable {
    let id: String
    let name: String
}

extension Color {
    static let wgBackground = Color(red: 0.078, green: 0.078, blue: 0.094)
    static let wgSurface = Color(red: 0.135, green: 0.135, blue: 0.16).opacity(0.85)
    static let wgSurfaceElevated = Color(red: 0.18, green: 0.18, blue: 0.22).opacity(0.92)
    static let wgPrimary = Color(red: 0.957, green: 0.475, blue: 1.0)
    static let wgAccent = Color(red: 0.475, green: 0.686, blue: 1.0)
    static let wgWaiting = Color(red: 1.0, green: 0.918, blue: 0.475)
    static let wgGood = Color(red: 0.475, green: 1.0, blue: 0.494)
    static let wgBad = Color(red: 1.0, green: 0.475, blue: 0.475)
    static let wgMuted = Color(red: 0.62, green: 0.62, blue: 0.7)

    static func avatarColor(seed: Int) -> Color {
        let palette: [Color] = [
            Color(red: 0.96, green: 0.47, blue: 1.00),
            Color(red: 0.47, green: 0.69, blue: 1.00),
            Color(red: 0.47, green: 1.00, blue: 0.65),
            Color(red: 1.00, green: 0.69, blue: 0.47),
            Color(red: 1.00, green: 0.47, blue: 0.59),
            Color(red: 0.74, green: 0.47, blue: 1.00),
            Color(red: 0.47, green: 1.00, blue: 0.94),
            Color(red: 1.00, green: 0.92, blue: 0.47)
        ]
        return palette[abs(seed) % palette.count]
    }
}

extension String {
    var initialsForAvatar: String {
        let parts = self.split(separator: " ").prefix(2)
        let chars = parts.compactMap { $0.first }.map { String($0).uppercased() }
        return chars.joined()
    }
}

enum ContentLoader {
    static func loadStringArray(_ resource: String) -> [String] {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let arr = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return arr
    }
}
