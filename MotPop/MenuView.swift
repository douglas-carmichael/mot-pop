import SwiftUI

struct MenuView: View {
    @EnvironmentObject var session: GameSession

    var body: some View {
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

            // Pinned "How to play" — always visible, never below the fold.
            HowToPlayPill {
                session.showHowToPlay = true
            }
            .padding(.top, 4)
            .padding(.trailing, 4)
        }
    }
}

private struct HowToPlayPill: View {
    var action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("menu.howToPlay")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(hover ? Color.black : Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(
                    hover
                        ? Color.wgPrimary
                        : Color.white.opacity(0.08)
                )
            )
            .overlay(
                Capsule().stroke(
                    hover ? Color.wgPrimary : Color.wgPrimary.opacity(0.45),
                    lineWidth: 1.2
                )
            )
            .shadow(color: Color.wgPrimary.opacity(hover ? 0.45 : 0.18),
                    radius: hover ? 14 : 8, y: 4)
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("menu.howToPlay")
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: hover)
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

    @State private var hover = false

    var body: some View {
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
                    .textFieldStyle(.plain)
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
