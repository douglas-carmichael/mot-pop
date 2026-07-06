import SwiftUI

#if os(tvOS)
struct NoChromeTVButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
#endif

struct MenuView: View {
    @EnvironmentObject var session: GameSession

    var body: some View {
        #if os(tvOS)
        tvBody
        #else
        macBody
        #endif
    }

    #if os(tvOS)
    private var tvBody: some View {
        VStack(spacing: 36) {
            HStack {
                Spacer()
                LanguagePill()
                MutePill()
                HowToPlayPill {
                    session.showHowToPlay = true
                }
            }
            .focusSection()

            HeroHeader()

            HStack(spacing: 22) {
                MenuCard(
                    title: "menu.solo.title",
                    subtitle: "menu.solo.subtitle",
                    systemImage: "person.fill",
                    accent: .wgPrimary
                ) {
                    session.startSinglePlayer(rounds: 5, bots: 3)
                }
                MenuCard(
                    title: "menu.host.title",
                    subtitle: "menu.host.subtitle",
                    systemImage: "antenna.radiowaves.left.and.right",
                    accent: .wgAccent
                ) {
                    session.startHosting()
                }
                MenuCard(
                    title: "menu.join.title",
                    subtitle: "menu.join.subtitle",
                    systemImage: "magnifyingglass",
                    accent: .wgGood
                ) {
                    session.startBrowsing()
                }
            }
            .frame(maxWidth: 1400)
            .focusSection()

            NameField()
                .frame(maxWidth: 480)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    #endif

    private var macBody: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 36) {
                HeroHeader()
                HStack(spacing: 22) {
                    MenuCard(
                        title: "menu.solo.title",
                        subtitle: "menu.solo.subtitle",
                        systemImage: "person.fill",
                        accent: .wgPrimary
                    ) {
                        session.startSinglePlayer(rounds: 5, bots: 3)
                    }
                    MenuCard(
                        title: "menu.host.title",
                        subtitle: "menu.host.subtitle",
                        systemImage: "antenna.radiowaves.left.and.right",
                        accent: .wgAccent
                    ) {
                        session.startHosting()
                    }
                    MenuCard(
                        title: "menu.join.title",
                        subtitle: "menu.join.subtitle",
                        systemImage: "magnifyingglass",
                        accent: .wgGood
                    ) {
                        session.startBrowsing()
                    }
                }
                .frame(maxWidth: 980)

                NameField()
                    .frame(maxWidth: 480)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 8) {
                LanguagePill()
                MutePill()
                HowToPlayPill {
                    session.showHowToPlay = true
                }
            }
            .padding(.top, 4)
            .padding(.trailing, 4)
        }
    }
}

private struct LanguagePill: View {
    @EnvironmentObject var session: GameSession

    #if os(macOS)
    @State private var hover = false
    #elseif os(tvOS)
    @FocusState private var focused: Bool
    #endif
    @State private var haloPulse = false

    private var highlighted: Bool {
        #if os(macOS)
        return hover
        #elseif os(tvOS)
        return focused
        #else
        return false
        #endif
    }

    private var flag: String {
        session.languageCode == "fr" ? "🇫🇷" : "🇬🇧"
    }

    private var code: String {
        session.languageCode.uppercased()
    }

    var body: some View {
        Button {
            session.toggleLanguage()
        } label: {
            HStack(spacing: 8) {
                Text(flag)
                    .font(.system(size: 16))
                Text(code)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
            }
            .foregroundStyle(highlighted ? Color.black : Color.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(
                    highlighted
                        ? Color.wgGood
                        : Color.white.opacity(0.08)
                )
            )
            .overlay(
                Capsule().stroke(
                    Color.wgGood.opacity(highlighted ? 0 : 0.45),
                    lineWidth: 1.2
                )
            )
            .shadow(color: Color.wgGood.opacity(highlighted ? 0.7 : 0.18),
                    radius: highlighted ? (haloPulse ? 26 : 16) : 8,
                    y: highlighted ? 0 : 4)
            .shadow(color: Color.wgGood.opacity(highlighted ? (haloPulse ? 0.55 : 0.3) : 0),
                    radius: highlighted ? (haloPulse ? 48 : 32) : 0)
        }
        #if os(tvOS)
        .buttonStyle(NoChromeTVButtonStyle())
        .focused($focused)
        .focusEffectDisabled()
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: focused)
        .onChange(of: focused) { _, isFocused in
            if isFocused {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    haloPulse = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    haloPulse = false
                }
            }
        }
        #else
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("menu.language")
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: hover)
        #endif
        .animation(.easeOut(duration: 0.15), value: session.languageCode)
    }
}

private struct MutePill: View {
    @State private var muted = SoundEngine.shared.isMuted

    #if os(macOS)
    @State private var hover = false
    #elseif os(tvOS)
    @FocusState private var focused: Bool
    #endif
    @State private var haloPulse = false

    private var highlighted: Bool {
        #if os(macOS)
        return hover
        #elseif os(tvOS)
        return focused
        #else
        return false
        #endif
    }

    var body: some View {
        Button {
            muted.toggle()
            SoundEngine.shared.isMuted = muted
        } label: {
            Image(systemName: muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(highlighted ? Color.black : Color.white)
                .frame(width: 40, height: 36)
                .background(
                    Capsule().fill(
                        highlighted
                            ? Color.wgAccent
                            : Color.white.opacity(0.08)
                    )
                )
                .overlay(
                    Capsule().stroke(
                        Color.wgAccent.opacity(highlighted ? 0 : 0.45),
                        lineWidth: 1.2
                    )
                )
                .shadow(color: Color.wgAccent.opacity(highlighted ? 0.7 : 0.18),
                        radius: highlighted ? (haloPulse ? 26 : 16) : 8,
                        y: highlighted ? 0 : 4)
                .shadow(color: Color.wgAccent.opacity(highlighted ? (haloPulse ? 0.55 : 0.3) : 0),
                        radius: highlighted ? (haloPulse ? 48 : 32) : 0)
        }
        #if os(tvOS)
        .buttonStyle(NoChromeTVButtonStyle())
        .focused($focused)
        .focusEffectDisabled()
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: focused)
        .onChange(of: focused) { _, isFocused in
            if isFocused {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    haloPulse = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    haloPulse = false
                }
            }
        }
        #else
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help(muted ? "Unmute" : "Mute")
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: hover)
        #endif
        .animation(.easeOut(duration: 0.15), value: muted)
    }
}

private struct HowToPlayPill: View {
    var action: () -> Void

    #if os(macOS)
    @State private var hover = false
    #elseif os(tvOS)
    @FocusState private var focused: Bool
    #endif
    @State private var haloPulse = false

    private var highlighted: Bool {
        #if os(macOS)
        return hover
        #elseif os(tvOS)
        return focused
        #else
        return false
        #endif
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("menu.howToPlay")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(highlighted ? Color.black : Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(
                    highlighted
                        ? Color.wgPrimary
                        : Color.white.opacity(0.08)
                )
            )
            .overlay(
                Capsule().stroke(
                    Color.wgPrimary.opacity(highlighted ? 0 : 0.45),
                    lineWidth: 1.2
                )
            )
            .shadow(color: Color.wgPrimary.opacity(highlighted ? 0.7 : 0.18),
                    radius: highlighted ? (haloPulse ? 26 : 16) : 8,
                    y: highlighted ? 0 : 4)
            .shadow(color: Color.wgPrimary.opacity(highlighted ? (haloPulse ? 0.55 : 0.3) : 0),
                    radius: highlighted ? (haloPulse ? 48 : 32) : 0)
        }
        #if os(tvOS)
        .buttonStyle(NoChromeTVButtonStyle())
        .focused($focused)
        .focusEffectDisabled()
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: focused)
        .onChange(of: focused) { _, isFocused in
            if isFocused {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    haloPulse = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    haloPulse = false
                }
            }
        }
        #else
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("menu.howToPlay")
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: hover)
        #endif
    }
}

private struct HeroHeader: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.wgPrimary.opacity(0.5), .clear],
                            center: .center, startRadius: 10, endRadius: 90
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulse ? 1.08 : 0.95)
                    .blur(radius: 8)
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 56, weight: .black))
                    .foregroundStyle(
                        LinearGradient(colors: [.wgPrimary, .wgAccent],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .shadow(color: .wgPrimary.opacity(0.6), radius: 18)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    pulse.toggle()
                }
            }

            Text("app.title")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.white, Color.wgMuted.opacity(0.8)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .black.opacity(0.45), radius: 12, y: 6)
            Text("app.tagline")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(Color.wgMuted)
        }
    }
}

private struct MenuCard: View {
    var title: LocalizedStringKey
    var subtitle: LocalizedStringKey
    var systemImage: String
    var accent: Color
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
        #if os(tvOS)
        tvBody
        #else
        macBody
        #endif
    }

    #if os(tvOS)
    private var tvBody: some View {
        Button(action: action) {
            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accent.opacity(0.22))
                        .frame(width: 70, height: 70)
                    Image(systemName: systemImage)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(accent)
                }
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    Text(subtitle)
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(Color.wgMuted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, minHeight: 280)
        }
        .buttonStyle(.card)
    }
    #endif

    #if os(macOS)
    private var macBody: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accent.opacity(hover ? 0.32 : 0.22))
                        .frame(width: 60, height: 60)
                    Image(systemName: systemImage)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(accent)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Color.wgMuted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(accent)
                        .opacity(hover ? 1 : 0.55)
                        .offset(x: hover ? 4 : 0)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(hover ? 0.18 : 0.10), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [accent.opacity(hover ? 0.6 : 0.3), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: accent.opacity(hover ? 0.35 : 0.15),
                    radius: hover ? 24 : 12, x: 0, y: hover ? 14 : 8)
            .scaleEffect(hover ? 1.025 : 1.0)
            .offset(y: hover ? -4 : 0)
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: hover)
    }
    #endif
}

private struct NameField: View {
    @EnvironmentObject var session: GameSession
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("menu.name.label")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.wgMuted)
            HStack(spacing: 12) {
                Avatar(name: session.localPlayerName, size: 36)
                TextField("menu.name.placeholder", text: $session.localPlayerName)
                    #if os(macOS)
                    .textFieldStyle(.plain)
                    #endif
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .foregroundStyle(.white)
                    .focused($focused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(focused ? Color.wgPrimary : Color.white.opacity(0.12), lineWidth: 1.2)
            )
            .animation(.easeOut(duration: 0.18), value: focused)
        }
    }
}
