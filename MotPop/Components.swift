import SwiftUI

struct Card<Content: View>: View {
    var padding: CGFloat = 24
    var corner: CGFloat = 22
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color.wgSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.45), radius: 18, x: 0, y: 10)
    }
}

struct PrimaryButton: View {
    var title: String
    var systemImage: String? = nil
    var color: Color = .wgPrimary
    var action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(.semibold)
            }
            .frame(minWidth: 160)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color.opacity(hovering ? 0.95 : 0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
            .foregroundStyle(.black)
            .shadow(color: color.opacity(hovering ? 0.55 : 0.3), radius: hovering ? 16 : 8, x: 0, y: 6)
            .scaleEffect(hovering ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.18), value: hovering)
    }
}

struct GhostButton: View {
    var title: String
    var systemImage: String? = nil
    var action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(hovering ? 0.10 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.18), value: hovering)
    }
}

struct Avatar: View {
    let name: String
    var size: CGFloat = 36
    var seed: Int? = nil

    var body: some View {
        let s = seed ?? abs(name.hashValue)
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.avatarColor(seed: s),
                            Color.avatarColor(seed: s &+ 7).opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(name.initialsForAvatar.isEmpty ? "?" : name.initialsForAvatar)
                .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.78))
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
    }
}

struct PlayerChip: View {
    let player: Player

    var body: some View {
        HStack(spacing: 10) {
            Avatar(name: player.name, size: 28, seed: player.avatarSeed)
            Text(player.name)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(.white)
            if player.isHost {
                Image(systemName: "crown.fill")
                    .foregroundStyle(Color.wgWaiting)
                    .font(.caption)
            }
            if player.isBot {
                Image(systemName: "cpu.fill")
                    .foregroundStyle(Color.wgMuted)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(Color.white.opacity(0.06))
        )
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}

struct CountdownRing: View {
    var progress: Double
    var label: String
    var size: CGFloat = 120
    var tint: Color = .wgPrimary

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 10)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(
                    AngularGradient(
                        colors: [tint, .wgAccent, tint],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: progress)
            Text(label)
                .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .frame(width: size, height: size)
    }
}

struct StatusPill: View {
    var text: String
    var color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.6), radius: 6)
            Text(text)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.06)))
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}

struct SentenceText: View {
    var text: String
    var blank: String

    var body: some View {
        let parts = text.components(separatedBy: "§")
        let leading = parts.first ?? ""
        let trailing = parts.dropFirst().joined(separator: "§")
        return (
            Text(leading)
                .foregroundStyle(.white) +
            Text(blank)
                .foregroundStyle(Color.wgPrimary)
                .fontWeight(.heavy) +
            Text(trailing)
                .foregroundStyle(.white)
        )
        .font(.system(size: 30, weight: .medium, design: .rounded))
        .multilineTextAlignment(.center)
        .lineSpacing(8)
    }
}
