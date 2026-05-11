import SwiftUI

// MARK: - Single Player Setup

struct SinglePlayerSetupView: View {
    @EnvironmentObject var session: GameSession
    @State private var rounds: Double = 5
    @State private var bots: Double = 3
    @State private var seconds: Double = 25

    var body: some View {
        VStack(spacing: 24) {
            LobbyHeader(title: "lobby.solo.title",
                        subtitle: "lobby.solo.subtitle")
            HStack(alignment: .top, spacing: 22) {
                Card {
                    VStack(alignment: .leading, spacing: 18) {
                        SectionLabel("lobby.config.title", systemImage: "slider.horizontal.3")

                        SettingSlider(label: "lobby.config.rounds",
                                      value: $rounds, range: 1...12, step: 1,
                                      formatter: { "\(Int($0))" })

                        SettingSlider(label: "lobby.config.opponents",
                                      value: $bots, range: 1...7, step: 1,
                                      formatter: { "\(Int($0))" })

                        SettingSlider(label: "lobby.config.timePerRound",
                                      value: $seconds, range: 10...60, step: 5,
                                      formatter: { String(format: NSLocalizedString("format.seconds", value: "%.0fs", comment: ""), $0) })
                    }
                }
                .frame(maxWidth: 460)

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel("lobby.players.title", systemImage: "person.3.fill")
                        ForEach(previewPlayers) { p in
                            PlayerChip(player: p)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            #if os(tvOS)
            .focusSection()
            #endif
            HStack {
                GhostButton(title: NSLocalizedString("action.back", value: "Back", comment: ""),
                            systemImage: "chevron.left") {
                    session.leave()
                }
                Spacer()
                PrimaryButton(title: NSLocalizedString("action.start", value: "Start game", comment: ""),
                              systemImage: "play.fill") {
                    session.config = GameConfig(
                        rounds: Int(rounds),
                        secondsPerQuestion: Int(seconds),
                        maxPlayers: Int(bots) + 1
                    )
                    session.startSinglePlayer(rounds: Int(rounds), bots: Int(bots))
                    DispatchQueue.main.async { session.startGame() }
                }
            }
            #if os(tvOS)
            .focusSection()
            #endif
        }
        .onAppear {
            rounds = Double(max(1, session.config.rounds))
            bots = Double(max(1, session.players.count - 1))
            seconds = Double(max(10, session.config.secondsPerQuestion))
        }
    }

    private var previewPlayers: [Player] {
        session.players
    }
}

// MARK: - Host Lobby

struct HostLobbyView: View {
    @EnvironmentObject var session: GameSession
    @State private var rounds: Double = 5
    @State private var seconds: Double = 25
    @State private var maxPlayers: Double = 8

    var body: some View {
        VStack(spacing: 22) {
            LobbyHeader(
                title: "lobby.host.title",
                subtitle: "lobby.host.subtitle",
                statusText: NSLocalizedString("lobby.host.broadcast", value: "Broadcasting on local network", comment: ""),
                statusColor: .wgGood
            )
            HStack(alignment: .top, spacing: 22) {
                Card {
                    VStack(alignment: .leading, spacing: 18) {
                        SectionLabel("lobby.config.title", systemImage: "slider.horizontal.3")
                        SettingSlider(label: "lobby.config.rounds",
                                      value: $rounds, range: 1...15, step: 1,
                                      formatter: { "\(Int($0))" })
                        SettingSlider(label: "lobby.config.timePerRound",
                                      value: $seconds, range: 10...60, step: 5,
                                      formatter: { String(format: NSLocalizedString("format.seconds", value: "%.0fs", comment: ""), $0) })
                        SettingSlider(label: "lobby.config.maxPlayers",
                                      value: $maxPlayers, range: 2...12, step: 1,
                                      formatter: { "\(Int($0))" })
                        Divider().background(Color.white.opacity(0.06))
                        VStack(alignment: .leading, spacing: 6) {
                            Text("lobby.host.serviceName")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(Color.wgMuted)
                            Text(session.hostServiceName)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(maxWidth: 460)

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel("lobby.players.connected",
                                     systemImage: "person.3.fill",
                                     trailing: "\(session.players.count)/\(Int(maxPlayers))")
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(session.players) { p in
                                    HStack {
                                        PlayerChip(player: p)
                                        Spacer()
                                        if !p.isHost {
                                            Button(role: .destructive) {
                                                session.kick(p)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(Color.wgBad)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                if session.players.count < 2 {
                                    HStack(spacing: 10) {
                                        ProgressView()
                                            #if os(macOS)
                                            .controlSize(.small)
                                            #endif
                                            .tint(.wgPrimary)
                                        Text("lobby.host.waitingForPlayers")
                                            .foregroundStyle(Color.wgMuted)
                                    }
                                    .padding(.top, 6)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 280)
            }
            #if os(tvOS)
            .focusSection()
            #endif
            HStack {
                GhostButton(title: NSLocalizedString("action.back", value: "Back", comment: ""),
                            systemImage: "chevron.left") {
                    session.leave()
                }
                Spacer()
                PrimaryButton(title: NSLocalizedString("action.start", value: "Start game", comment: ""),
                              systemImage: "play.fill") {
                    session.updateConfig(GameConfig(
                        rounds: Int(rounds),
                        secondsPerQuestion: Int(seconds),
                        maxPlayers: Int(maxPlayers)
                    ))
                    session.startGame()
                }
                .disabled(session.players.count < 1)
                .opacity(session.players.count < 1 ? 0.5 : 1)
            }
            #if os(tvOS)
            .focusSection()
            #endif
        }
        .onAppear {
            rounds = Double(max(1, session.config.rounds))
            seconds = Double(max(10, session.config.secondsPerQuestion))
            maxPlayers = Double(max(2, session.config.maxPlayers))
        }
    }
}

// MARK: - Browse / Join

struct BrowseView: View {
    @EnvironmentObject var session: GameSession

    var body: some View {
        VStack(spacing: 22) {
            LobbyHeader(
                title: "lobby.browse.title",
                subtitle: "lobby.browse.subtitle",
                statusText: NSLocalizedString("lobby.browse.searching", value: "Looking for hosts on your network…", comment: ""),
                statusColor: .wgWaiting
            )
            Card {
                VStack(alignment: .leading, spacing: 14) {
                    SectionLabel("lobby.browse.foundHosts", systemImage: "wifi")
                    if session.discoveredHosts.isEmpty {
                        VStack(spacing: 14) {
                            ProgressView().controlSize(.large).tint(.wgPrimary)
                            Text("lobby.browse.empty")
                                .foregroundStyle(Color.wgMuted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 220)
                    } else {
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(session.discoveredHosts) { host in
                                    HostRow(host: host) {
                                        session.joinHost(host)
                                    }
                                }
                            }
                        }
                        .frame(minHeight: 220)
                    }
                }
            }
            HStack {
                GhostButton(title: NSLocalizedString("action.back", value: "Back", comment: ""),
                            systemImage: "chevron.left") {
                    session.leave()
                }
                Spacer()
            }
        }
    }
}

private struct HostRow: View {
    let host: DiscoveredHost
    var action: () -> Void

    #if os(macOS)
    @State private var hover = false
    #endif

    private var highlighted: Bool {
        #if os(macOS)
        return hover
        #else
        return false
        #endif
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.wgAccent.opacity(0.2))
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundStyle(Color.wgAccent)
                }
                .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(host.name)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                    Text("lobby.browse.tapToJoin")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Color.wgMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.wgMuted)
                    .offset(x: highlighted ? 4 : 0)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(highlighted ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(highlighted ? 0.18 : 0.10), lineWidth: 1)
            )
            #if os(tvOS)
            .hoverEffect(.lift)
            #endif
        }
        .buttonStyle(.plain)
        #if os(macOS)
        .onHover { hover = $0 }
        .animation(.easeOut(duration: 0.18), value: hover)
        #endif
    }
}

// MARK: - Client Lobby

struct ClientLobbyView: View {
    @EnvironmentObject var session: GameSession

    var body: some View {
        VStack(spacing: 22) {
            LobbyHeader(
                title: "lobby.client.title",
                subtitle: "lobby.client.subtitle",
                statusText: NSLocalizedString("lobby.client.connected", value: "Connected — waiting for the host to start", comment: ""),
                statusColor: .wgGood
            )
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel("lobby.players.connected", systemImage: "person.3.fill",
                                 trailing: "\(session.players.count)")
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(session.players) { p in
                                PlayerChip(player: p)
                            }
                        }
                    }
                }
            }
            HStack {
                GhostButton(title: NSLocalizedString("action.leave", value: "Leave", comment: ""),
                            systemImage: "chevron.left") {
                    session.leave()
                }
                Spacer()
            }
        }
    }
}

// MARK: - Helpers

struct LobbyHeader: View {
    var title: LocalizedStringKey
    var subtitle: LocalizedStringKey
    var statusText: String? = nil
    var statusColor: Color = .wgGood

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(Color.wgMuted)
            }
            Spacer()
            if let statusText {
                StatusPill(text: statusText, color: statusColor)
            }
        }
    }
}

struct SectionLabel: View {
    var key: LocalizedStringKey
    var systemImage: String
    var trailing: String?

    init(_ key: LocalizedStringKey, systemImage: String, trailing: String? = nil) {
        self.key = key
        self.systemImage = systemImage
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage).foregroundStyle(Color.wgPrimary)
            Text(key)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.wgMuted)
                    .monospacedDigit()
            }
        }
    }
}

struct SettingSlider: View {
    var label: LocalizedStringKey
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    var formatter: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(.white)
                Spacer()
                Text(formatter(value))
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.wgPrimary)
                    .monospacedDigit()
            }
            #if os(tvOS)
            HStack(spacing: 24) {
                Button {
                    value = max(range.lowerBound, value - step)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                }
                .disabled(value <= range.lowerBound)

                ProgressView(value: (value - range.lowerBound) / (range.upperBound - range.lowerBound))
                    .tint(.wgPrimary)

                Button {
                    value = min(range.upperBound, value + step)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(value >= range.upperBound)
            }
            #else
            Slider(value: $value, in: range, step: step)
                .tint(.wgPrimary)
            #endif
        }
    }
}

// MARK: - Countdown

struct CountdownView: View {
    @EnvironmentObject var session: GameSession

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Text("countdown.starting")
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(Color.wgMuted)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [Color.wgPrimary.opacity(0.45), .clear],
                                       center: .center, startRadius: 10, endRadius: 200)
                    )
                    .frame(width: 360, height: 360)
                    .blur(radius: 8)
                Text("\(max(0, session.countdownSeconds))")
                    .font(.system(size: 200, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, Color.wgPrimary],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5, dampingFraction: 0.6),
                               value: session.countdownSeconds)
            }
            Spacer()
        }
        .onAppear { SoundEngine.shared.countdownTick() }
        .onChange(of: session.countdownSeconds) { _, newValue in
            SoundEngine.shared.countdownTick(final: newValue <= 0)
        }
    }
}
